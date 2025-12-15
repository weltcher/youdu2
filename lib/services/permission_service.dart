import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// 权限请求服务
/// 在应用启动时请求必要的权限
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 在应用启动时请求所有必要的权限
  /// 
  /// 包括：
  /// - 相机权限（用于拍照和视频通话）
  /// - 麦克风权限（用于语音和视频通话）
  /// - 存储权限（用于保存文件）
  /// - 通知权限（用于接收消息通知）
  Future<void> requestInitialPermissions(BuildContext context) async {
    try {
      logger.info('🔐 开始请求应用权限...');

      // 定义需要请求的权限列表
      final permissions = <Permission>[];

      // 相机权限（iOS 和 Android 都需要）
      permissions.add(Permission.camera);

      // 麦克风权限（iOS 和 Android 都需要）
      permissions.add(Permission.microphone);

      // 通知权限
      permissions.add(Permission.notification);

      // 存储权限（根据平台和 Android 版本不同）
      if (Platform.isAndroid) {
        // Android 13+ 使用新的媒体权限
        permissions.add(Permission.photos);
        permissions.add(Permission.videos);
        
        // Android 12 及以下使用传统存储权限
        permissions.add(Permission.storage);
      } else if (Platform.isIOS) {
        // iOS 使用照片库权限
        permissions.add(Permission.photos);
      }

      // iOS特殊处理：逐个请求权限
      if (Platform.isIOS) {
        logger.info('📱 iOS平台：检查并请求权限');
        final statuses = <Permission, PermissionStatus>{};
        final needsSettings = <Permission>[];
        
        for (final permission in permissions) {
          try {
            // 先检查当前状态
            final currentStatus = await permission.status;
            
            logger.debug('  ${_getPermissionName(permission)}: ${_getStatusText(currentStatus)}');
            
            // 如果权限未授予，尝试请求
            if (!currentStatus.isGranted) {
              // 检查是否已被永久拒绝（用户之前拒绝过）
              if (currentStatus.isPermanentlyDenied) {
                logger.debug('  → 已被永久拒绝，需要在系统设置中开启');
                needsSettings.add(permission);
                statuses[permission] = currentStatus;
              } else {
                // 尝试请求权限（会弹出系统对话框）
                logger.debug('  → 请求权限（将弹出系统对话框）...');
                final newStatus = await permission.request();
                statuses[permission] = newStatus;
                logger.debug('  → 用户选择: ${_getStatusText(newStatus)}');
                
                // 如果用户拒绝了，记录到需要设置列表
                if (!newStatus.isGranted) {
                  needsSettings.add(permission);
                }
                
                // 每次请求之间稍微延迟，避免弹窗太快
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } else {
              logger.debug('  → 已授权');
              statuses[permission] = currentStatus;
            }
          } catch (e) {
            logger.error('  请求 ${_getPermissionName(permission)} 失败: $e');
          }
        }
        
        // 记录最终结果
        logger.info('📋 权限最终状态：');
        statuses.forEach((permission, status) {
          final permissionName = _getPermissionName(permission);
          final statusText = _getStatusText(status);
          logger.info('  - $permissionName: $statusText');
        });
        
        // 如果有权限需要在设置中开启，显示提示
        if (needsSettings.isNotEmpty && context.mounted) {
          final permissionNames = needsSettings.map(_getPermissionName).join('、');
          logger.info('⚠️ 以下权限未授权: $permissionNames');
          
          // 延迟显示对话框，避免在应用启动时立即弹出
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              _showSettingsDialog(context, needsSettings);
            }
          });
        } else {
          logger.info('✅ 所有权限已授权');
        }
        
        logger.info('✅ iOS权限检查完成');
      } else {
        // Android：批量请求权限
        final statuses = await permissions.request();

        // 记录权限请求结果
        logger.info('📋 权限请求结果：');
        statuses.forEach((permission, status) {
          final permissionName = _getPermissionName(permission);
          final statusText = _getStatusText(status);
          logger.info('  - $permissionName: $statusText');
        });

        // 检查是否有被永久拒绝的权限
        final deniedPermissions = <Permission>[];
        final permanentlyDeniedPermissions = <Permission>[];

        statuses.forEach((permission, status) {
          if (status.isDenied) {
            deniedPermissions.add(permission);
          } else if (status.isPermanentlyDenied) {
            permanentlyDeniedPermissions.add(permission);
          }
        });

        // 如果有被永久拒绝的权限，提示用户去设置中开启
        if (permanentlyDeniedPermissions.isNotEmpty && context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            permanentlyDeniedPermissions,
            isPermanent: true,
          );
        } else if (deniedPermissions.isNotEmpty && context.mounted) {
          // 如果有被拒绝的权限，提示用户
          await _showPermissionDeniedDialog(
            context,
            deniedPermissions,
            isPermanent: false,
          );
        }

        logger.info('✅ 权限请求完成');
      }
    } catch (e) {
      logger.error('❌ 请求权限时发生错误: $e');
    }
  }

  /// 显示权限被拒绝的对话框
  Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    List<Permission> permissions,
    {required bool isPermanent}
  ) async {
    final permissionNames = permissions.map(_getPermissionName).join('、');
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('需要权限'),
        content: Text(
          isPermanent
              ? '应用需要以下权限才能正常工作：\n\n$permissionNames\n\n请在系统设置中开启这些权限。'
              : '应用需要以下权限才能正常工作：\n\n$permissionNames\n\n部分功能可能无法使用。',
        ),
        actions: [
          if (!isPermanent)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isPermanent) {
                // 打开应用设置
                openAppSettings();
              }
            },
            child: Text(isPermanent ? '去设置' : '确定'),
          ),
        ],
      ),
    );
  }

  /// 显示需要在设置中开启权限的对话框（iOS专用）
  Future<void> _showSettingsDialog(
    BuildContext context,
    List<Permission> permissions,
  ) async {
    final permissionNames = permissions.map(_getPermissionName).join('、');
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('需要开启权限'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '为了正常使用以下功能，需要开启相应权限：',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: permissions.map((p) {
                  final name = _getPermissionName(p);
                  final desc = _getPermissionDescription(p);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            '$name：$desc',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '点击"去设置"将跳转到系统设置页面，请在"有度"应用设置中开启相应权限。',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 获取权限的功能描述
  String _getPermissionDescription(Permission permission) {
    if (permission == Permission.camera) return '拍照和视频通话';
    if (permission == Permission.microphone) return '语音和视频通话';
    if (permission == Permission.photos) return '选择和保存图片';
    if (permission == Permission.videos) return '选择和保存视频';
    if (permission == Permission.storage) return '保存文件';
    if (permission == Permission.notification) return '接收消息通知';
    return '应用功能';
  }

  /// 获取权限的中文名称
  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) return '相机';
    if (permission == Permission.microphone) return '麦克风';
    if (permission == Permission.photos) return '相册';
    if (permission == Permission.videos) return '视频';
    if (permission == Permission.storage) return '存储';
    if (permission == Permission.notification) return '通知';
    return permission.toString();
  }

  /// 获取权限状态的中文描述
  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅ 已授权';
      case PermissionStatus.denied:
        return '❌ 已拒绝';
      case PermissionStatus.permanentlyDenied:
        return '🚫 永久拒绝';
      case PermissionStatus.restricted:
        return '⚠️ 受限制';
      case PermissionStatus.limited:
        return '⚠️ 部分授权';
      case PermissionStatus.provisional:
        return '⚠️ 临时授权';
      default:
        return '❓ 未知';
    }
  }

  /// 检查特定权限是否已授权
  Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// 请求特定权限
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }
}
