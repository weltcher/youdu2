import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/online_notification_model.dart';
import '../../services/websocket_service.dart';
import '../../utils/logger.dart';

/// WebSocket 消息处理 Mixin
mixin WebSocketHandlerMixin<T extends StatefulWidget> on State<T> {
  // WebSocket 服务
  WebSocketService get wsService;

  // 状态访问
  int get currentUserId;
  int? get currentChatUserId;
  bool get isCurrentChatGroup;

  List<MessageModel> get messages;
  set messages(List<MessageModel> value);

  Map<int, String?> get avatarCache;

  /// 初始化 WebSocket
  Future<void> initWebSocket() async {
    // 设置消息接收回调
    wsService.onMessage = handleWebSocketMessage;

    // 连接 WebSocket
    await wsService.connect();

    logger.debug('WebSocket 初始化完成');
  }

  /// 处理 WebSocket 消息
  void handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'message':
        handleNewMessage(message['data']);
        break;
      case 'offline_messages':
        logger.debug('收到离线消息: ${message['data']}');
        break;
      case 'message_sent':
        logger.debug('消息发送成功: ${message['data']}');
        handleMessageSentConfirmation(message['data']);
        break;
      case 'status_change':
        handleStatusChange(message['data']);
        break;
      case 'online_notification':
        handleOnlineNotification(message['data']);
        break;
      case 'offline_notification':
        handleOfflineNotification(message['data']);
        break;
      case 'status_change_success':
        logger.debug('状态变更成功: ${message['data']}');
        break;
      case 'status_change_error':
        logger.debug('状态变更失败: ${message['data']}');
        break;
      case 'message_recalled':
        handleMessageRecalled(message['data']);
        break;
      case 'group_message':
        handleGroupMessage(message);
        break;
      case 'group_message_sent':
        logger.debug('群组消息发送成功确认: ${message['data']}');
        handleGroupMessageSentConfirmation(message['data']);
        break;
      case 'group_message_error':
        handleGroupMessageError(message['data']);
        break;
      case 'avatar_updated':
        handleAvatarUpdated(message['data']);
        break;
      case 'group_info_updated':
        handleGroupInfoUpdated(message['data']);
        break;
      default:
        logger.debug('未知消息类型: $type');
    }
  }

  /// 处理接收到的新消息
  void handleNewMessage(dynamic data) {
    try {
      if (data == null) return;
      if (!mounted) return;

      final messageData = data as Map<String, dynamic>;
      final senderId = messageData['sender_id'] as int?;
      final content = messageData['content'] as String?;

      logger.debug('📩 收到新消息 - 发送者ID: $senderId, 当前聊天ID: $currentChatUserId');

      if (senderId == null || content == null) {
        logger.debug('消息数据不完整');
        return;
      }

      // 判断消息是否来自当前正在聊天的联系人
      if (currentChatUserId != null && senderId == currentChatUserId) {
        final newMessage = MessageModel.fromJson(messageData);

        setState(() {
          messages.add(newMessage);
        });

        // 滚动到底部（需要在主文件中实现）
        onMessageReceived(newMessage);

        logger.debug('✅ 收到并显示新消息: $content');
      } else {
        // 消息来自其他联系人，刷新最近联系人列表
        logger.debug('💬 收到其他联系人的消息，刷新列表');
        onOtherContactMessage();
      }
    } catch (e) {
      logger.debug('❌ 处理新消息失败: $e');
    }
  }

  /// 处理消息发送成功确认
  void handleMessageSentConfirmation(dynamic data) {
    try {
      if (data == null) return;
      if (!mounted) return;

      final confirmData = data as Map<String, dynamic>;
      final messageId = confirmData['message_id'] as int?;

      if (messageId != null) {
        setState(() {
          final index = messages.indexWhere((msg) => msg.id == 0);
          if (index != -1) {
            final oldMsg = messages[index];
            messages[index] = MessageModel(
              id: messageId,
              senderId: oldMsg.senderId,
              receiverId: oldMsg.receiverId,
              senderName: oldMsg.senderName,
              receiverName: oldMsg.receiverName,
              content: oldMsg.content,
              messageType: oldMsg.messageType,
              fileName: oldMsg.fileName,
              quotedMessageId: oldMsg.quotedMessageId,
              quotedMessageContent: oldMsg.quotedMessageContent,
              isRead: oldMsg.isRead,
              createdAt: oldMsg.createdAt,
            );

            logger.debug('🔄 更新临时消息ID: 0 -> $messageId');
          }
        });
      }
    } catch (e) {
      logger.debug('处理消息确认失败: $e');
    }
  }

  /// 处理消息撤回通知
  void handleMessageRecalled(dynamic data) {
    try {
      if (data == null) return;
      if (!mounted) return;

      final recallData = data as Map<String, dynamic>;
      final messageId = recallData['message_id'] as int?;

      if (messageId == null) {
        logger.debug('撤回消息数据不完整');
        return;
      }

      logger.debug('↩️ 收到消息撤回通知 - 消息ID: $messageId');

      setState(() {
        final index = messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          final oldMessage = messages[index];
          messages[index] = MessageModel(
            id: oldMessage.id,
            senderId: oldMessage.senderId,
            receiverId: oldMessage.receiverId,
            senderName: oldMessage.senderName,
            receiverName: oldMessage.receiverName,
            content: oldMessage.content,
            messageType: oldMessage.messageType,
            fileName: oldMessage.fileName,
            quotedMessageId: oldMessage.quotedMessageId,
            quotedMessageContent: oldMessage.quotedMessageContent,
            status: 'recalled',
            isRead: oldMessage.isRead,
            createdAt: oldMessage.createdAt,
            readAt: oldMessage.readAt,
          );
          logger.debug('消息已更新为撤回状态');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('对方撤回了一条消息')));
      }
    } catch (e) {
      logger.debug('处理消息撤回失败: $e');
    }
  }

  /// 处理群组消息
  void handleGroupMessage(Map<String, dynamic> message) {
    logger.debug('收到群组消息');
    // 需要在主文件中实现具体逻辑
  }

  /// 处理群组消息发送确认
  void handleGroupMessageSentConfirmation(dynamic data) {
    logger.debug('群组消息发送确认');
  }

  /// 处理群组消息错误
  void handleGroupMessageError(dynamic data) {
    logger.debug('群组消息发送错误');
  }

  /// 处理状态变更
  void handleStatusChange(dynamic data) {
    logger.debug('状态变更通知');
  }

  /// 处理上线通知
  void handleOnlineNotification(dynamic data) {
    logger.debug('上线通知');
  }

  /// 处理离线通知
  void handleOfflineNotification(dynamic data) {
    logger.debug('离线通知');
  }

  /// 处理头像更新
  void handleAvatarUpdated(dynamic data) {
    try {
      if (data == null) return;

      final userId = data['user_id'] as int?;
      final avatar = data['avatar'] as String?;

      if (userId != null) {
        setState(() {
          avatarCache[userId] = avatar;
        });
        logger.debug('更新用户头像缓存: userId=$userId');
      }
    } catch (e) {
      logger.debug('处理头像更新失败: $e');
    }
  }

  /// 处理群组信息更新
  void handleGroupInfoUpdated(dynamic data) {
    logger.debug('收到群组信息更新通知: $data');
    // 通知主页面更新群组信息
    onGroupInfoUpdated(data);
  }

  // 需要在主文件中实现的回调方法
  void onMessageReceived(MessageModel message);
  void onOtherContactMessage();
  void onGroupInfoUpdated(dynamic data);
}
