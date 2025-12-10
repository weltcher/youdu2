// 移动端实现 - 使用真实的 flutter_sound
// 此文件包含实际的实现逻辑，不直接导入 flutter_sound
// 通过条件导入在 voice_record_service_mobile.dart 中导入 flutter_sound

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

// 使用条件导入：在移动端使用真实的 flutter_sound，在桌面端使用 stub
// 注意：由于 Windows 也有 dart.library.io，我们使用默认 stub + 条件导入
// 在 Web 平台（dart.library.html）使用 stub，在移动端（有 dart.library.io 但没有 html）使用真实实现
import 'voice_record_service_stub.dart' // 默认 stub（用于 Windows/Web）
    if (dart.library.io) 'voice_record_service_flutter_sound.dart'; // 移动端导入真实实现

/// OSS上传信息
class OssUploadInfo {
  final String uploadUrl; // 用于 PUT 上传
  final String fileUrl; // 上传后可直接访问的 URL
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
      contentType: json['contentType'] as String? ?? 'audio/ogg',
    );
  }
}

/// 语音录制服务（移动端实现）
///
/// 功能：
/// - 支持最长60秒录音
/// - 使用AAC编码格式（M4A容器）
/// - 上传到OSS存储
/// - 返回语音URL和时长
class VoiceRecordService {
  static final VoiceRecordService _instance = VoiceRecordService._internal();
  factory VoiceRecordService() => _instance;
  VoiceRecordService._internal();

  // 使用条件导入的类型
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final Dio _dio = Dio();
  bool _isInited = false; // 录音器是否已初始化
  bool _isIniting = false; // 防止重复初始化
  Completer<void>? _initCompleter; // 用于等待初始化完成

  // 录音状态
  bool _isRecording = false;
  String? _currentRecordPath;

  // 最大录音时长（秒）
  static const int maxDurationSeconds = 60;

  // 录音状态回调
  Function(int seconds)? onDurationUpdate;
  Function()? onMaxDurationReached;
  Function(String error)? onError;

  // 录音时长
  int _currentDuration = 0;
  StreamSubscription? _progressSubscription;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 当前录音时长（秒）
  int get currentDuration => _currentDuration;

  /// 是否已初始化
  bool get isInited => _isInited;

