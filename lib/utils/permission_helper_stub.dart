/// 权限助手的存根实现
/// 当 WebRTC 功能被禁用时使用此文件
library;

import 'logger.dart';

/// 权限状态枚举（存根）
class PermissionStatus {
  final bool _isGranted;
  const PermissionStatus._(this._isGranted);

  static const granted = PermissionStatus._(true);
  static const denied = PermissionStatus._(false);

  bool get isGranted => _isGranted;
}

/// 权限类型（存根）
class Permission {
  const Permission._();

  static const microphone = _MicrophonePermission();
  static const camera = _CameraPermission();
}

class _MicrophonePermission {
  const _MicrophonePermission();

  Future<PermissionStatus> request() async {
    logger.debug('⚠️ 权限请求被忽略（WebRTC 未启用）');
    return PermissionStatus.denied;
  }
}

class _CameraPermission {
  const _CameraPermission();

  Future<PermissionStatus> request() async {
    logger.debug('⚠️ 权限请求被忽略（WebRTC 未启用）');
    return PermissionStatus.denied;
  }
}
