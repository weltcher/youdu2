import 'storage.dart';
import 'logger.dart';

/// 自动下载调试工具
class AutoDownloadDebug {
  /// 打印当前所有自动下载相关的设置
  static Future<void> debugSettings() async {
    final autoDownloadEnabled = await Storage.getAutoDownloadEnabled();
    final autoDownloadSizeMB = await Storage.getAutoDownloadSizeMB();
    final fileStoragePath = await Storage.getFileStoragePath();
    final messageStoragePath = await Storage.getMessageStoragePath();

    // 同时检查空闲状态设置
    await _debugIdleSettings();
  }

  /// 打印空闲状态设置
  static Future<void> _debugIdleSettings() async {
    final idleEnabled = await Storage.getIdleStatusEnabled();
    final idleMinutes = await Storage.getIdleMinutes();
  }

  /// 检查特定消息是否会被自动下载
  static Future<bool> willAutoDownload({
    required String messageType,
    required double fileSizeMB,
  }) async {
    final autoDownloadEnabled = await Storage.getAutoDownloadEnabled();
    final autoDownloadSizeMB = await Storage.getAutoDownloadSizeMB();
    final fileStoragePath = await Storage.getFileStoragePath();

    // 检查消息类型
    if (messageType != 'file' &&
        messageType != 'image' &&
        messageType != 'video') {
      logger.debug('❌ 消息类型 "$messageType" 不支持自动下载');
      return false;
    }

    // 检查开关
    if (!autoDownloadEnabled) {
      logger.debug('❌ 自动下载开关未打开');
      return false;
    }

    // 检查路径
    if (fileStoragePath == null || fileStoragePath.isEmpty) {
      logger.debug('❌ 文件存储路径未设置');
      return false;
    }

    // 检查大小
    if (fileSizeMB > autoDownloadSizeMB) {
      logger.debug(
        '❌ 文件大小 ${fileSizeMB.toStringAsFixed(2)}MB 超过限制 ${autoDownloadSizeMB}MB',
      );
      return false;
    }

    logger.debug('✅ 该文件将被自动下载');
    return true;
  }
}
