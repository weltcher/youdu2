import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/contact_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import '../utils/logger.dart';

// ========== 全局变量：用于在页面被销毁后恢复数据 ==========
// 头像相关
File? _cgdGlobalSelectedAvatar;
String? _cgdGlobalAvatarUrl;
bool _cgdGlobalNeedReopenPage = false;
bool _cgdGlobalFilePickerReturned = false;

// 表单数据
String? _cgdGlobalGroupName;
String? _cgdGlobalAnnouncement;
String? _cgdGlobalNickname;
bool? _cgdGlobalDoNotDisturb;
Set<int>? _cgdGlobalSelectedContactIds;

// 公共函数：检查是否需要重新打开页面
bool cgdNeedReopenCreateGroupPage() {
  logger.debug('🔍 [CGD检查] cgdNeedReopenCreateGroupPage() 被调用');
  logger.debug('🔍 [CGD检查] _cgdGlobalNeedReopenPage = $_cgdGlobalNeedReopenPage');
  return _cgdGlobalNeedReopenPage;
}

// 公共函数：清除重新打开页面的标记
void cgdClearReopenCreateGroupPageFlag() {
  logger.debug('🧹 [CGD清除] cgdClearReopenCreateGroupPageFlag() 被调用');
  _cgdGlobalNeedReopenPage = false;
}

// 公共函数：设置选中的头像文件
void cgdSetGlobalSelectedAvatar(File? file, String? url) {
  logger.debug('💾 [CGD设置] cgdSetGlobalSelectedAvatar() file=${file?.path}, url=$url');
  _cgdGlobalSelectedAvatar = file;
  _cgdGlobalAvatarUrl = url;
}

// 公共函数：检查FilePicker是否已返回
bool cgdFilePickerReturned() {
  return _cgdGlobalFilePickerReturned;
}

// 公共函数：重置FilePicker返回标记
void cgdResetFilePickerFlag() {
  _cgdGlobalFilePickerReturned = false;
  logger.debug('🧹 [CGD重置] _cgdGlobalFilePickerReturned = false');
}

// 公共函数：清空所有全局表单数据
void cgdClearGlobalFormData() {
  _cgdGlobalSelectedAvatar = null;
  _cgdGlobalAvatarUrl = null;
  _cgdGlobalGroupName = null;
  _cgdGlobalAnnouncement = null;
  _cgdGlobalNickname = null;
  _cgdGlobalDoNotDisturb = null;
  _cgdGlobalSelectedContactIds = null;
  _cgdGlobalNeedReopenPage = false;
  logger.debug('🧹 [CGD清空] 已清空所有全局表单数据');
}

/// 创建群组/群组设置页面（桌面端）
/// 使用全屏页面替代Dialog，参考 desktop_create_group_page.dart 的样式布局
class CreateGroupDialog extends StatefulWidget {
  final List<ContactModel> contacts;
  final Function(GroupModel) onCreateGroup;
  final Function(int groupId, String? remark)? onGroupUpdated;
  final int currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final int? currentChatUserId;
  final Map<String, dynamic>? existingGroupData;
  final List<int> existingMemberIds;
  final List<Map<String, dynamic>>? existingMembersData;

