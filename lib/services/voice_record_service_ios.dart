// iOS专用录音服务 - 使用 record 包
// 此文件仅在 iOS 平台使用，Android 继续使用 flutter_sound

import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

/// OSS上传信息
class OssUploadInfo {
  final String uploadUrl;
  final String fileUrl;
  final String contentType;

  OssUploadInfo({
    required this.uploadUrl,
    required this.fileUrl,
    required this.contentType,
  });

  factory OssUploadInfo.fromJson(Map<String, dynamic> json) {
    return OssUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      fileUrl: json['fileUrl'] as String,
      contentType: json['contentType'] as String? ?? 'audio/mp4',
    );
  }
}

/// iOS专用语音录制服务
/// 使用 record 包，比 flutter_sound 在 iOS 上更稳定
class VoiceRecordServiceIOS {
  static final VoiceRecordServiceIOS _instance = VoiceRecordServiceIOS._internal();
  factory VoiceRecordServiceIOS() => _instance;
  VoiceRecordServiceIOS._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio = Dio();
  
  bool _isRecording = false;
  String? _currentRecordPath;
  int _currentDuration = 0;
  Timer? _durationTimer;
  DateTime? _startTime;

  // 最大录音时长（秒）
  static const int maxDurationSeconds = 60;

  // 录音状态回调
  Function(int seconds)? onDurationUpdate;
  Function()? onMaxDurationReached;
  Function(String error)? onError;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 当前录音时长（秒）
  int get currentDuration => _currentDuration;

  /// 初始化（检查权限）
  Future<void> init() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('麦克风权限未授予');
      }
    }
    logger.debug('🎤 [iOS] 录音服务初始化成功');
  }

  /// 检查麦克风权限
  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  /// 开始录音
  Future<bool> startRecording() async {
    if (_isRecording) {
      logger.debug('⚠️ [iOS] 已经在录音中');
      return false;
    }

    try {
      // 检查权限
      if (!await _recorder.hasPermission()) {
        await init();
      }

      // 获取临时目录
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordPath = '${dir.path}/voice_$timestamp.m4a';

      logger.debug('🎤 [iOS] 开始录音: $_currentRecordPath');

      // 使用 AAC-LC 编码器（iOS 原生支持，最稳定）
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
        ),
        path: _currentRecordPath!,
      );

      _isRecording = true;
      _currentDuration = 0;
      _startTime = DateTime.now();

      // 启动时长计时器
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _currentDuration = DateTime.now().difference(_startTime!).inSeconds;
        logger.debug('⏱️ [iOS] 录音时长: ${_currentDuration}秒');
        onDurationUpdate?.call(_currentDuration);

        if (_currentDuration >= maxDurationSeconds) {
          logger.debug('⏱️ [iOS] 达到最大录音时长');
          onMaxDurationReached?.call();
        }
      });

      logger.debug('🎤 [iOS] 录音已开始');
      return true;
    } catch (e) {
      logger.error('[iOS] 开始录音失败', error: e);
      onError?.call('开始录音失败: $e');
      _cleanup();
      return false;
    }
  }

  /// 停止录音
  Future<Map<String, dynamic>?> stopRecording() async {
    if (!_isRecording) {
      logger.debug('⚠️ [iOS] 没有正在进行的录音');
      return null;
    }

    try {
      final duration = _currentDuration;
      
      // 停止计时器
      _durationTimer?.cancel();
      _durationTimer = null;
      _isRecording = false;

      // 停止录音
      final path = await _recorder.stop();
      logger.debug('🎤 [iOS] 停止录音: path=$path, duration=${duration}秒');

      if (path == null || path.isEmpty) {
        logger.debug('❌ [iOS] 录音文件路径为空');
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        logger.debug('❌ [iOS] 录音文件不存在: $path');
        return null;
      }

      final fileSize = await file.length();
      logger.debug('📁 [iOS] 录音文件大小: $fileSize bytes');

      // 验证文件头
      if (fileSize > 8) {
        final bytes = await file.openRead(0, 8).first;
        logger.debug('📁 [iOS] 文件头: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      }

      if (duration < 1) {
        logger.debug('⚠️ [iOS] 录音时长太短，不保存');
        await file.delete();
        return null;
      }

      return {
        'path': path,
        'duration': duration,
        'size': fileSize,
      };
    } catch (e) {
      logger.error('[iOS] 停止录音失败', error: e);
      _cleanup();
      return null;
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _durationTimer?.cancel();
      _durationTimer = null;
      _isRecording = false;

      await _recorder.stop();

      if (_currentRecordPath != null) {
        final file = File(_currentRecordPath!);
        if (await file.exists()) {
          await file.delete();
          logger.debug('🗑️ [iOS] 已删除取消的录音文件');
        }
      }
    } catch (e) {
      logger.error('[iOS] 取消录音失败', error: e);
    } finally {
      _cleanup();
    }
  }

  /// 上传语音文件到OSS
  static Future<Map<String, dynamic>> uploadVoice({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    final service = VoiceRecordServiceIOS();
    return service._uploadVoiceInternal(
      token: token,
      filePath: filePath,
      onProgress: onProgress,
    );
  }

  Future<OssUploadInfo> _getUploadUrl({
    required String token,
    required String fileName,
  }) async {
    final url = ApiConfig.getApiUrl(ApiConfig.ossGetOpusUploadUrl);
    logger.debug('📤 [iOS] 请求上传URL: $url, fileName: $fileName');

    final response = await _dio.post(
      url,
      data: {'fileName': fileName},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0 || data['code'] == 200) {
        return OssUploadInfo.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? '获取上传URL失败');
    }
    throw Exception('获取上传URL失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _uploadVoiceInternal({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    try {
      logger.debug('📤 [iOS] 开始上传语音文件: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('语音文件不存在: $filePath');
      }

      final fileName = filePath.split('/').last;
      final fileBytes = await file.readAsBytes();
      logger.debug('📁 [iOS] 文件大小: ${fileBytes.length} bytes');

      if (fileBytes.isEmpty) {
        throw Exception('语音文件为空');
      }

      // 获取上传URL
      final uploadInfo = await _getUploadUrl(token: token, fileName: fileName);
      logger.debug('✅ [iOS] 获取上传URL成功: ${uploadInfo.fileUrl}');

      // 使用 http 包上传
      final request = http.Request('PUT', Uri.parse(uploadInfo.uploadUrl));
      request.bodyBytes = fileBytes;
      request.headers['Content-Type'] = uploadInfo.contentType;
      request.headers['Content-Length'] = fileBytes.length.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      logger.debug('📥 [iOS] OSS响应: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('上传失败: ${response.statusCode}');
      }

      onProgress?.call(fileBytes.length, fileBytes.length);
      logger.debug('✅ [iOS] 上传成功: ${uploadInfo.fileUrl}');

      return {
        'url': uploadInfo.fileUrl,
        'file_name': fileName,
      };
    } catch (e) {
      logger.error('[iOS] 上传语音文件失败', error: e);
      rethrow;
    }
  }

  void _cleanup() {
    _isRecording = false;
    _currentRecordPath = null;
    _currentDuration = 0;
    _startTime = null;
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> dispose() async {
    _cleanup();
    _recorder.dispose();
  }
}
