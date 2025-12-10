// 语音录制服务 - 平台自适应
//
// 策略：
// - 移动端（Android/iOS）：使用移动端实现（使用 flutter_sound）
// - 桌面端（Windows/Linux/macOS）：使用桌面端实现（stub，不支持录音）
//
// 使用运行时平台检测（Platform.isAndroid || Platform.isIOS）来选择实现
// 注意：移动端实现使用条件导入，在 Windows 上会自动使用 stub，所以可以安全导入

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'voice_record_service_mobile.dart' as mobile;
import 'voice_record_service_desktop.dart' as desktop;

// 导出接口类型
export 'voice_record_service_interface.dart';

/// 判断是否为移动平台
bool _isMobilePlatform() {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// 语音录制服务
/// 
/// 根据运行平台自动选择移动端或桌面端实现
class VoiceRecordService {
  static VoiceRecordService? _instance;
  
  // 内部实现（移动端或桌面端）
  late final dynamic _impl;
  
  factory VoiceRecordService() {
    _instance ??= VoiceRecordService._internal();
    return _instance!;
  }
  
  VoiceRecordService._internal() {
    if (_isMobilePlatform()) {
      _impl = mobile.VoiceRecordService();
    } else {
      _impl = desktop.VoiceRecordService();
    }
  }

  // 代理所有方法和属性到内部实现
  bool get isRecording => _impl.isRecording;
  int get currentDuration => _impl.currentDuration;
  bool get isInited => _impl.isInited;
  
  // 回调转发
  Function(int seconds)? get onDurationUpdate => _impl.onDurationUpdate;
  set onDurationUpdate(Function(int seconds)? callback) {
    _impl.onDurationUpdate = callback;
  }
  
  Function()? get onMaxDurationReached => _impl.onMaxDurationReached;
  set onMaxDurationReached(Function()? callback) {
    _impl.onMaxDurationReached = callback;
  }
  
  Function(String error)? get onError => _impl.onError;
  set onError(Function(String error)? callback) {
    _impl.onError = callback;
  }
  
  Future<void> init() => _impl.init();
  Future<bool> checkPermission() => _impl.checkPermission();
  Future<bool> startRecording() => _impl.startRecording();
  Future<Map<String, dynamic>?> stopRecording() => _impl.stopRecording();
  Future<void> cancelRecording() => _impl.cancelRecording();
  Future<void> dispose() => _impl.dispose();
  
  static Future<Map<String, dynamic>> uploadVoice({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) {
    if (_isMobilePlatform()) {
      return mobile.VoiceRecordService.uploadVoice(
        token: token,
        filePath: filePath,
        onProgress: onProgress,
      );
    } else {
      return desktop.VoiceRecordService.uploadVoice(
        token: token,
        filePath: filePath,
        onProgress: onProgress,
      );
    }
  }
}
