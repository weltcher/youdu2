import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// 移动端权限助手
class MobilePermissionHelper {
  /// 请求相机权限
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // 显示设置对话框
      if (context.mounted) {
        await _showPermissionDialog(
          context,
          title: '需要相机权限',
          message: '请在设置中允许访问相机，以便拍照和扫描二维码。',
        );
      }
    }

    return false;
  }

  /// 请求麦克风权限
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDialog(
          context,
          title: '需要麦克风权限',
          message: '请在设置中允许访问麦克风，以便进行语音通话。',
        );
      }
    }

    return false;
  }

  /// 请求存储权限
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // 检查是否已经有权限
    if (await Permission.storage.isGranted ||
        await Permission.photos.isGranted) {
      return true;
    }

    // 尝试请求照片权限（适用于iOS和Android 13+）
    PermissionStatus status = await Permission.photos.request();

    // 如果照片权限被拒绝，尝试请求存储权限（适用于Android 12及以下）
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDialog(
          context,
          title: '需要存储权限',
          message: '请在设置中允许访问存储，以便发送和保存文件。',
        );
      }
    }

    return false;
  }

  /// 请求通知权限
  static Future<bool> requestNotificationPermission(
    BuildContext context,
  ) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDialog(
          context,
          title: '需要通知权限',
          message: '请在设置中允许发送通知，以便接收新消息提醒。',
        );
      }
    }

    return false;
  }

  /// 请求所有必要权限
  static Future<Map<String, bool>> requestAllPermissions(
    BuildContext context,
  ) async {
    final results = <String, bool>{};

    // 请求通知权限
    results['notification'] = await requestNotificationPermission(context);

    // 其他权限根据需要请求

    logger.debug('权限请求结果: $results');
    return results;
  }

  /// 检查权限状态
  static Future<Map<Permission, PermissionStatus>> checkPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
      Permission.photos,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }

    return statuses;
  }

  /// 显示权限对话框
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  /// 处理键盘高度变化
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// 获取安全区域padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}
