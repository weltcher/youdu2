// 语音录制服务 - 平台自适应
//
// 策略：
// - iOS：使用 record 包（更稳定）
// - Android：使用 flutter_sound（原有实现）
// - 桌面端（Windows/Linux/macOS）：使用桌面端实现（stub，不支持录音）
//
// 使用运行时平台检测来选择实现

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'voice_record_service_mobile.dart' as mobile;
import 'voice_record_service_desktop.dart' as desktop;
import 'voice_record_service_ios.dart' as ios;

// 导出接口类型
export 'voice_record_service_interface.dart';

/// 判断是否为移动平台
bool _isMobilePlatform() {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// 判断是否为 iOS 平台
bool _isIOSPlatform() {
  if (kIsWeb) return false;
  return Platform.isIOS;
}

/// 语音录制服务
/// 
/// 根据运行平台自动选择实现：
/// - iOS: 使用 record 包
/// - Android: 使用 flutter_sound
/// - 桌面端: stub
class VoiceRecordService {
  static VoiceRecordService? _instance;
  
  // 内部实现
  dynamic _impl;
  // iOS 专用实现
  ios.VoiceRecordServiceIOS? _iosImpl;
  
  factory VoiceRecordService() {
    _instance ??= VoiceRecordService._internal();
    return _instance!;
  }
  
  VoiceRecordService._internal() {
    if (_isIOSPlatform()) {
      // iOS 使用 record 包
      _iosImpl = ios.VoiceRecordServiceIOS();
      _impl = null;
    } else if (_isMobilePlatform()) {
      // Android 使用 flutter_sound
      _impl = mobile.VoiceRecordService();
      _iosImpl = null;
    } else {
      // 桌面端
      _impl = desktop.VoiceRecordService();
      _iosImpl = null;
    }
  }

  // 代理所有方法和属性到内部实现
  bool get isRecording {
    if (_iosImpl != null) return _iosImpl!.isRecording;
    return _impl.isRecording;
  }
  
  int get currentDuration {
    if (_iosImpl != null) return _iosImpl!.currentDuration;
    return _impl.currentDuration;
  }
  
  bool get isInited {
    if (_iosImpl != null) return true; // iOS 实现不需要显式初始化状态
    return _impl.isInited;
  }
  
  // 回调转发
  Function(int seconds)? get onDurationUpdate {
    if (_iosImpl != null) return _iosImpl!.onDurationUpdate;
    return _impl.onDurationUpdate;
  }
  set onDurationUpdate(Function(int seconds)? callback) {
    if (_iosImpl != null) {
      _iosImpl!.onDurationUpdate = callback;
    } else {
      _impl.onDurationUpdate = callback;
    }
  }
  
  Function()? get onMaxDurationReached {
    if (_iosImpl != null) return _iosImpl!.onMaxDurationReached;
    return _impl.onMaxDurationReached;
  }
  set onMaxDurationReached(Function()? callback) {
    if (_iosImpl != null) {
      _iosImpl!.onMaxDurationReached = callback;
    } else {
      _impl.onMaxDurationReached = callback;
    }
  }
  
  Function(String error)? get onError {
    if (_iosImpl != null) return _iosImpl!.onError;
    return _impl.onError;
  }
  set onError(Function(String error)? callback) {
    if (_iosImpl != null) {
      _iosImpl!.onError = callback;
    } else {
      _impl.onError = callback;
    }
  }
  
  Future<void> init() {
    if (_iosImpl != null) return _iosImpl!.init();
    return _impl.init();
  }
  
  Future<bool> checkPermission() {
    if (_iosImpl != null) return _iosImpl!.checkPermission();
    return _impl.checkPermission();
  }
  
  Future<bool> startRecording() {
    if (_iosImpl != null) return _iosImpl!.startRecording();
    return _impl.startRecording();
  }
  
  Future<Map<String, dynamic>?> stopRecording() {
    if (_iosImpl != null) return _iosImpl!.stopRecording();
    return _impl.stopRecording();
  }
  
  Future<void> cancelRecording() {
    if (_iosImpl != null) return _iosImpl!.cancelRecording();
    return _impl.cancelRecording();
  }
  
  Future<void> dispose() {
    if (_iosImpl != null) return _iosImpl!.dispose();
    return _impl.dispose();
  }
  
  static Future<Map<String, dynamic>> uploadVoice({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) {
    if (_isIOSPlatform()) {
      // iOS 使用专用上传
      return ios.VoiceRecordServiceIOS.uploadVoice(
        token: token,
        filePath: filePath,
        onProgress: onProgress,
      );
    } else if (_isMobilePlatform()) {
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