  const CreateGroupDialog({
    super.key,
    required this.contacts,
    required this.onCreateGroup,
    this.onGroupUpdated,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar = '',
    this.currentChatUserId,
    this.existingGroupData,
    this.existingMemberIds = const [],
    this.existingMembersData,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  // 选中的联系人ID集合
  final Set<int> _selectedContactIds = {};

  // 群组信息表单控制器
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // 是否正在创建群组
  bool _isCreating = false;

  // 当前用户是否是群主
  bool _isOwner = false;

  // 当前用户是否是管理员
  bool _isAdmin = false;

  // 群组成员数据
  List<Map<String, dynamic>>? _membersData;

  // 消息免打扰状态
  bool _doNotDisturb = false;

  // 群组头像
  File? _selectedAvatar;
  String? _currentAvatarUrl;
  bool _isUploadingAvatar = false;

  // 搜索文本
  String _searchText = '';

  // 本地联系人列表
  List<ContactModel> _localContacts = [];

  // 是否是编辑模式
  bool get _isEditMode => widget.existingGroupData != null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    logger.debug('');
    logger.debug('========== [CGD初始化创建群组页面] ==========');
    logger.debug('📋 currentChatUserId: ${widget.currentChatUserId}');
    logger.debug('📋 contacts数量: ${widget.contacts.length}');
    logger.debug('📋 已存在群组: $_isEditMode');

    _localContacts = List.from(widget.contacts);

    // 🔴 从全局变量恢复头像和表单数据（处理FilePicker导致页面销毁的情况）
    logger.debug('🔍 检查是否需要从全局变量恢复数据...');
    logger.debug('🔍 _cgdGlobalSelectedAvatar: ${_cgdGlobalSelectedAvatar?.path}');
    logger.debug('🔍 _cgdGlobalGroupName: $_cgdGlobalGroupName');
    
    if (_cgdGlobalSelectedAvatar != null || _cgdGlobalGroupName != null) {
      logger.debug('✅ 从全局变量恢复数据');
      
      // 恢复头像
      bool needUploadAvatar = false;
      if (_cgdGlobalSelectedAvatar != null) {
        logger.debug('✅ 恢复头像文件: ${_cgdGlobalSelectedAvatar!.path}');
        _selectedAvatar = _cgdGlobalSelectedAvatar;
        _currentAvatarUrl = _cgdGlobalAvatarUrl;
        if (_isEditMode) {
          needUploadAvatar = true;
          logger.debug('📤 检测到编辑模式，需要上传头像');
        }
      }
      
      // 恢复表单数据
      if (_cgdGlobalGroupName != null) {
        logger.debug('✅ 恢复群名: $_cgdGlobalGroupName');
        _groupNameController.value = TextEditingValue(
          text: _cgdGlobalGroupName!,
          selection: TextSelection.collapsed(offset: _cgdGlobalGroupName!.length),
        );
      }
      if (_cgdGlobalAnnouncement != null) {
        logger.debug('✅ 恢复公告: $_cgdGlobalAnnouncement');
        _announcementController.value = TextEditingValue(
          text: _cgdGlobalAnnouncement!,
          selection: TextSelection.collapsed(offset: _cgdGlobalAnnouncement!.length),
        );
      }
      if (_cgdGlobalNickname != null) {
        logger.debug('✅ 恢复昵称: $_cgdGlobalNickname');
        _nicknameController.value = TextEditingValue(
          text: _cgdGlobalNickname!,
          selection: TextSelection.collapsed(offset: _cgdGlobalNickname!.length),
        );
      }
      if (_cgdGlobalDoNotDisturb != null) {
        logger.debug('✅ 恢复免打扰: $_cgdGlobalDoNotDisturb');
        _doNotDisturb = _cgdGlobalDoNotDisturb!;
      }
      if (_cgdGlobalSelectedContactIds != null) {
        logger.debug('✅ 恢复已选成员: ${_cgdGlobalSelectedContactIds!.length}人');
        _selectedContactIds.clear();
        _selectedContactIds.addAll(_cgdGlobalSelectedContactIds!);
      }
      
      // 清除全局变量
      _cgdGlobalSelectedAvatar = null;
      _cgdGlobalAvatarUrl = null;
      _cgdGlobalNeedReopenPage = false;
      _cgdGlobalGroupName = null;
      _cgdGlobalAnnouncement = null;
      _cgdGlobalNickname = null;
      _cgdGlobalDoNotDisturb = null;
      _cgdGlobalSelectedContactIds = null;
      logger.debug('✅ 数据恢复完成，已清除全局变量');
      
      // 如果需要上传头像，在页面构建完成后上传
      if (needUploadAvatar) {
        logger.debug('📤 准备在页面构建完成后上传头像...');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && _selectedAvatar != null) {
            logger.debug('📤 开始上传恢复的头像（编辑模式）...');
            await _uploadGroupAvatar();
          }
        });
      }
      
