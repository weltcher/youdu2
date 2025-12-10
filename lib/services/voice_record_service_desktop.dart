import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      contentType: json['contentType'] as String? ?? 'audio/ogg',
    );
  }
}

/// 语音录制服务（桌面端 Stub 实现）
///
/// 桌面端暂不支持语音录制功能
class VoiceRecordService {
  static final VoiceRecordService _instance = VoiceRecordService._internal();
  factory VoiceRecordService() => _instance;
  VoiceRecordService._internal();

  // 录音状态
  bool _isRecording = false;

  // 最大录音时长（秒）
  static const int maxDurationSeconds = 60;

  // 录音状态回调
  Function(int seconds)? onDurationUpdate;
  Function()? onMaxDurationReached;
  Function(String error)? onError;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 当前录音时长（秒）
  int get currentDuration => 0;

  /// 是否已初始化
  bool get isInited => false;

  /// 初始化录音器
  Future<void> init() async {
    logger.debug('🎤 桌面端不支持语音录制功能');
    throw UnsupportedError('桌面端暂不支持语音录制功能');
  }

  /// 检查麦克风权限
  Future<bool> checkPermission() async {
    return false;
  }

  /// 开始录音
  Future<bool> startRecording() async {
    logger.debug('⚠️ 桌面端不支持语音录制功能');
    onError?.call('桌面端暂不支持语音录制功能');
    return false;
  }

  /// 停止录音
  Future<Map<String, dynamic>?> stopRecording() async {
    return null;
  }

  /// 取消录音
  Future<void> cancelRecording() async {}

  /// 上传语音文件到OSS
  static Future<Map<String, dynamic>> uploadVoice({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    throw UnsupportedError('桌面端暂不支持语音上传功能');
  }

  /// 释放资源
  Future<void> dispose() async {}
}
