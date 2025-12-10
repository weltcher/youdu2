import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';

/// 群组管理功能 Mixin
mixin GroupManagerMixin<T extends StatefulWidget> on State<T> {
  // 群组相关状态
  List<GroupModel> get groups;
  set groups(List<GroupModel> value);

  bool get isLoadingGroups;
  set isLoadingGroups(bool value);

  String? get groupsError;
  set groupsError(String? value);

  GroupModel? get selectedGroup;
  set selectedGroup(GroupModel? value);

  String? get token;

  /// 加载群组列表
  Future<void> loadGroups() async {
    setState(() {
      isLoadingGroups = true;
      groupsError = null;
    });

    try {
      if (token == null || token!.isEmpty) {
        setState(() {
          isLoadingGroups = false;
          groupsError = '未登录';
        });
        return;
      }

      final response = await ApiService.getGroups(token: token!);

      if (response['code'] == 0 && response['data'] != null) {
        final groupsData = response['data']['groups'] as List?;
        final groupsList = (groupsData ?? [])
            .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          groups = groupsList;
          isLoadingGroups = false;
        });

        logger.debug('加载群组成功，共 ${groupsList.length} 个群组');
      } else {
        setState(() {
          isLoadingGroups = false;
          groupsError = response['message'] ?? '加载失败';
        });
      }
    } catch (e) {
      logger.debug('加载群组失败: $e');
      setState(() {
        isLoadingGroups = false;
        groupsError = e.toString();
      });
    }
  }

  /// 创建群组
  Future<void> createGroup({
    required String name,
    required String description,
    required List<int> memberIds,
  }) async {
    try {
      if (token == null || token!.isEmpty) {
        throw Exception('未登录');
      }

      final response = await ApiService.createGroup(
        token: token!,
        name: name,
        description: description,
        memberIds: memberIds,
      );

      if (response['code'] == 0) {
        logger.debug('创建群组成功');
        // 重新加载群组列表
        await loadGroups();
      } else {
        throw Exception(response['message'] ?? '创建群组失败');
      }
    } catch (e) {
      logger.debug('创建群组失败: $e');
      rethrow;
    }
  }

  /// 加入群组
  Future<void> joinGroup(String groupId) async {
    try {
      if (token == null || token!.isEmpty) {
        throw Exception('未登录');
      }

      final response = await ApiService.joinGroup(
        token: token!,
        groupId: groupId,
      );

      if (response['code'] == 0) {
        logger.debug('加入群组成功');
        await loadGroups();
      } else {
        throw Exception(response['message'] ?? '加入群组失败');
      }
    } catch (e) {
      logger.debug('加入群组失败: $e');
      rethrow;
    }
  }

  /// 退出群组
  Future<void> leaveGroup(int groupId) async {
    try {
      if (token == null || token!.isEmpty) {
        throw Exception('未登录');
      }

      final response = await ApiService.leaveGroup(
        token: token!,
        groupId: groupId,
      );

      if (response['code'] == 0) {
        logger.debug('退出群组成功');
        await loadGroups();
      } else {
        throw Exception(response['message'] ?? '退出群组失败');
      }
    } catch (e) {
      logger.debug('退出群组失败: $e');
      rethrow;
    }
  }

  /// 获取群组详情
  Future<GroupModel?> getGroupDetail(int groupId) async {
    try {
      if (token == null || token!.isEmpty) {
        return null;
      }

      final response = await ApiService.getGroupDetail(
        token: token!,
        groupId: groupId,
      );

      if (response['code'] == 0 && response['data'] != null) {
        return GroupModel.fromJson(response['data']['group']);
      }
      return null;
    } catch (e) {
      logger.debug('获取群组详情失败: $e');
      return null;
    }
  }
}
