import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../../services/message_service.dart';
import '../../utils/logger.dart';
import '../../constants/upload_limits.dart';

/// 消息处理功能 Mixin
mixin MessageHandlerMixin<T extends StatefulWidget> on State<T> {
  // 消息相关状态
  List<MessageModel> get messages;
  set messages(List<MessageModel> value);

  bool get isLoadingMessages;
  set isLoadingMessages(bool value);

  String? get messagesError;
  set messagesError(String? value);

  int? get currentChatUserId;
  set currentChatUserId(int? value);

  bool get isCurrentChatGroup;
  set isCurrentChatGroup(bool value);

  int get currentUserId;
  String? get token;

  TextEditingController get messageInputController;
  ScrollController get messageScrollController;

  bool get isSendingMessage;
  set isSendingMessage(bool value);

  List<File> get selectedImageFiles;
  bool get isUploadingImage;
  set isUploadingImage(bool value);

  List<File> get selectedFiles;
  bool get isUploadingFile;
  set isUploadingFile(bool value);

  MessageModel? get quotedMessage;
  set quotedMessage(MessageModel? value);

  /// 加载消息历史
  Future<void> loadMessageHistory({
    required int userId,
    required bool isGroup,
    int page = 1,
    int pageSize = 50,
  }) async {
    logger.debug('📜 加载消息历史 - userId: $userId, isGroup: $isGroup');

    setState(() {
      isLoadingMessages = true;
      messagesError = null;
    });

    try {
      if (token == null || token!.isEmpty) {
        setState(() {
          isLoadingMessages = false;
          messagesError = '未登录';
        });
        return;
      }

      // 从本地数据库获取消息
      final messageService = MessageService();
      final messagesList = isGroup
          ? await messageService.getGroupMessageList(
              groupId: userId,
              page: page,
              pageSize: pageSize,
            )
          : await messageService.getMessages(
              contactId: userId,
              page: page,
              pageSize: pageSize,
            );

      setState(() {
        messages = messagesList;
        isLoadingMessages = false;
      });

      logger.debug('从本地数据库加载消息历史成功，共 ${messagesList.length} 条消息');

      // 滚动到底部
      scrollToBottom(animated: false);
    } catch (e) {
      logger.debug('加载消息历史失败: $e');
      setState(() {
        isLoadingMessages = false;
        messagesError = e.toString();
      });
    }
  }

  /// 发送消息
  Future<void> sendMessage({
    String? imageUrl,
    String messageType = 'text',
    String? fileName,
    bool autoScroll = true,
  }) async {
    String content;

    if (messageType == 'image' && imageUrl != null) {
      content = imageUrl;
    } else if (messageType == 'file' && imageUrl != null) {
      content = imageUrl;
    } else {
      content = messageInputController.text.trim();
      if (content.isEmpty || currentChatUserId == null) {
        return;
      }
    }

    if (currentChatUserId == null) {
      return;
    }

    if (isSendingMessage) {
      return;
    }

    setState(() {
      isSendingMessage = true;
    });

    try {
      // 🔴 使用serverId（服务器ID）而不是本地ID，确保接收方能找到被引用的消息
      final quotedId = quotedMessage?.serverId ?? quotedMessage?.id;
      final quotedContent = quotedMessage != null
          ? getQuotedMessagePreview(quotedMessage!)
          : null;

      String finalMessageType = messageType;
      if (quotedMessage != null && messageType == 'text') {
        finalMessageType = 'quoted';
        logger.debug(
          '📝 发送引用消息 - 原消息ID: ${quotedMessage!.id}, 服务器ID: ${quotedMessage!.serverId}, 引用内容: $quotedContent',
        );
      }

      logger.debug(
        '📤 发送消息 - 类型: $finalMessageType, 内容: $content, 是否群组: $isCurrentChatGroup',
      );

      Map<String, dynamic> response;

      if (isCurrentChatGroup) {
        response = await ApiService.sendGroupMessage(
          token: token!,
          groupId: currentChatUserId!,
          content: content,
          messageType: finalMessageType,
          fileName: fileName,
          quotedMessageId: quotedId,
          quotedMessageContent: quotedContent,
        );
      } else {
        response = await ApiService.sendMessage(
          token: token!,
          receiverId: currentChatUserId!,
          content: content,
          messageType: finalMessageType,
          fileName: fileName,
          quotedMessageId: quotedId,
          quotedMessageContent: quotedContent,
        );
      }

      if (response['code'] == 0) {
        // 发送成功，清空输入框
        if (messageType == 'text') {
          messageInputController.clear();
        }

        // 清空引用消息
        if (quotedMessage != null) {
          setState(() {
            quotedMessage = null;
          });
        }

        // 发送方也需要滚动到底部，显示刚发送的消息
        scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '发送失败')),
          );
        }
      }

      setState(() {
        isSendingMessage = false;
      });
    } catch (e) {
      setState(() {
        isSendingMessage = false;
      });
      logger.debug('发送消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    }
  }

  /// 发送图片和文字
  Future<void> sendMessageWithImage() async {
    if (currentChatUserId == null) {
      return;
    }

    final textContent = messageInputController.text.trim();
    final hasImages = selectedImageFiles.isNotEmpty;
    final hasFiles = selectedFiles.isNotEmpty;
    final hasText = textContent.isNotEmpty;

    if (!hasImages && !hasFiles && !hasText) {
      return;
    }

    try {
      if (token == null) {
        throw Exception('未登录');
      }

      // 1. 先发送所有图片
      if (hasImages) {
        setState(() {
          isUploadingImage = true;
        });

        for (var imageFile in selectedImageFiles) {
          final fileSize = await imageFile.length();
          if (fileSize > kMaxImageUploadBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('图片大小不能超过32MB')),
              );
            }
            continue;
          }

          final response = await ApiService.uploadImage(
            token: token!,
            filePath: imageFile.path,
          );

          if (response['code'] == 0 && response['data'] != null) {
            final imageUrl = response['data']['url'];
            await sendMessage(
              imageUrl: imageUrl,
              messageType: 'image',
              autoScroll: false,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message'] ?? '图片上传失败')),
              );
            }
            setState(() {
              isUploadingImage = false;
            });
            return;
          }
        }

        setState(() {
          isUploadingImage = false;
          selectedImageFiles.clear();
        });
      }

      // 2. 再发送所有文件
      if (hasFiles) {
        setState(() {
          isUploadingFile = true;
        });

        for (var file in selectedFiles) {
          final fileSize = await file.length();
          if (fileSize > kMaxFileUploadBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件大小不能超过1GB')),
              );
            }
            continue;
          }

          final response = await ApiService.uploadFile(
            token: token!,
            filePath: file.path,
          );

          if (response['code'] == 0 && response['data'] != null) {
            final fileUrl = response['data']['url'];
            final fileName = response['data']['file_name'];

            await sendMessage(
              imageUrl: fileUrl,
              messageType: 'file',
              fileName: fileName,
              autoScroll: false,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message'] ?? '文件上传失败')),
              );
            }
            setState(() {
              isUploadingFile = false;
            });
            return;
          }
        }

        setState(() {
          isUploadingFile = false;
          selectedFiles.clear();
        });
      }

      // 3. 最后发送文本
      if (hasText) {
        await sendMessage(
          messageType: 'text',
          autoScroll: false, // 文本发送时不滚动
        );
      }

      // 4. 所有内容发送完毕后，发送方也需要滚动到底部
      if (hasImages || hasFiles || hasText) {
        scrollToBottom();
      }
    } catch (e) {
      setState(() {
        isUploadingImage = false;
        isUploadingFile = false;
        isSendingMessage = false;
      });
      logger.debug('发送失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    }
  }

  /// 滚动到底部
  /// 确保红色占位条和最后一条消息完全显示在屏幕上
  void scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 第一次延迟，等待新消息渲染
      Future.delayed(const Duration(milliseconds: 100), () {
        // 再次使用 addPostFrameCallback 确保layout已更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (messageScrollController.hasClients) {
              final maxScroll =
                  messageScrollController.position.maxScrollExtent;
              // 额外滚动9999像素，确保红色条和最后一条消息完全可见
              final extraScroll = 9999.0;
              final targetScroll = maxScroll + extraScroll;

              if (animated) {
                messageScrollController.animateTo(
                  targetScroll,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } else {
                messageScrollController.jumpTo(targetScroll);
              }
            }
          });
        });
      });
    });
  }

  /// 滚动到指定消息
  void scrollToMessage(int messageId) {
    // 实现滚动到指定消息的逻辑
  }

  /// 获取引用消息的预览文本
  String getQuotedMessagePreview(MessageModel message) {
    if (message.messageType == 'image') {
      return '[图片]';
    } else if (message.messageType == 'file') {
      return '[文件] ${message.fileName ?? "未知文件"}';
    } else if (message.messageType == 'quoted') {
      return message.content;
    } else {
      return message.content;
    }
  }

  /// 撤回消息
  Future<void> recallMessage(MessageModel message) async {
    try {
      if (token == null) {
        throw Exception('未登录');
      }

      final response = await ApiService.recallMessage(
        token: token!,
        messageId: message.id,
      );

      if (response['code'] == 0) {
        logger.debug('撤回消息成功');
        // 更新消息状态
        setState(() {
          final index = messages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            messages[index] = MessageModel(
              id: message.id,
              senderId: message.senderId,
              receiverId: message.receiverId,
              senderName: message.senderName,
              receiverName: message.receiverName,
              content: message.content,
              messageType: message.messageType,
              fileName: message.fileName,
              quotedMessageId: message.quotedMessageId,
              quotedMessageContent: message.quotedMessageContent,
              status: 'recalled',
              isRead: message.isRead,
              createdAt: message.createdAt,
              readAt: message.readAt,
            );
          }
        });
      } else {
        throw Exception(response['message'] ?? '撤回失败');
      }
    } catch (e) {
      logger.debug('撤回消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('撤回失败: $e')));
      }
    }
  }

  /// 删除消息
  Future<void> deleteMessage(MessageModel message) async {
    try {
      if (token == null) {
        throw Exception('未登录');
      }

      final response = await ApiService.deleteMessage(
        token: token!,
        messageId: message.id,
      );

      if (response['code'] == 0) {
        logger.debug('删除消息成功');
        setState(() {
          messages.removeWhere((msg) => msg.id == message.id);
        });
      } else {
        throw Exception(response['message'] ?? '删除失败');
      }
    } catch (e) {
      logger.debug('删除消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }
}
