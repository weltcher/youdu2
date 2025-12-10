import 'package:flutter/material.dart';
import '../../models/recent_contact_model.dart';
import '../../models/contact_model.dart';
import '../../services/agora_service.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../utils/storage.dart';
import '../../config/feature_config.dart';
import '../../utils/logger.dart';
import '../../utils/permission_helper_impl.dart';
import '../voice_call_page.dart';

/// 通话处理功能 Mixin
mixin CallHandlerMixin<T extends StatefulWidget> on State<T> {
  // 通话相关状态
  bool isShowingIncomingCallDialog = false;
  bool showCallFloatingButton = false;
  int currentCallUserId = 0;
  String currentCallDisplayName = '';
  CallType currentCallType = CallType.voice;
  double floatingButtonX = 0;
  double floatingButtonY = 0;

  // Agora 服务引用（需要在使用此 mixin 的 State 中提供）
  AgoraService? get agoraService;
  int get currentUserId;

  // WebSocket 服务
  final WebSocketService _wsService = WebSocketService();

  /// 显示来电对话框
  void showIncomingCallDialog(
    int userId,
    String displayName,
    CallType callType,
  ) {
    logger.debug('🔔 ========== 显示来电对话框 ==========');
    logger.debug('🔔 用户ID: $userId, 名称: $displayName, 类型: $callType');
    logger.debug('🔔 当前标志状态: $isShowingIncomingCallDialog');

    setState(() {
      isShowingIncomingCallDialog = true;
      // 🔴 修复：立即设置当前通话类型，用于拒接时发送正确的消息
      currentCallType = callType;
    });

    logger.debug('🔔 已设置 isShowingIncomingCallDialog = true');
    logger.debug('🔔 已设置 currentCallType = $callType');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        logger.debug('🔔 AlertDialog builder 被调用');
        return AlertDialog(
          title: Text('${callType == CallType.voice ? '语音' : '视频'}通话'),
          content: Text('$displayName 正在呼叫...'),
          actions: [
            TextButton(
              onPressed: () {
                logger.debug('🔴 ========== 用户点击拒接按钮 ==========');
                final dialogContext = context;
                Navigator.of(dialogContext).pop();

                Future.microtask(() async {
                  logger.debug('🔴 开始执行拒绝通话操作');
                  if (FeatureConfig.enableWebRTC && agoraService != null) {
                    await agoraService!.rejectCall();
                    logger.debug('🔴 拒绝通话操作完成');

                    // 发送拒绝消息（接收方拒绝，显示"已拒绝"）
                    logger.debug('🔴 发送拒绝消息 - callType: $callType');
                    await _sendCallRejectedMessageInMixin(
                      userId,
                      callType,
                      isRejecter: true,
                    );
                  }
                });
              },
              child: const Text('拒接'),
            ),
            ElevatedButton(
              onPressed: () {
                logger.debug('🟢 ========== 用户点击接听按钮 ==========');
                final dialogContext = context;
                Navigator.of(dialogContext).pop();

                Future.microtask(() async {
                  logger.debug('🟢 开始异步操作');

                  if (FeatureConfig.enableWebRTC && agoraService != null) {
                    logger.debug('🟢 准备接听通话...');
                    await agoraService!.acceptCall();
                    logger.debug('🟢 通话已接听');
                  }

                  if (FeatureConfig.enableWebRTC && mounted) {
                    logger.debug('🟢 准备打开通话页面');

                    currentCallUserId = userId;
                    currentCallDisplayName = displayName;
                    currentCallType = callType;

                    final result = await Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (ctx) => VoiceCallPage(
                          targetUserId: userId,
                          targetDisplayName: displayName,
                          isIncoming: true,
                          callType: callType,
                          currentUserId: currentUserId, // 🔴 修复：传递当前用户ID
                        ),
                      ),
                    );

                    if (result is Map && result['showFloatingButton'] == true) {
                      setState(() {
                        showCallFloatingButton = true;
                        floatingButtonX = 0;
                        floatingButtonY = 0;
                      });
                      logger.debug('📱 显示通话悬浮按钮');
                    } else {
                      setState(() {
                        showCallFloatingButton = false;
                      });

                      // 处理通话结束后的结果
                      if (result is Map) {
                        if (result['callRejected'] == true) {
                          // 接收方拒绝了通话，发送拒绝消息
                          final returnedCallType =
                              result['callType'] as CallType?;
                          await _sendCallRejectedMessageInMixin(
                            userId,
                            returnedCallType ?? callType,
                            isRejecter: true,
                          );
                        } else if (result['callCancelled'] == true) {
                          // 接收到取消通知
                          final returnedCallType =
                              result['callType'] as CallType?;
                          await _sendCallCancelledMessageInMixin(
                            userId,
                            returnedCallType ?? callType,
                            isCaller: false,
                          );
                        }
                      }
                    }
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('接听'),
            ),
          ],
        );
      },
    ).then((_) {
      logger.debug('🔔 ========== showDialog.then 回调被触发 ==========');
      if (mounted) {
        setState(() {
          isShowingIncomingCallDialog = false;
        });
      }
    });
  }

  /// 关闭来电对话框（如果正在显示）
  void closeIncomingCallDialogIfShowing() {
    logger.debug(
      '💫 ========== closeIncomingCallDialogIfShowing 被调用 ==========',
    );
    logger.debug('💫 当前标志: $isShowingIncomingCallDialog');

    if (isShowingIncomingCallDialog && mounted) {
      logger.debug('💫 条件满足，准备关闭对话框');

      setState(() {
        isShowingIncomingCallDialog = false;
      });

      try {
        final canPop = Navigator.of(context).canPop();
        logger.debug('💫 canPop 结果: $canPop');

        if (canPop) {
          Navigator.of(context).pop();
          logger.debug('💫 已执行 Navigator.pop()');
        }
      } catch (e) {
        logger.debug('💫 ⚠️ 关闭对话框失败: $e');
      }
    }
  }

  /// 发起语音通话
  Future<void> startVoiceCall(RecentContactModel contact) async {
    logger.debug('📞 准备发起语音通话:');
    logger.debug('  - 联系人类型: ${contact.type}');
    logger.debug('  - 联系人userId: ${contact.userId}');
    logger.debug('  - 联系人显示名: ${contact.displayName}');
    logger.debug('  - 当前用户 ID: $currentUserId');

    if (contact.userId == currentUserId) {
      logger.debug('检测到联系人userId 等于当前用户 ID，阻止通话');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('不能给自己打电话')));
      }
      return;
    }

    // 🔴 检查好友关系（前端限制）
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final contactsResponse = await ApiService.getContacts(token: token);
        if (contactsResponse['code'] == 0) {
          final contactsData = contactsResponse['data']['contacts'] as List?;
          if (contactsData != null) {
            final contacts = contactsData.map((json) => ContactModel.fromJson(json)).toList();
            final contactModel = contacts.firstWhere(
              (c) => c.friendId == contact.userId,
              orElse: () => ContactModel(
                relationId: 0,
                userId: 0,
                friendId: contact.userId,
                username: contact.username,
                avatar: '',
                status: 'offline',
                createdAt: DateTime.now(),
                isDeleted: true, // 默认标记为已删除（找不到联系人）
              ),
            );

            // 检查是否被删除
            if (contactModel.isDeleted) {
              logger.debug('📞 ⚠️ 该联系人已被删除，无法发起语音通话');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('该联系人已被删除，无法发起通话'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            // 检查是否被拉黑
            if (contactModel.isBlocked || contactModel.isBlockedByMe) {
              logger.debug('📞 ⚠️ 该联系人已被拉黑，无法发起语音通话');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('该联系人已被拉黑，无法发起通话'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      logger.debug('📞 检查好友关系时出错: $e');
    }

    if (!FeatureConfig.enableWebRTC) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('语音通话功能未启用')));
      }
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要麦克风权限才能进行语音通话')));
      }
      return;
    }

    // 🔴 修复：确保 AgoraService 已正确初始化
    if (agoraService != null) {
      if (agoraService!.myUserId == null || agoraService!.myUserId == 0) {
        logger.debug('📞 ⚠️ AgoraService 用户ID未初始化，尝试重新初始化...');
        if (currentUserId > 0) {
          await agoraService!.initialize(currentUserId);
          logger.debug(
            '📞 ✅ AgoraService 重新初始化完成，用户ID: ${agoraService!.myUserId}',
          );
        } else {
          logger.debug('📞 ❌ 当前用户ID无效: $currentUserId');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('无法初始化通话服务：用户ID无效')));
          }
          return;
        }
      }
    }

    if (mounted) {
      currentCallUserId = contact.userId;
      currentCallDisplayName = contact.displayName;
      currentCallType = CallType.voice;

      // 在进入通话页面前，尽量获取最新头像
      String? avatarForCall = contact.avatar;
      try {
        final token = await Storage.getToken();
        if (token != null && token.isNotEmpty) {
          final userInfo = await ApiService.getUserInfo(
            contact.userId,
            token: token,
          );
          if (userInfo['code'] == 0) {
            final data = userInfo['data'];
            final serverAvatar = data['avatar']?.toString();
            logger.debug('📞 [startVoiceCall] getUserInfo 返回头像: $serverAvatar');
            if (serverAvatar != null && serverAvatar.isNotEmpty) {
              avatarForCall = serverAvatar;
            }
          }
        }
      } catch (e) {
        logger.debug('📞 获取用户头像用于语音通话时出错: $e');
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCallPage(
            targetUserId: contact.userId,
            targetDisplayName: contact.displayName,
            targetAvatar: avatarForCall,
            isIncoming: false,
            callType: CallType.voice,
            currentUserId: currentUserId, // 🔴 修复：传递当前用户ID
          ),
        ),
      );

      if (result is Map && result['showFloatingButton'] == true) {
        setState(() {
          showCallFloatingButton = true;
          floatingButtonX = 0;
          floatingButtonY = 0;
        });
        logger.debug('📱 显示通话悬浮按钮');
      } else {
        setState(() {
          showCallFloatingButton = false;
        });
      }
    }
  }

  /// 发起视频通话
  Future<void> startVideoCall(RecentContactModel contact) async {
    logger.debug('📹 准备发起视频通话:');
    logger.debug('  - 联系人类型: ${contact.type}');
    logger.debug('  - 联系人userId: ${contact.userId}');
    logger.debug('  - 联系人显示名: ${contact.displayName}');
    logger.debug('  - 当前用户 ID: $currentUserId');

    if (contact.userId == currentUserId) {
      logger.debug('检测到联系人userId 等于当前用户 ID，阻止通话');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('不能给自己打电话')));
      }
      return;
    }

    // 🔴 检查好友关系（前端限制）
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final contactsResponse = await ApiService.getContacts(token: token);
        if (contactsResponse['code'] == 0) {
          final contactsData = contactsResponse['data']['contacts'] as List?;
          if (contactsData != null) {
            final contacts = contactsData.map((json) => ContactModel.fromJson(json)).toList();
            final contactModel = contacts.firstWhere(
              (c) => c.friendId == contact.userId,
              orElse: () => ContactModel(
                relationId: 0,
                userId: 0,
                friendId: contact.userId,
                username: contact.username,
                avatar: '',
                status: 'offline',
                createdAt: DateTime.now(),
                isDeleted: true, // 默认标记为已删除（找不到联系人）
              ),
            );

            // 检查是否被删除
            if (contactModel.isDeleted) {
              logger.debug('📹 ⚠️ 该联系人已被删除，无法发起视频通话');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('该联系人已被删除，无法发起通话'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            // 检查是否被拉黑
            if (contactModel.isBlocked || contactModel.isBlockedByMe) {
              logger.debug('📹 ⚠️ 该联系人已被拉黑，无法发起视频通话');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('该联系人已被拉黑，无法发起通话'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      logger.debug('📹 检查好友关系时出错: $e');
    }

    if (!FeatureConfig.enableWebRTC) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('视频通话功能未启用')));
      }
      return;
    }

    final micStatus = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();

    if (!micStatus.isGranted || !cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要麦克风和摄像头权限才能进行视频通话')));
      }
      return;
    }

    // 🔴 修复：确保 AgoraService 已正确初始化
    if (agoraService != null) {
      if (agoraService!.myUserId == null || agoraService!.myUserId == 0) {
        logger.debug('📹 ⚠️ AgoraService 用户ID未初始化，尝试重新初始化...');
        if (currentUserId > 0) {
          await agoraService!.initialize(currentUserId);
          logger.debug(
            '📹 ✅ AgoraService 重新初始化完成，用户ID: ${agoraService!.myUserId}',
          );
        } else {
          logger.debug('📹 ❌ 当前用户ID无效: $currentUserId');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('无法初始化通话服务：用户ID无效')));
          }
          return;
        }
      }
    }

    if (mounted) {
      currentCallUserId = contact.userId;
      currentCallDisplayName = contact.displayName;
      currentCallType = CallType.video;

      // 在进入通话页面前，尽量获取最新头像
      String? avatarForCall = contact.avatar;
      try {
        final token = await Storage.getToken();
        if (token != null && token.isNotEmpty) {
          final userInfo = await ApiService.getUserInfo(
            token: token,
            userId: contact.userId,
          );
          if (userInfo['code'] == 0) {
            final data = userInfo['data'];
            final serverAvatar = data['avatar']?.toString();
            if (serverAvatar != null && serverAvatar.isNotEmpty) {
              avatarForCall = serverAvatar;
            }
          }
        }
      } catch (e) {
        logger.debug('📹 获取用户头像用于视频通话时出错: $e');
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCallPage(
            targetUserId: contact.userId,
            targetDisplayName: contact.displayName,
            targetAvatar: avatarForCall,
            isIncoming: false,
            callType: CallType.video,
            currentUserId: currentUserId, // 🔴 修复：传递当前用户ID
          ),
        ),
      );

      if (result is Map && result['showFloatingButton'] == true) {
        setState(() {
          showCallFloatingButton = true;
          floatingButtonX = 0;
          floatingButtonY = 0;
        });
        logger.debug('📱 显示通话悬浮按钮');
      } else {
        setState(() {
          showCallFloatingButton = false;
        });
      }
    }
  }

  /// 构建通话悬浮按钮
  Widget buildCallFloatingButton() {
    if (floatingButtonX == 0 && floatingButtonY == 0) {
      final screenHeight = MediaQuery.of(context).size.height;
      floatingButtonX = 20;
      floatingButtonY = screenHeight / 3;
    }

    return Positioned(
      right: floatingButtonX,
      bottom: floatingButtonY,
      child: GestureDetector(
        onTap: () async {
          logger.debug('📱 点击悬浮按钮，重新打开通话页面');

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoiceCallPage(
                targetUserId: currentCallUserId,
                targetDisplayName: currentCallDisplayName,
                isIncoming: false,
                callType: currentCallType,
              ),
            ),
          );

          if (result is Map && result['showFloatingButton'] == true) {
            setState(() {
              showCallFloatingButton = true;
            });
          } else {
            setState(() {
              showCallFloatingButton = false;
            });
          }
        },
        onPanUpdate: (details) {
          setState(() {
            floatingButtonX -= details.delta.dx;
            floatingButtonY -= details.delta.dy;

            final screenSize = MediaQuery.of(context).size;
            const buttonSize = 60.0;

            if (floatingButtonX < 0) floatingButtonX = 0;
            if (floatingButtonX > screenSize.width - buttonSize) {
              floatingButtonX = screenSize.width - buttonSize;
            }

            if (floatingButtonY < 0) floatingButtonY = 0;
            if (floatingButtonY > screenSize.height - buttonSize) {
              floatingButtonY = screenSize.height - buttonSize;
            }
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            currentCallType == CallType.voice
                ? Icons.phone_in_talk
                : Icons.videocam,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// 发送通话拒绝消息（Mixin内部使用）
  Future<void> _sendCallRejectedMessageInMixin(
    int targetUserId,
    CallType callType, {
    bool isRejecter = true,
  }) async {
    try {
      // 发送给对方的消息内容
      final contentToSend = isRejecter ? '对方已拒绝' : '已拒绝';

      // 根据通话类型确定消息类型
      final messageType = (callType == CallType.video)
          ? 'call_rejected_video'
          : 'call_rejected';

      logger.debug('📞 [Mixin] 发送通话拒绝消息:');
      logger.debug('  - 目标用户ID: $targetUserId');
      logger.debug('  - 消息内容: $contentToSend');
      logger.debug('  - 通话类型: ${callType == CallType.video ? "视频" : "语音"}');
      logger.debug('  - 消息类型: $messageType');

      // 发送消息
      await _wsService.sendMessage(
        receiverId: targetUserId,
        content: contentToSend,
        messageType: messageType,
      );

      logger.debug('✅ [Mixin] 通话拒绝消息已发送');
    } catch (e) {
      logger.debug('⚠️ [Mixin] 发送通话拒绝消息异常: $e');
    }
  }

  /// 发送通话取消消息（Mixin内部使用）
  Future<void> _sendCallCancelledMessageInMixin(
    int targetUserId,
    CallType callType, {
    bool isCaller = true,
  }) async {
    try {
      // 发送给对方的消息内容
      final contentToSend = isCaller ? '对方已取消' : '已取消';

      // 根据通话类型确定消息类型
      final messageType = (callType == CallType.video)
          ? 'call_cancelled_video'
          : 'call_cancelled';

      logger.debug('📞 [Mixin] 发送通话取消消息:');
      logger.debug('  - 目标用户ID: $targetUserId');
      logger.debug('  - 消息内容: $contentToSend');
      logger.debug('  - 通话类型: ${callType == CallType.video ? "视频" : "语音"}');
      logger.debug('  - 消息类型: $messageType');

      // 发送消息
      await _wsService.sendMessage(
        receiverId: targetUserId,
        content: contentToSend,
        messageType: messageType,
      );

      logger.debug('✅ [Mixin] 通话取消消息已发送');
    } catch (e) {
      logger.debug('⚠️ [Mixin] 发送通话取消消息异常: $e');
    }
  }
}