      // 🔴 重要：如果已经从全局变量恢复了数据，不要再执行下面的初始化逻辑
      // 但需要设置 _isOwner 和 _isAdmin
      if (_isEditMode) {
        final ownerId = widget.existingGroupData!['owner_id'] as int?;
        _isOwner = (ownerId == widget.currentUserId);
        if (widget.existingMembersData != null) {
          _membersData = List.from(widget.existingMembersData!);
          try {
            final currentUserMember = widget.existingMembersData!.firstWhere(
              (member) => member['user_id'] == widget.currentUserId,
            );
            final role = currentUserMember['role'] as String? ?? 'member';
            _isAdmin = (role == 'admin');
          } catch (e) {
            logger.debug('未找到当前用户的群组成员信息: $e');
          }
        }
      } else {
        _isOwner = true;
      }
      return; // 已恢复数据，直接返回
    }
    
    logger.debug('ℹ️ 没有需要恢复的数据，执行正常初始化');

    if (_isEditMode) {
      final ownerId = widget.existingGroupData!['owner_id'] as int?;
      _isOwner = (ownerId == widget.currentUserId);

      _groupNameController.text = widget.existingGroupData!['name'] as String? ?? '';
      _announcementController.text = widget.existingGroupData!['announcement'] as String? ?? '';
      _currentAvatarUrl = widget.existingGroupData!['avatar'] as String?;
      _selectedContactIds.addAll(widget.existingMemberIds);

      if (widget.existingMembersData != null) {
        _membersData = List.from(widget.existingMembersData!);
        try {
          final currentUserMember = widget.existingMembersData!.firstWhere(
            (member) => member['user_id'] == widget.currentUserId,
          );
          _nicknameController.text = currentUserMember['nickname'] as String? ?? '';
          final role = currentUserMember['role'] as String? ?? 'member';
          _isAdmin = (role == 'admin');
          _doNotDisturb = currentUserMember['do_not_disturb'] as bool? ?? false;
        } catch (e) {
          logger.debug('未找到当前用户的群组成员信息: $e');
        }
      }
    } else {
      _isOwner = true;
      if (widget.currentChatUserId != null && widget.currentChatUserId != widget.currentUserId) {
        _selectedContactIds.add(widget.currentChatUserId!);
        try {
          final currentChatContact = widget.contacts.firstWhere(
            (contact) => contact.friendId == widget.currentChatUserId,
          );
          _groupNameController.text = '${widget.currentUserName}${currentChatContact.displayName}...';
        } catch (e) {
          _groupNameController.text = '${widget.currentUserName}的群组';
        }
      }
    }
  }

  @override
  void dispose() {
    logger.debug('🗑️ CreateGroupDialog dispose - 页面被销毁');
    logger.debug('🗑️ 当前_cgdGlobalNeedReopenPage: $_cgdGlobalNeedReopenPage');
    _groupNameController.dispose();
    _announcementController.dispose();
    _nicknameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 选择群组头像 - 使用关闭页面方式，让 home_page 处理文件选择
  Future<void> _pickGroupAvatar() async {
    logger.debug('');
    logger.debug('========== [CGD选择群组头像] ==========');
    logger.debug('📸 开始选择头像');
    logger.debug('📸 当前mounted状态: $mounted');
    logger.debug('📸 是否编辑模式: $_isEditMode');
    
    // 🔴 保存当前表单数据到全局变量（以防页面被销毁）
    logger.debug('💾 保存表单数据到全局变量...');
    _cgdGlobalGroupName = _groupNameController.text;
    _cgdGlobalAnnouncement = _announcementController.text;
    _cgdGlobalNickname = _nicknameController.text;
    _cgdGlobalDoNotDisturb = _doNotDisturb;
    _cgdGlobalSelectedContactIds = Set.from(_selectedContactIds);
    logger.debug('💾 已保存: 群名=$_cgdGlobalGroupName, 已选成员=${_cgdGlobalSelectedContactIds?.length}');
    
    // 🔴 关闭当前页面，返回特殊标记，让 home_page 处理文件选择
    logger.debug('📸 关闭页面并返回 pick_avatar 标记');
    Navigator.of(context).pop('pick_avatar');
  }

  // 上传群组头像
  Future<String?> _uploadGroupAvatar() async {
    if (_selectedAvatar == null) return null;

    setState(() => _isUploadingAvatar = true);

    try {
      final token = await Storage.getToken();
      if (token == null) throw Exception('未登录');

      final response = await ApiService.uploadAvatar(
        token: token,
        filePath: _selectedAvatar!.path,
      );

      if (response['code'] == 0) {
        final avatarUrl = response['data']['url'] as String;
        
        if (_isEditMode) {
          final groupId = widget.existingGroupData!['id'] as int;
          final updateResponse = await ApiService.updateGroup(
            token: token,
            groupId: groupId,
            avatar: avatarUrl,
          );
          
          if (updateResponse['code'] == 0) {
            setState(() => _currentAvatarUrl = avatarUrl);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('头像更新成功')),
              );
            }
          }
        }
        
        return avatarUrl;
      } else {
        throw Exception(response['message'] ?? '上传失败');
      }
    } catch (e) {
      logger.error('上传群组头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传头像失败: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // 处理创建/保存群组
  Future<void> _handleSave() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入群组名称'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final token = await Storage.getToken();
      if (token == null) throw Exception('未登录');

      if (_isEditMode) {
        await _handleUpdateGroup(token);
      } else {
        await _handleCreateGroup(token);
      }
    } catch (e) {
      logger.error('保存群组失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleCreateGroup(String token) async {
    String? avatarUrl = _currentAvatarUrl;
    if (_selectedAvatar != null) {
      avatarUrl = await _uploadGroupAvatar();
    }

    final response = await ApiService.createGroup(
      token: token,
      name: _groupNameController.text.trim(),
      announcement: _announcementController.text.trim().isEmpty ? null : _announcementController.text.trim(),
      avatar: avatarUrl,
      nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      memberIds: _selectedContactIds.toList(),
      doNotDisturb: _doNotDisturb,
    );

    if (response['code'] == 0) {
      final groupData = response['data']['group'];
      final group = GroupModel.fromJson(groupData);
      widget.onCreateGroup(group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群组创建成功')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      throw Exception(response['message'] ?? '创建失败');
    }
  }

  Future<void> _handleUpdateGroup(String token) async {
    final groupId = widget.existingGroupData!['id'] as int;
    final canEditGroupInfo = _isOwner || _isAdmin;

    final originalMemberIds = widget.existingMemberIds.toSet();
    final currentMemberIds = _selectedContactIds.toSet();
    final addMembers = currentMemberIds.difference(originalMemberIds).toList();
    final removeMembers = originalMemberIds
        .difference(currentMemberIds)
        .where((id) => id != widget.currentUserId)
        .toList();

    final response = await ApiService.updateGroup(
      token: token,
      groupId: groupId,
      name: canEditGroupInfo ? _groupNameController.text.trim() : null,
      announcement: canEditGroupInfo && _announcementController.text.trim().isNotEmpty
          ? _announcementController.text.trim()
          : null,
      nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      doNotDisturb: _doNotDisturb,
      addMembers: addMembers.isNotEmpty ? addMembers : null,
      removeMembers: ((_isOwner || _isAdmin) && removeMembers.isNotEmpty) ? removeMembers : null,
    );

    if (response['code'] == 0) {
      final inviteConfirmation = widget.existingGroupData?['invite_confirmation'] as bool? ?? false;
      final needsApproval = inviteConfirmation && !_isOwner && !_isAdmin && addMembers.isNotEmpty;

      widget.onGroupUpdated?.call(groupId, null);
      if (mounted) {
        if (needsApproval) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已添加成员，等待群主或群管理员审核'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
        }
        Navigator.of(context).pop(true);
      }
    } else {
      throw Exception(response['message'] ?? '保存失败');
    }
  }

  // 更新消息免打扰状态
  Future<void> _updateDoNotDisturb(bool value) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.updateGroup(
        token: token,
        groupId: groupId,
        doNotDisturb: value,
      );

      if (response['code'] == 0) {
        setState(() => _doNotDisturb = value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(value ? '已开启消息免打扰' : '已关闭消息免打扰')),
          );
          widget.onGroupUpdated?.call(groupId, null);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '更新失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('更新消息免打扰状态失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  // 退出群聊
  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出该群聊吗？退出后将不再接收该群聊的消息。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.leaveGroup(token: token, groupId: groupId);

      if (response['code'] == 0) {
        widget.onGroupUpdated?.call(groupId, 'GROUP_LEFT');
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(const SnackBar(content: Text('已退出群聊')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '退出失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('退出群组失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('退出失败: $e')));
      }
    }
  }

  // 解散群组
  Future<void> _handleDisbandGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认解散'),
        content: const Text('确定要解散该群聊吗？解散后该群聊将不再显示，但数据仍会保留。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('确定解散'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.deleteGroup(token: token, groupId: groupId);

      if (response['code'] == 0) {
        final userId = await Storage.getUserId();
        if (userId != null) {
          final contactKey = Storage.generateContactKey(isGroup: true, id: groupId);
          await Storage.addDeletedChat(userId, contactKey);
        }

        widget.onGroupUpdated?.call(groupId, 'GROUP_DISBANDED');
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(const SnackBar(content: Text('该群聊已解散')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '解散失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('解散群组失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解散失败: $e')));
      }
    }
  }

  // 切换禁言状态
  Future<void> _toggleMuteStatus(int userId, bool currentlyMuted) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = currentlyMuted
          ? await ApiService.unmuteGroupMember(token: token, groupId: groupId, userId: userId)
          : await ApiService.muteGroupMember(token: token, groupId: groupId, userId: userId);

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(currentlyMuted ? '已解除禁言' : '已禁言')),
          );
        }

        final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
        if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
          final membersData = detailResponse['data']['members'] as List?;
          if (membersData != null && mounted) {
            setState(() {
              _membersData = List<Map<String, dynamic>>.from(
                membersData.map((m) => m as Map<String, dynamic>),
              );
            });
            widget.onGroupUpdated?.call(groupId, null);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '操作失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('切换禁言状态失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  // 移除群成员
  Future<void> _removeMember(int userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 $displayName 移除出群吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.updateGroup(
        token: token,
        groupId: groupId,
        removeMembers: [userId],
      );

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已移除成员')));
        }

        final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
        if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
          final membersData = detailResponse['data']['members'] as List?;
          if (membersData != null && mounted) {
            setState(() {
              _membersData = List<Map<String, dynamic>>.from(
                membersData.map((m) => m as Map<String, dynamic>),
              );
              if (_selectedContactIds.contains(userId)) {
                _selectedContactIds.remove(userId);
              }
            });
            widget.onGroupUpdated?.call(groupId, null);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '移除失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('移除群成员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移除失败: $e')));
      }
    }
  }

  // 通过群成员审核
  Future<void> _approveMember(int userId, String displayName) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.approveGroupMember(token: token, groupId: groupId, userId: userId);

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已通过审核')));
        }

        final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
        if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
          final membersData = detailResponse['data']['members'] as List?;
          if (membersData != null && mounted) {
            setState(() {
              _membersData = List<Map<String, dynamic>>.from(
                membersData.map((m) => m as Map<String, dynamic>),
              );
            });
            widget.onGroupUpdated?.call(groupId, null);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '审核失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('通过审核失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('审核失败: $e')));
      }
    }
  }

  // 拒绝群成员审核
  Future<void> _rejectMember(int userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认拒绝'),
        content: Text('确定要拒绝 $displayName 加入群组吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      final response = await ApiService.rejectGroupMember(token: token, groupId: groupId, userId: userId);

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝申请')));
        }

        final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
        if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
          final membersData = detailResponse['data']['members'] as List?;
          if (membersData != null && mounted) {
            setState(() {
              _membersData = List<Map<String, dynamic>>.from(
                membersData.map((m) => m as Map<String, dynamic>),
              );
            });
            widget.onGroupUpdated?.call(groupId, null);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '拒绝失败')),
          );
        }
      }
    } catch (e) {
      logger.debug('拒绝审核失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('拒绝失败: $e')));
      }
    }
  }

  // 获取头像文本
  String _getAvatarText(String name) {
    if (name.length >= 2) {
      return name.substring(name.length - 2);
    }
    return name;
  }

  // 显示群管理对话框
  void _showGroupManagement() {
    if (!_isEditMode || !_isOwner) return;

    bool allMuted = widget.existingGroupData!['all_muted'] as bool? ?? false;
    bool inviteConfirmation = widget.existingGroupData!['invite_confirmation'] as bool? ?? false;
    bool memberViewPermission = widget.existingGroupData!['member_view_permission'] as bool? ?? true;
    final groupId = widget.existingGroupData!['id'] as int;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('群管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: Container(
              width: 400,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 全体禁言
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.volume_off, color: Color(0xFFFF9800), size: 24),
                      ),
                      title: const Text('全体禁言', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: const Text('开启后普通成员无法发送消息', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      trailing: Switch(
                        value: allMuted,
                        onChanged: (value) async {
                          try {
                            final token = await Storage.getToken();
                            if (token == null) return;
                            final response = await ApiService.updateGroupAllMuted(token: token, groupId: groupId, allMuted: value);
                            if (response['code'] == 0) {
                              setDialogState(() => allMuted = value);
                              widget.existingGroupData!['all_muted'] = value;
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '设置成功')));
                              
                              // 🔴 重新获取群组详情，更新成员禁言状态
                              final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
                              if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
                                final membersData = detailResponse['data']['members'] as List?;
                                if (membersData != null && mounted) {
                                  setState(() {
                                    _membersData = List<Map<String, dynamic>>.from(
                                      membersData.map((m) => m as Map<String, dynamic>),
                                    );
                                  });
                                }
                              }
                            }
                          } catch (e) {
                            logger.error('更新全体禁言状态失败: $e');
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // 群聊邀请确认
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.person_add, color: Color(0xFFFF9800), size: 24),
                      ),
                      title: const Text('群聊邀请确认', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: const Text('开启后普通成员添加好友需群主或管理员审核', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      trailing: Switch(
                        value: inviteConfirmation,
                        onChanged: (value) async {
                          try {
                            final token = await Storage.getToken();
                            if (token == null) return;
                            final response = await ApiService.updateGroupInviteConfirmation(token: token, groupId: groupId, inviteConfirmation: value);
                            if (response['code'] == 0) {
                              setDialogState(() => inviteConfirmation = value);
                              widget.existingGroupData!['invite_confirmation'] = value;
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '设置成功')));
                            }
                          } catch (e) {
                            logger.error('更新邀请确认状态失败: $e');
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // 群成员权限
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.visibility, color: Color(0xFF2196F3), size: 24),
                      ),
                      title: const Text('群成员权限', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: const Text('开启后普通成员可以查看其他成员信息', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      trailing: Switch(
                        value: memberViewPermission,
                        onChanged: (value) async {
                          try {
                            final token = await Storage.getToken();
                            if (token == null) return;
                            final response = await ApiService.updateGroupMemberViewPermission(token: token, groupId: groupId, memberViewPermission: value);
                            if (response['code'] == 0) {
                              setDialogState(() => memberViewPermission = value);
                              widget.existingGroupData!['member_view_permission'] = value;
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '设置成功')));
                            }
                          } catch (e) {
                            logger.error('更新群成员查看权限状态失败: $e');
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // 群主管理权限转让
                    if (_isOwner) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.admin_panel_settings, color: Color(0xFF4A90E2), size: 24),
                        ),
                        title: const Text('群主管理权限转让', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: const Text('将群主权限转让给其他成员', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
                        onTap: () {
                          Navigator.pop(context);
                          _showTransferOwnershipDialog();
                        },
                      ),
                      const Divider(height: 1),
                      // 群管理员设置
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFF4CAF50), size: 24),
                        ),
                        title: const Text('群管理员设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: const Text('设置群管理员（最多5个）', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
                        onTap: () {
                          Navigator.pop(context);
                          _showAdminSettingsDialog();
                        },
                      ),
                      const Divider(height: 1),
                      // 解散群聊
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 24),
                        ),
                        title: const Text('解散该群聊', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE53935))),
                        subtitle: const Text('解散后该群聊将不再显示', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
                        onTap: () async {
                          Navigator.pop(context);
                          await Future.delayed(const Duration(milliseconds: 100));
                          _handleDisbandGroup();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭', style: TextStyle(color: Color(0xFF666666)))),
            ],
          );
        },
      ),
    );
  }

  // 显示群管理员设置对话框
  void _showAdminSettingsDialog() {
    if (_membersData == null || _membersData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法获取群成员列表')));
      return;
    }

    final otherMembers = _membersData!.where((member) => member['user_id'] != widget.existingGroupData!['owner_id']).toList();
    if (otherMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('群组中没有其他成员可以设置为管理员')));
      return;
    }

    final currentAdmins = otherMembers
        .where((member) => (member['role'] as String? ?? 'member') == 'admin')
        .map((member) => member['user_id'] as int)
        .toSet();
    final selectedAdmins = Set<int>.from(currentAdmins);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Text('设置群管理员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${selectedAdmins.length}/5', style: TextStyle(fontSize: 14, color: selectedAdmins.length >= 5 ? const Color(0xFFE53935) : const Color(0xFF4A90E2))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('最多可设置5个管理员：', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: otherMembers.length,
                    itemBuilder: (context, index) {
                      final member = otherMembers[index];
                      final memberId = member['user_id'] as int;
                      final isSelected = selectedAdmins.contains(memberId);
                      final displayName = member['username'] as String? ?? member['full_name'] as String? ?? '未知用户';
                      final avatarText = _getAvatarText(displayName);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          if (value == true) {
                            if (selectedAdmins.length < 5) {
                              setState(() => selectedAdmins.add(memberId));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('最多只能设置5个管理员')));
                            }
                          } else {
                            setState(() => selectedAdmins.remove(memberId));
                          }
                        },
                        secondary: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFF4A90E2), borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text(avatarText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        title: Text(displayName, style: const TextStyle(fontSize: 14)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateGroupAdmins(selectedAdmins.toList());
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  // 更新群管理员
  Future<void> _updateGroupAdmins(List<int> adminIds) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      }

      final response = await ApiService.setGroupAdmins(token: token, groupId: groupId, adminIds: adminIds);
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        if (response['code'] == 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('群管理员设置成功'), backgroundColor: Colors.green));
          final detailResponse = await ApiService.getGroupDetail(token: token, groupId: groupId);
          if (detailResponse['code'] == 0 && detailResponse['data'] != null) {
            final membersData = detailResponse['data']['members'] as List?;
            if (membersData != null && mounted) {
              setState(() {
                _membersData = List<Map<String, dynamic>>.from(membersData.map((m) => m as Map<String, dynamic>));
                try {
                  final currentUserMember = _membersData!.firstWhere((member) => member['user_id'] == widget.currentUserId);
                  final role = currentUserMember['role'] as String? ?? 'member';
                  _isAdmin = (role == 'admin');
                } catch (e) {
                  _isAdmin = false;
                }
              });
              widget.onGroupUpdated?.call(groupId, null);
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '设置失败'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
      logger.debug('设置群管理员失败: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置失败: $e'), backgroundColor: Colors.red));
    }
  }

  // 显示转让群主权限的对话框
  void _showTransferOwnershipDialog() {
    if (_membersData == null || _membersData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法获取群成员列表')));
      return;
    }

    final otherMembers = _membersData!.where((member) => member['user_id'] != widget.currentUserId).toList();
    if (otherMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('群组中没有其他成员可以转让')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转让群主权限', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请选择新的群主：', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherMembers.length,
                  itemBuilder: (context, index) {
                    final member = otherMembers[index];
                    final memberId = member['user_id'] as int;
                    final displayName = member['username'] as String? ?? member['full_name'] as String? ?? '未知用户';
                    final avatarText = _getAvatarText(displayName);

                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFF4A90E2), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: Text(avatarText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      title: Text(displayName, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _confirmTransferOwnership(memberId, displayName);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        ],
      ),
    );
  }

  // 确认转让群主权限
  void _confirmTransferOwnership(int newOwnerId, String newOwnerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认转让'),
        content: Text('确定要将群主权限转让给 "$newOwnerName" 吗？\n\n转让后您将成为普通成员，此操作不可撤销。', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _transferOwnership(newOwnerId, newOwnerName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
            child: const Text('确认转让'),
          ),
        ],
      ),
    );
  }

  // 执行转让群主权限
  Future<void> _transferOwnership(int newOwnerId, String newOwnerName) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登录')));
        return;
      }

      final groupId = widget.existingGroupData!['id'] as int;
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      }

      final response = await ApiService.transferGroupOwnership(token: token, groupId: groupId, newOwnerId: newOwnerId);
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        if (response['code'] == 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已成功将群主权限转让给 $newOwnerName'), backgroundColor: Colors.green));
          setState(() {
            _isOwner = false;
            if (_membersData != null) {
              for (var member in _membersData!) {
                final memberId = member['user_id'] as int;
                if (memberId == widget.currentUserId) member['role'] = 'member';
                if (memberId == newOwnerId) member['role'] = 'owner';
              }
            }
          });
          widget.onGroupUpdated?.call(groupId, null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '转让失败'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('转让失败: $e'), backgroundColor: Colors.red));
    }
  }

  // 显示成员右键菜单
  void _showMemberContextMenu(int memberId, String displayName, Offset tapPosition) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    // 获取成员的禁言状态
    bool isMuted = false;
    if (_membersData != null) {
      try {
        final member = _membersData!.firstWhere((m) => m['user_id'] == memberId);
        isMuted = member['is_muted'] as bool? ?? false;
      } catch (_) {}
    }

    final menuWidth = 120.0;
    final menuHeight = 150.0;
    final overlayTopLeft = overlay.localToGlobal(Offset.zero);
    final relativeX = tapPosition.dx - overlayTopLeft.dx;
    final relativeY = tapPosition.dy - overlayTopLeft.dy;

    double left = relativeX;
    double top = relativeY;
    if (left + menuWidth > overlay.size.width) left = relativeX - menuWidth;
    if (top + menuHeight > overlay.size.height) top = relativeY - menuHeight;
    left = left.clamp(0.0, overlay.size.width - menuWidth);
    top = top.clamp(0.0, overlay.size.height - menuHeight);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, overlay.size.width - (left + menuWidth), overlay.size.height - (top + menuHeight)),
      items: [
        // 禁言/解除禁言
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                isMuted ? Icons.volume_up : Icons.volume_off,
                size: 18,
                color: isMuted ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              Text(isMuted ? '解除禁言' : '禁言'),
            ],
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              _toggleMuteStatus(memberId, isMuted);
            });
          },
        ),
        // 移除成员
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.person_remove, size: 18, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Text('移除'),
            ],
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              _removeMember(memberId, displayName);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditMode ? '群组设置' : '创建群组'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _handleSave,
            child: _isCreating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isEditMode ? '保存' : '创建', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(flex: 1, child: _buildContactList()),
          Expanded(flex: 1, child: _buildGroupInfo()),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    final availableContacts = _localContacts.where((contact) {
      if (contact.friendId == widget.currentUserId) return false;
      if (_selectedContactIds.contains(contact.friendId)) return false;
      if (_searchText.isNotEmpty) {
        final name = contact.displayName.toLowerCase();
        return name.contains(_searchText.toLowerCase());
      }
      return true;
    }).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索联系人',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF5F5F5),
            child: Row(
              children: [
                const Text('选择成员', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('已选${_selectedContactIds.length}人', style: const TextStyle(color: Color(0xFF4A90E2))),
              ],
            ),
          ),
          // 联系人列表
          Expanded(
            child: availableContacts.isEmpty
                ? const Center(child: Text('暂无可选联系人', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: availableContacts.length,
                    itemBuilder: (context, index) {
                      final contact = availableContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF4A90E2),
                          backgroundImage: contact.avatar.isNotEmpty ? NetworkImage(contact.avatar) : null,
                          child: contact.avatar.isEmpty ? Text(contact.avatarText, style: const TextStyle(color: Colors.white)) : null,
                        ),
                        title: Text(contact.displayName),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4A90E2)),
                          onPressed: () => _addMember(contact),
                        ),
                        onTap: () => _addMember(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addMember(ContactModel contact) {
    setState(() {
      _selectedContactIds.add(contact.friendId);
      if (_isEditMode && _membersData != null) {
        final alreadyExists = _membersData!.any((member) => member['user_id'] == contact.friendId);
        if (!alreadyExists) {
          _membersData!.add({
            'user_id': contact.friendId,
            'username': contact.username,
            'full_name': contact.fullName,
            'display_name': contact.displayName,
            'role': 'member',
            'is_muted': false,
            'approval_status': 'approved',
            'avatar': contact.avatar,
            'nickname': null,
          });
        }
      }
    });
  }

  Widget _buildGroupInfo() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(left: 1),
      child: Column(
        children: [
          _buildSelectedMembers(),
          const Divider(height: 1),
          Expanded(child: _buildGroupForm()),
        ],
      ),
    );
  }

  Widget _buildSelectedMembers() {
    List<Widget> memberWidgets = [];

    if (_isEditMode && _membersData != null) {
      final sortedMembers = List<Map<String, dynamic>>.from(_membersData!);
      sortedMembers.sort((a, b) {
        final aRole = a['role'] as String? ?? 'member';
        final bRole = b['role'] as String? ?? 'member';
        if (aRole == 'owner') return -1;
        if (bRole == 'owner') return 1;
        if (aRole == 'admin' && bRole != 'admin') return -1;
        if (bRole == 'admin' && aRole != 'admin') return 1;
        return 0;
      });

      for (var member in sortedMembers) {
        if ((member['approval_status'] as String? ?? 'approved') == 'pending') continue;
        final memberId = member['user_id'] as int;
        // 优先显示群昵称，其次是用户昵称，最后是用户名
        final nickname = member['nickname'] as String?;
        final fullName = member['full_name'] as String?;
        final username = member['username'] as String?;
        final displayName = (nickname != null && nickname.isNotEmpty)
            ? nickname
            : (fullName != null && fullName.isNotEmpty)
                ? fullName
                : (username ?? '未知');
        final avatarUrl = member['avatar'] as String?;
        final role = member['role'] as String? ?? 'member';

        final isMuted = member['is_muted'] as bool? ?? false;

        memberWidgets.add(_buildMemberChip(
          memberId: memberId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          isOwner: role == 'owner',
          isAdmin: role == 'admin',
          isMuted: isMuted,
          canRemove: false,
        ));
      }
    } else {
      memberWidgets.add(_buildMemberChip(
        memberId: widget.currentUserId,
        displayName: widget.currentUserName,
        avatarUrl: widget.currentUserAvatar,
        isOwner: true,
        canRemove: false,
      ));

      for (var contactId in _selectedContactIds) {
        try {
          final contact = _localContacts.firstWhere((c) => c.friendId == contactId);
          memberWidgets.add(_buildMemberChip(
            memberId: contact.friendId,
            displayName: contact.displayName,
            avatarUrl: contact.avatar,
            canRemove: true,
          ));
        } catch (_) {}
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('群组成员', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${memberWidgets.length}人', style: const TextStyle(color: Color(0xFF4A90E2))),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Wrap(spacing: 12, runSpacing: 12, children: memberWidgets),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip({
    required int memberId,
    required String displayName,
    String? avatarUrl,
    bool isOwner = false,
    bool isAdmin = false,
    bool isMuted = false,
    bool canRemove = false,
  }) {
    final isCurrentUser = memberId == widget.currentUserId;
    final showContextMenu = _isEditMode && !isOwner && !isAdmin && !isCurrentUser;

    return Column(
      children: [
        GestureDetector(
          onSecondaryTapDown: showContextMenu
              ? (TapDownDetails details) => _showMemberContextMenu(memberId, displayName, details.globalPosition)
              : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4A90E2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(displayName.isNotEmpty ? displayName.substring(displayName.length > 1 ? displayName.length - 2 : 0) : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14))
                    : null,
              ),
              if (canRemove)
                Positioned(
                  right: -4, top: -4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedContactIds.remove(memberId)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              if (isOwner)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                    child: const Text('群主', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
              if (isAdmin && !isOwner)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                    child: const Text('管理', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
              // 禁言图标 - 显示在右上角
              if (isMuted)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_off,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(displayName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildGroupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 群组头像
          _buildAvatarSection(),
          const SizedBox(height: 16),
          // 群组名称
          _buildTextField(
            label: '群聊名称',
            controller: _groupNameController,
            hintText: '请输入群组名称',
            required: true,
            enabled: !_isEditMode || _isOwner || _isAdmin,
          ),
          const SizedBox(height: 16),
          // 群公告
          _buildTextField(
            label: '群公告',
            controller: _announcementController,
            hintText: '请输入群公告',
            enabled: !_isEditMode || _isOwner || _isAdmin,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // 我的昵称
          _buildTextField(
            label: '我在群里的昵称',
            controller: _nicknameController,
            hintText: '请输入昵称',
          ),
          const SizedBox(height: 16),
          // 消息免打扰
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text('消息免打扰', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const Spacer(),
                Switch(
                  value: _doNotDisturb,
                  onChanged: _isEditMode
                      ? (value) async => await _updateDoNotDisturb(value)
                      : (value) => setState(() => _doNotDisturb = value),
                  activeColor: const Color(0xFF4A90E2),
                ),
              ],
            ),
          ),
          // 群管理按钮
          if (_isEditMode && _isOwner) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showGroupManagement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('群管理'),
              ),
            ),
          ],
          // 退出群聊按钮
          if (_isEditMode) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleLeaveGroup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('退出群聊'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final canEdit = !_isEditMode || _isOwner || _isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('群组头像', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            SizedBox(width: 8),
            Text('(可选)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: canEdit ? _pickGroupAvatar : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF4A90E2),
                  backgroundImage: _selectedAvatar != null
                      ? FileImage(_selectedAvatar!)
                      : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                          ? NetworkImage(_currentAvatarUrl!)
                          : null) as ImageProvider?,
                  child: (_selectedAvatar == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                      ? const Icon(Icons.group, size: 40, color: Colors.white)
                      : null,
                ),
                if (_isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                      child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                    ),
                  ),
                if (canEdit)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[100],
            isDense: true,
          ),
        ),
      ],
    );
  }
}
