import 'package:flutter/material.dart';
import '../../models/contact_model.dart';
import '../../models/recent_contact_model.dart';
import '../../services/api_service.dart';
import '../../services/message_service.dart';
import '../../utils/logger.dart';
import '../../utils/storage.dart';

/// 联系人管理功能 Mixin
mixin ContactManagerMixin<T extends StatefulWidget> on State<T> {
  // 联系人相关状态（需要在主 State 中定义或通过 getter 访问）
  List<ContactModel> get contacts;
  set contacts(List<ContactModel> value);

  bool get isLoadingContacts;
  set isLoadingContacts(bool value);

  String? get contactsError;
  set contactsError(String? value);

  List<RecentContactModel> get recentContacts;
  set recentContacts(List<RecentContactModel> value);

  bool get isLoadingRecentContacts;
  set isLoadingRecentContacts(bool value);

  String? get recentContactsError;
  set recentContactsError(String? value);

  String? get token;
  int? get currentChatUserId;
  int get selectedChatIndex;
  set selectedChatIndex(int value);

  int get selectedMenuIndex;

  /// 加载最近联系人列表
  Future<void> loadRecentContacts() async {
    logger.debug('🔄 开始加载最近联系人列表');
    setState(() {
      isLoadingRecentContacts = true;
      recentContactsError = null;
    });

    try {
      if (token == null || token!.isEmpty) {
        logger.debug('未登录，无法加载最近联系人');
        setState(() {
          isLoadingRecentContacts = false;
          recentContactsError = '未登录';
        });
        return;
      }

      logger.debug('📡 调用本地服务获取最近联系人列表...');
      final response = await MessageService().getRecentContacts();
      logger.debug('📥 本地服务响应: code=${response['code']}');

      if (response['code'] == 0 && response['data'] != null) {
        final contactsData = response['data']['contacts'] as List?;
        var contactsList = (contactsData ?? [])
            .map(
              (json) =>
                  RecentContactModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        logger.debug('加载最近联系人成功，共 ${contactsList.length} 个联系人');

        // 应用置顶和删除配置
        contactsList = await applyContactPreferences(contactsList);
        logger.debug('应用偏好设置后，剩余 ${contactsList.length} 个联系人');

        // 请求实时在线状态（会直接修改contactsList）
        await _fetchOnlineStatuses(contactsList);

        // 如果当前有选中的聊天，需要在新列表中找到该联系人的位置并更新索引
        if (currentChatUserId != null) {
          final currentContactIndex = contactsList.indexWhere(
            (contact) => contact.userId == currentChatUserId,
          );
          if (currentContactIndex != -1) {
            logger.debug(
              '🔄 更新选中索引: $selectedChatIndex -> $currentContactIndex',
            );
            setState(() {
              recentContacts = contactsList;
              selectedChatIndex = currentContactIndex;
              isLoadingRecentContacts = false;
            });
          } else {
            logger.debug('⚠️ 当前聊天联系人不在新列表中');
            setState(() {
              recentContacts = contactsList;
              isLoadingRecentContacts = false;
            });
          }
        } else {
          setState(() {
            recentContacts = contactsList;
            isLoadingRecentContacts = false;
          });
          
          logger.debug('✅ UI更新完成，联系人数量: ${recentContacts.length}');

          // 只在初次加载且没有当前聊天用户时，自动选择第一个联系人
          if (contactsList.isNotEmpty && selectedMenuIndex == 0) {
            final firstContact = contactsList[0];
            logger.debug(
              '🎯 自动选择第一个联系人: ${firstContact.displayName} (ID: ${firstContact.userId})',
            );
            setState(() {
              selectedChatIndex = 0;
            });
            // 需要在主文件中实现加载消息历史的逻辑
            onContactSelected(firstContact);
          }
        }
      } else {
        setState(() {
          isLoadingRecentContacts = false;
          recentContactsError = response['message'] ?? '加载失败';
        });
      }
    } catch (e) {
      logger.debug('加载最近联系人失败: $e');
      setState(() {
        isLoadingRecentContacts = false;
        recentContactsError = e.toString();
      });
    }
  }

  /// 加载联系人列表
  Future<void> loadContacts() async {
    setState(() {
      isLoadingContacts = true;
      contactsError = null;
    });

    try {
      if (token == null || token!.isEmpty) {
        setState(() {
          isLoadingContacts = false;
          contactsError = '未登录';
        });
        return;
      }

      final response = await ApiService.getContacts(token: token!);

      if (response['code'] == 0 && response['data'] != null) {
        final contactsData = response['data']['contacts'] as List?;
        final contactsList = (contactsData ?? [])
            .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
            .toList();

        logger.debug('成功加载联系人列表，共 ${contactsList.length} 个联系人');

        setState(() {
          contacts = contactsList;
          isLoadingContacts = false;
        });
      } else {
        setState(() {
          isLoadingContacts = false;
          contactsError = response['message'] ?? '加载失败';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingContacts = false;
        contactsError = e.toString();
      });
    }
  }

  /// 应用联系人偏好设置（置顶、删除等）
  Future<List<RecentContactModel>> applyContactPreferences(
    List<RecentContactModel> contactsList,
  ) async {
    try {
      // 获取置顶和删除的会话列表（使用当前登录用户）
      final pinnedChats = await Storage.getPinnedChatsForCurrentUser();
      final deletedChats = await Storage.getDeletedChatsForCurrentUser();

      logger.debug('📌 置顶的会话: $pinnedChats');
      logger.debug('🗑️ 删除的会话: $deletedChats');

      // 过滤掉被删除的会话
      var filteredContacts = contactsList.where((contact) {
        final contactKey = Storage.generateContactKey(
          isGroup: contact.isGroup,
          id: contact.isGroup
              ? (contact.groupId ?? contact.userId)
              : contact.userId,
        );
        return !deletedChats.contains(contactKey);
      }).toList();

      logger.debug('过滤删除后剩余: ${filteredContacts.length} 个联系人');

      // 分离置顶和非置顶的联系人
      final List<MapEntry<RecentContactModel, int>> pinnedList = [];
      final List<RecentContactModel> unpinnedList = [];

      for (var contact in filteredContacts) {
        final contactKey = Storage.generateContactKey(
          isGroup: contact.isGroup,
          id: contact.isGroup
              ? (contact.groupId ?? contact.userId)
              : contact.userId,
        );
        final pinnedTimestamp = pinnedChats[contactKey];
        if (pinnedTimestamp != null) {
          pinnedList.add(MapEntry(contact, pinnedTimestamp));
        } else {
          unpinnedList.add(contact);
        }
      }

      // 对置顶列表按置顶时间倒序排序（最新置顶的在最前面）
      pinnedList.sort((a, b) => b.value.compareTo(a.value));

      logger.debug('📌 置顶联系人数量: ${pinnedList.length}');
      logger.debug('📋 普通联系人数量: ${unpinnedList.length}');

      // 合并列表：置顶的在前面
      final result = <RecentContactModel>[];
      result.addAll(pinnedList.map((e) => e.key));
      result.addAll(unpinnedList);
      return result;
    } catch (e) {
      logger.debug('应用联系人偏好设置失败: $e');
      return contactsList;
    }
  }

  /// 批量获取联系人的实时在线状态
  Future<void> _fetchOnlineStatuses(List<RecentContactModel> contactsList) async {
    try {
      if (contactsList.isEmpty || token == null || token!.isEmpty) {
        logger.debug('📊 跳过在线状态查询 - 列表为空或未登录');
        return;
      }

      // 只查询用户类型的联系人（排除群组和文件助手）
      final userIds = contactsList
          .where((contact) => contact.type == 'user')
          .map((contact) => contact.userId)
          .toList();

      if (userIds.isEmpty) {
        logger.debug('📊 没有需要查询在线状态的用户联系人');
        return;
      }

      final response = await ApiService.batchGetOnlineStatus(
        token: token!,
        userIds: userIds,
      );

      logger.debug('📊 API响应: code=${response['code']}, message=${response['message']}');

      if (response['code'] == 0 && response['data'] != null) {
        final statusesData = response['data']['statuses'] as Map<String, dynamic>?;
        if (statusesData != null) {
          logger.debug('✅ 在线状态查询成功，收到 ${statusesData.length} 个用户的状态');
          logger.debug('📊 返回的状态数据: $statusesData');

          // 更新联系人的在线状态（不在这里调用setState，返回更新后的列表）
          int updatedCount = 0;
          for (int i = 0; i < contactsList.length; i++) {
            final contact = contactsList[i];
            if (contact.type == 'user') {
              // 尝试两种键格式：字符串和整数
              final userIdStr = contact.userId.toString();
              dynamic newStatus = statusesData[userIdStr];
              
              // 如果字符串键没找到，尝试整数键
              if (newStatus == null) {
                newStatus = statusesData[contact.userId];
              }
              
              logger.debug('📊 用户 ${contact.userId}: 当前状态=${contact.status}, 新状态=$newStatus');
              
              if (newStatus != null && newStatus != contact.status) {
                contactsList[i] = contact.copyWith(status: newStatus as String);
                updatedCount++;
                logger.debug(
                  '🔄 更新用户 ${contact.userId} 状态: ${contact.status} -> $newStatus',
                );
              }
            }
          }
          
          logger.debug('✅ 完成在线状态更新，共更新 $updatedCount 个用户');
        } else {
          logger.debug('⚠️ 状态数据为空');
        }
      } else {
        logger.debug('⚠️ 查询在线状态失败: ${response['message']}');
      }
    } catch (e, stackTrace) {
      logger.debug('❌ 批量查询在线状态异常: $e');
      logger.debug('❌ 堆栈跟踪: $stackTrace');
    }
  }

  /// 搜索联系人
  Future<void> searchContacts(String keyword) async {
    // 需要在主文件中实现
  }

  /// 联系人被选中时的回调（需要在主文件中实现）
  void onContactSelected(RecentContactModel contact);
}
