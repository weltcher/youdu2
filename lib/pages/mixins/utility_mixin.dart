import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import '../../utils/storage.dart';
import '../../services/api_service.dart';

/// 工具方法 Mixin
mixin UtilityMixin<T extends StatefulWidget> on State<T> {
  String? get token;
  String get userStatus;
  set userStatus(String value);

  DateTime get lastActivityTime;
  set lastActivityTime(DateTime value);

  Timer? get autoOfflineTimer;
  set autoOfflineTimer(Timer? value);

  /// 初始化自动离线定时器
  Future<void> initAutoOfflineTimer() async {
    logger.debug('🕐 初始化自动离线定时器...');

    final enabled = await Storage.getIdleStatusEnabled();
    final minutes = await Storage.getIdleMinutes();

    logger.debug('  自动离线开关: ${enabled ? "✅ 已开启" : "❌ 已关闭"}');
    logger.debug('  自动离线时间: $minutes分钟');

    if (!enabled) {
      logger.debug('  ℹ️ 自动离线功能未开启，跳过初始化');
      autoOfflineTimer?.cancel();
      return;
    }

    lastActivityTime = DateTime.now();
    startAutoOfflineTimer(minutes);
  }

  /// 启动自动离线定时器
  void startAutoOfflineTimer(int minutes) {
    autoOfflineTimer?.cancel();

    logger.debug('✅ 启动自动离线定时器: $minutes分钟后检查是否需要自动离线');

    autoOfflineTimer = Timer(Duration(minutes: minutes), () async {
      logger.debug('📴 【自动离线定时器触发】');

      final enabled = await Storage.getIdleStatusEnabled();
      if (!enabled) {
        logger.debug('  自动离线功能已关闭，不执行自动离线');
        return;
      }

      final now = DateTime.now();
      final idleDuration = now.difference(lastActivityTime);
      final idleMinutes = idleDuration.inMinutes;

      logger.debug('  当前时间: $now');
      logger.debug('  最后活动时间: $lastActivityTime');
      logger.debug('  闲置时长: $idleMinutes 分钟');

      if (idleMinutes >= minutes) {
        logger.debug('  ✅ 闲置时长超过设定值，执行自动离线');
        await sendOfflineStatus();
        setState(() {
          userStatus = 'offline';
        });
      } else {
        logger.debug('  ℹ️ 闲置时长不足，不执行自动离线');
      }

      // 重新启动定时器
      startAutoOfflineTimer(minutes);
    });
  }

  /// 记录用户活动
  void recordUserActivity() {
    lastActivityTime = DateTime.now();
  }

  /// 发送离线状态
  Future<void> sendOfflineStatus() async {
    try {
      if (token == null || token!.isEmpty) {
        logger.debug('未登录，无法发送状态');
        return;
      }

      final response = await ApiService.updateUserStatus(
        token: token!,
        status: 'offline',
      );

      if (response['code'] == 0) {
        logger.debug('✅ 离线状态发送成功');
      } else {
        logger.debug('❌ 离线状态发送失败: ${response['message']}');
      }
    } catch (e) {
      logger.debug('❌ 发送离线状态异常: $e');
    }
  }

  /// 检查并恢复被删除的会话
  Future<void> checkAndRestoreDeletedChat({
    required bool isGroup,
    required int id,
  }) async {
    try {
      final contactKey = Storage.generateContactKey(isGroup: isGroup, id: id);
      final isDeleted = await Storage.isChatDeletedForCurrentUser(contactKey);
      if (isDeleted) {
        logger.debug('检测到被删除的会话，正在恢复: $contactKey');
        await Storage.removeDeletedChatForCurrentUser(contactKey);
        logger.debug('会话已恢复: $contactKey');
      }
    } catch (e) {
      logger.debug('检查/恢复会话失败: $e');
    }
  }

  /// 标记消息为已读
  Future<void> markMessagesAsRead(int userId) async {
    try {
      if (token == null || token!.isEmpty) {
        return;
      }

      final response = await ApiService.markMessagesAsRead(
        token: token!,
        senderId: userId,
      );

      if (response['code'] == 0) {
        logger.debug('标记消息已读成功');
      }
    } catch (e) {
      logger.debug('标记消息已读失败: $e');
    }
  }

  /// 显示 SnackBar
  void showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 显示错误 SnackBar
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// 显示成功 SnackBar
  void showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
}