  /// 初始化录音器
  Future<void> init() async {
    // 如果已经初始化，直接返回
    if (_isInited) {
      logger.debug('🎤 录音器已经初始化');
      return;
    }

    // 如果正在初始化，等待完成
    if (_isIniting && _initCompleter != null) {
      logger.debug('🎤 等待录音器初始化完成...');
      await _initCompleter!.future;
      return;
    }

    _isIniting = true;
    _initCompleter = Completer<void>();

    try {
      // 申请麦克风权限
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('麦克风权限未授予');
      }

      // 打开录音器
      await _recorder.openRecorder();
      _isInited = true;
      logger.debug('🎤 录音器初始化成功');
      _initCompleter!.complete();
    } catch (e) {
      logger.error('录音器初始化失败', error: e);
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _isIniting = false;
    }
  }

  /// 检查麦克风权限
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      logger.error('检查麦克风权限失败', error: e);
      return false;
    }
  }

  /// 开始录音
  ///
  /// 返回是否成功开始录音
  Future<bool> startRecording() async {
    if (_isRecording) {
      logger.debug('⚠️ 已经在录音中');
      return false;
    }

    try {
      // 确保已初始化
      if (!_isInited) {
        await init();
      }

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // 使用 .m4a 扩展名，AAC 编码（Android/iOS 都支持）
      _currentRecordPath = '${tempDir.path}/voice_$timestamp.m4a';

      logger.debug('🎤 开始录音: $_currentRecordPath');

      // 重置时长
      _currentDuration = 0;
      final startTime = DateTime.now();

      // 使用定时器手动更新时长（flutter_sound的onProgress在某些设备上不可靠）
      _progressSubscription?.cancel();
      _progressSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
        _currentDuration = DateTime.now().difference(startTime).inSeconds;
        logger.debug('⏱️ 录音时长: ${_currentDuration}秒');
        onDurationUpdate?.call(_currentDuration);

        // 检查是否达到最大时长
        if (_currentDuration >= maxDurationSeconds) {
          logger.debug('⏱️ 达到最大录音时长 ${maxDurationSeconds}秒');
          onMaxDurationReached?.call();
        }
      });

      // 开始录制，使用 AAC 编码（Android/iOS 原生支持）
      await _recorder.startRecorder(
        toFile: _currentRecordPath,
        codec: Codec.aacMP4, // AAC 编码，MP4 容器（最通用）
        bitRate: 64000, // 64kbps，AAC 语音质量好
        sampleRate: 16000, // 16kHz，语音足够
      );

      _isRecording = true;
      logger.debug('🎤 录音已开始');

      return true;
    } catch (e) {
      logger.error('开始录音失败', error: e);
      onError?.call('开始录音失败: $e');
      _cleanup();
      return false;
    }
  }

  /// 停止录音
  ///
  /// 返回录音文件路径和时长，如果录音失败返回null
  Future<Map<String, dynamic>?> stopRecording() async {
    if (!_isRecording) {
      logger.debug('⚠️ 没有正在进行的录音');
      return null;
    }

    try {
      // 先保存当前时长（在清理之前）
      final duration = _currentDuration;
      
      // 停止录音
      final path = await _recorder.stopRecorder();

      logger.debug('🎤 停止录音: path=$path, duration=${duration}秒');

      // 清理
      _progressSubscription?.cancel();
      _progressSubscription = null;
      _isRecording = false;

      // 检查录音文件是否存在
      if (path == null || path.isEmpty) {
        logger.debug('❌ 录音文件路径为空');
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        logger.debug('❌ 录音文件不存在: $path');
        return null;
      }

      final fileSize = await file.length();
      logger.debug('📁 录音文件大小: $fileSize bytes');

      // 如果录音时长太短（小于1秒），不保存
      if (duration < 1) {
        logger.debug('⚠️ 录音时长太短，不保存');
        await file.delete();
        return null;
      }

      return {
        'path': path,
        'duration': duration,
        'size': fileSize,
      };
    } catch (e) {
      logger.error('停止录音失败', error: e);
      _cleanup();
      return null;
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();

      // 删除录音文件
      if (_currentRecordPath != null) {
        final file = File(_currentRecordPath!);
        if (await file.exists()) {
          await file.delete();
          logger.debug('🗑️ 已删除取消的录音文件');
        }
      }
    } catch (e) {
      logger.error('取消录音失败', error: e);
    } finally {
      _cleanup();
    }
  }

  /// 获取OPUS文件上传URL
  Future<OssUploadInfo> _getOpusUploadUrl({
    required String token,
    required String fileName,
  }) async {
    try {
      final url = ApiConfig.getApiUrl(ApiConfig.ossGetOpusUploadUrl);
      logger.debug('📤 请求语音上传URL: $url');
      logger.debug('   fileName: $fileName');

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

      logger.debug('📥 响应状态码: ${response.statusCode}');
      logger.debug('📥 响应数据: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0 || data['code'] == 200) {
          return OssUploadInfo.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? '获取上传URL失败');
        }
      } else {
        throw Exception('获取上传URL失败: ${response.statusCode}');
      }
    } catch (e) {
      logger.error('获取语音上传URL失败', error: e);
      rethrow;
    }
  }

  /// 上传语音文件到OSS
  ///
  /// 参数:
  /// - token: 认证token
  /// - filePath: 语音文件路径
  /// - onProgress: 上传进度回调
  ///
  /// 返回:
  /// - url: 语音文件URL
  /// - fileName: 文件名
  static Future<Map<String, dynamic>> uploadVoice({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    final service = VoiceRecordService();
    return service._uploadVoiceInternal(
      token: token,
      filePath: filePath,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> _uploadVoiceInternal({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    try {
      logger.debug('📤 开始上传语音文件: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('语音文件不存在: $filePath');
      }

      // 获取文件名
      final fileName = filePath.split('/').last;

      // 1. 向后端请求 OSS 上传 URL
      logger.debug('📤 向后端请求上传地址...');
      final uploadInfo = await _getOpusUploadUrl(
        token: token,
        fileName: fileName,
      );

      logger.debug('✅ 获取上传URL成功:');
      logger.debug('   uploadUrl: ${uploadInfo.uploadUrl}');
      logger.debug('   fileUrl: ${uploadInfo.fileUrl}');
      logger.debug('   contentType: ${uploadInfo.contentType}');

      // 2. 上传文件到 OSS
      logger.debug('📤 上传文件到OSS...');
      final fileLength = await file.length();

      final response = await _dio.put(
        uploadInfo.uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': uploadInfo.contentType,
            'Content-Length': fileLength,
          },
        ),
        onSendProgress: (sent, total) {
          onProgress?.call(sent, total);
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('上传到OSS失败: ${response.statusCode}');
      }

      logger.debug('✅ 语音文件上传成功: ${uploadInfo.fileUrl}');

      return {
        'url': uploadInfo.fileUrl,
        'file_name': fileName,
      };
    } catch (e) {
      logger.error('上传语音文件失败', error: e);
      rethrow;
    }
  }

  /// 清理资源
  void _cleanup() {
    _isRecording = false;
    _currentRecordPath = null;
    _currentDuration = 0;

    _progressSubscription?.cancel();
    _progressSubscription = null;
  }

  /// 释放资源
  Future<void> dispose() async {
    _cleanup();
    if (_isInited) {
      await _recorder.closeRecorder();
      _isInited = false;
    }
    _initCompleter = null;
  }
}
