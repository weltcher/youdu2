import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/contact_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../utils/storage.dart';
import '../utils/logger.dart';
import 'group_qr_code_page.dart';

/// 移动端创建群组页面
class MobileCreateGroupPage extends StatefulWidget {
  final List<ContactModel>? contacts; // 可选的联系人列表
  final Function(GroupModel)? onCreateGroup; // 创建成功的回调
  final bool isEditMode; // 是否是编辑模式
  final int? groupId; // 群组ID（编辑模式下需要）
  final String? groupName; // 群组名称（编辑模式下的初始值）

  /// 静态回调：当群组的 doNotDisturb 状态更新后调用
  /// 参数: groupId, newDoNotDisturbValue
  static void Function(int groupId, bool doNotDisturb)? onDoNotDisturbChanged;

  /// 静态回调：当群组信息更新后调用（包括头像、名称等）
  /// 参数: groupId, groupData (包含 name, avatar 等字段)
  static void Function(int groupId, Map<String, dynamic> groupData)? onGroupInfoChanged;

  const MobileCreateGroupPage({
    Key? key,
    this.contacts,
    this.onCreateGroup,
    this.isEditMode = false,
    this.groupId,
    this.groupName,
  }) : super(key: key);

  @override
  State<MobileCreateGroupPage> createState() => _MobileCreateGroupPageState();
}

class _MobileCreateGroupPageState extends State<MobileCreateGroupPage> {
  // 表单控制器
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // 滚动和焦点控制
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchFieldKey = GlobalKey();

  // 记录键盘状态和原始滚动位置
  double _originalScrollOffset = 0.0;

  // 联系人相关
  List<ContactModel> _contacts = [];
  bool _isLoadingContacts = false;
  String? _contactsError;
  String _searchText = '';

  // 选中的联系人ID集合
  final Set<int> _selectedContactIds = {};

  // 群组成员信息（编辑模式下使用）
  List<Map<String, dynamic>> _groupMembers = [];
  String? _currentUserRole;
  int? _currentUserId;

  // 是否正在创建
  bool _isCreating = false;

  // 消息免打扰状态
  bool _doNotDisturb = false;

  // 群组管理设置
  bool _allMuted = false;
  bool _inviteConfirmation = false;
  bool _memberViewPermission = true;
  bool _adminOnlyEditName = false;

  // 群组头像
  File? _selectedAvatar;
  String? _currentAvatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _initialize();

    // 监听搜索框焦点变化
    _searchFocusNode.addListener(_handleSearchFocusChange);
  }

  void _handleSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      // 记录当前滚动位置
      if (_scrollController.hasClients) {
        _originalScrollOffset = _scrollController.offset;
      }

      // 延迟一下确保键盘已经弹出
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToSearchField();
      });
    } else {
      // 当失去焦点时，恢复原来的位置
      Future.delayed(const Duration(milliseconds: 100), () {
        _restoreScrollPosition();
      });
    }
  }

  void _restoreScrollPosition() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _originalScrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToSearchField() {
    if (_scrollController.hasClients) {
      final RenderObject? renderObject = _searchFieldKey.currentContext
          ?.findRenderObject();
      if (renderObject != null) {
        // 确保搜索框在视图中可见
        _scrollController.position.ensureVisible(
          renderObject,
          alignment: 0.2, // 稍微偏上一点，让搜索框不会太贴近顶部
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _initialize() async {
    // 获取当前用户ID
    _currentUserId = await Storage.getUserId();

    // 如果是编辑模式，初始化群组名称
    if (widget.isEditMode && widget.groupName != null) {
      _groupNameController.text = widget.groupName!;
    }

    if (widget.contacts != null && widget.contacts!.isNotEmpty) {
      _contacts = widget.contacts!;
    } else {
      _loadContacts();
    }

    // 如果是编辑模式，加载群组详情
    if (widget.isEditMode && widget.groupId != null) {
      _loadGroupDetails();
    }
  }

  // 加载群组详情（编辑模式）
  Future<void> _loadGroupDetails() async {
    try {
      logger.debug('');
      logger.debug('========== [加载群组详情] ==========');
      logger.debug('🔍 群组ID: ${widget.groupId}');
      logger.debug('🔍 当前用户ID: $_currentUserId');

      final token = await Storage.getToken();
      if (token == null) {
        logger.error('❌ Token为空，无法加载群组详情');
        return;
      }

      final response = await ApiService.getGroupDetail(
        token: token,
        groupId: widget.groupId!,
      );

      logger.debug('📥 API响应: ${response['code']} - ${response['message']}');

      if (mounted && response['code'] == 0) {
        final groupData = response['data']['group'] as Map<String, dynamic>;
        final members = response['data']['members'] as List;
        final memberRole = response['data']['member_role'] as String?;

        logger.debug(
          '📊 群组数据: name=${groupData['name']}, announcement=${groupData['announcement']}',
        );
        logger.debug('📊 成员总数（包含待审核）: ${members.length}');
        logger.debug('📊 当前用户角色: $memberRole');

        // 过滤掉待审核的成员，只显示已审核通过的成员
        final approvedMembers = members.where((member) {
          final approvalStatus =
              member['approval_status'] as String? ?? 'approved';
          return approvalStatus == 'approved';
        }).toList();

        logger.debug('📊 已审核通过的成员数量: ${approvedMembers.length}');

        // 查找当前用户在群组中的信息（从所有成员中查找，包括待审核的）
        final currentUserMember = members.firstWhere(
          (m) => m['user_id'] == _currentUserId,
          orElse: () => <String, dynamic>{},
        );

        if (currentUserMember.isNotEmpty) {
          logger.debug('✅ 找到当前用户信息:');
          logger.debug('   - 昵称: ${currentUserMember['nickname']}');
          logger.debug('   - 免打扰: ${currentUserMember['do_not_disturb']}');
          logger.debug('   - 审核状态: ${currentUserMember['approval_status']}');
        } else {
          logger.debug('⚠️ 未找到当前用户在群组中的信息');
        }

        // 对成员进行排序：群主第一，管理员第二，普通成员最后
        approvedMembers.sort((a, b) {
          final aRole = a['role'] as String;
          final bRole = b['role'] as String;

          if (aRole == 'owner') return -1;
          if (bRole == 'owner') return 1;
          if (aRole == 'admin' && bRole != 'admin') return -1;
          if (bRole == 'admin' && aRole != 'admin') return 1;
          return 0;
        });

        setState(() {
          _groupNameController.text = groupData['name'] ?? '';
          _announcementController.text = groupData['announcement'] ?? '';
          _currentAvatarUrl = groupData['avatar'] as String?;
          _groupMembers = approvedMembers.cast<Map<String, dynamic>>();
          _currentUserRole = memberRole;

          // 加载群组管理设置
          _allMuted = groupData['all_muted'] as bool? ?? false;
          _inviteConfirmation =
              groupData['invite_confirmation'] as bool? ?? false;
          _memberViewPermission =
              groupData['member_view_permission'] as bool? ?? true;
          _adminOnlyEditName =
              groupData['admin_only_edit_name'] as bool? ?? false;

          logger.debug('✅ 已加载群组管理设置:');
          logger.debug('   - 全体禁言: $_allMuted');
          logger.debug('   - 邀请确认: $_inviteConfirmation');
          logger.debug('   - 成员查看权限: $_memberViewPermission');
          logger.debug('   - 仅管理员可修改群名称: $_adminOnlyEditName');
          logger.debug('   - 群组头像: $_currentAvatarUrl');

          // 加载当前用户的昵称和消息免打扰状态
          if (currentUserMember.isNotEmpty) {
            final nickname = currentUserMember['nickname'] as String? ?? '';
            final doNotDisturb =
                currentUserMember['do_not_disturb'] as bool? ?? false;
            _nicknameController.text = nickname;
            _doNotDisturb = doNotDisturb;
            logger.debug('✅ 已设置昵称: "$nickname"');
            logger.debug('✅ 已设置免打扰: $doNotDisturb');
          }
        });

        logger.debug('========== [加载完成] ==========');
        logger.debug('');
      } else {
        logger.error('❌ 加载失败: ${response['message']}');
      }
    } catch (e) {
      logger.error('❌ 加载群组详情异常: $e');
    }
  }

  @override
  void dispose() {
    logger.debug('');
    logger.debug('========== [Dispose Controllers] ==========');
    logger.debug('🗑️ 正在释放 controllers...');
    _groupNameController.dispose();
    logger.debug('✅ _groupNameController disposed');
    _announcementController.dispose();
    logger.debug('✅ _announcementController disposed');
    _nicknameController.dispose();
    logger.debug('✅ _nicknameController disposed');
    _searchController.dispose();
    logger.debug('✅ _searchController disposed');
    _scrollController.dispose();
    logger.debug('✅ _scrollController disposed');
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    logger.debug('✅ _searchFocusNode disposed');
    logger.debug('========== [Dispose 完成] ==========');
    logger.debug('');
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      final token = await Storage.getToken();
      if (token == null) {
        throw Exception('未登录');
      }

      final response = await ApiService.getContacts(token: token);
      final contactsData = response['data']?['contacts'] as List?;
      final contacts = (contactsData ?? [])
          .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
          .where((c) => c.isApproved) // 只显示已通过审核的联系人
          .toList();

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      logger.error('加载联系人失败: $e');
      if (mounted) {
        setState(() {
          _contactsError = e.toString();
          _isLoadingContacts = false;
        });
      }
    }
  }

  List<ContactModel> get _filteredContacts {
    if (_searchText.isEmpty) return _contacts;

    return _contacts.where((contact) {
      final name = (contact.fullName ?? contact.username).toLowerCase();
      final search = _searchText.toLowerCase();
      return name.contains(search);
    }).toList();
  }

  // 过滤后的群组成员列表
  List<Map<String, dynamic>> get _filteredGroupMembers {
    if (_searchText.isEmpty) return _groupMembers;

    final search = _searchText.toLowerCase();
    return _groupMembers.where((member) {
      final nickname = (member['nickname'] as String? ?? '').toLowerCase();
      final fullName = (member['full_name'] as String? ?? '').toLowerCase();
      final username = (member['username'] as String? ?? '').toLowerCase();

      return nickname.contains(search) ||
          fullName.contains(search) ||
          username.contains(search);
    }).toList();
  }

  void _toggleContact(int contactId) {
    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });
  }

  // 显示群组二维码
  void _showGroupQRCode() {
    if (widget.groupId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupQRCodePage(
          groupName: _groupNameController.text,
          groupAvatar: _currentAvatarUrl,
          groupId: widget.groupId!,
        ),
      ),
    );
  }

  // 选择群组头像
  Future<void> _pickGroupAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        lockParentWindow: true, // 锁定父窗口，防止Dialog关闭（桌面端）
        withData: false, // 禁用自动压缩，避免权限问题
        allowCompression: false, // 禁用压缩
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() {
          _selectedAvatar = File(result.files.first.path!);
        });
        
        // 如果是编辑模式，立即上传头像
        if (widget.isEditMode) {
          await _uploadGroupAvatar();
        }
      }
    } catch (e) {
      logger.error('选择群组头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择头像失败')),
        );
      }
    }
  }

  // 上传群组头像
  Future<String?> _uploadGroupAvatar() async {
    if (_selectedAvatar == null) return null;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final token = await Storage.getToken();
      if (token == null) {
        throw Exception('未登录');
      }

      final response = await ApiService.uploadAvatar(
        token: token,
        filePath: _selectedAvatar!.path,
      );

      if (response['code'] == 0) {
        final avatarUrl = response['data']['url'] as String;
        
        // 如果是编辑模式，立即更新群组头像
        if (widget.isEditMode && widget.groupId != null) {
          final updateResponse = await ApiService.updateGroup(
            token: token,
            groupId: widget.groupId!,
            avatar: avatarUrl,
          );
          
          if (updateResponse['code'] == 0) {
            setState(() {
              _currentAvatarUrl = avatarUrl;
            });
            
            // 🔴 通知会话列表更新群组头像
            if (MobileCreateGroupPage.onGroupInfoChanged != null) {
              MobileCreateGroupPage.onGroupInfoChanged!(widget.groupId!, {
                'avatar': avatarUrl,
              });
              logger.debug('📢 已通知会话列表更新群组头像 - groupId: ${widget.groupId}, avatar: $avatarUrl');
            }
            
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
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleCreateGroup() async {
    // 验证群组名称
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入群组名称')));
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final token = await Storage.getToken();
      if (token == null) {
        throw Exception('未登录');
      }

      if (widget.isEditMode && widget.groupId != null) {
        // 编辑模式：更新群组信息
        logger.debug('');
        logger.debug('========== [保存群组设置] ==========');
        logger.debug('🔍 群组ID: ${widget.groupId}');
        logger.debug('👤 当前用户角色: $_currentUserRole');
        logger.debug('📝 群组名称: ${_groupNameController.text.trim()}');
        logger.debug('📝 群公告: ${_announcementController.text.trim()}');
        logger.debug('📝 我的昵称: ${_nicknameController.text.trim()}');
        logger.debug('📝 免打扰: $_doNotDisturb');

        final nickname = _nicknameController.text.trim();
        final announcement = _announcementController.text.trim();
        final groupName = _groupNameController.text.trim();

        // 判断当前用户是否有权限修改群组名称和公告
        final canEditGroupInfo = _currentUserRole == 'owner' || _currentUserRole == 'admin';
        logger.debug('🔐 是否有权限修改群组信息: $canEditGroupInfo');

        final response = await ApiService.updateGroup(
          token: token,
          groupId: widget.groupId!,
          // 只有群主和管理员才传入name和announcement参数
          name: canEditGroupInfo ? groupName : null,
          announcement: canEditGroupInfo && announcement.isNotEmpty ? announcement : null,
          nickname: nickname.isEmpty ? null : nickname,
          doNotDisturb: _doNotDisturb,
        );

        logger.debug('📥 保存响应: ${response['code']} - ${response['message']}');

        if (response['code'] == 0) {
          logger.debug('✅ 保存成功');
          
          // 🔴 通知会话列表更新群组信息（名称等）
          if (canEditGroupInfo && MobileCreateGroupPage.onGroupInfoChanged != null) {
            MobileCreateGroupPage.onGroupInfoChanged!(widget.groupId!, {
              'name': groupName,
            });
            logger.debug('📢 已通知会话列表更新群组名称 - groupId: ${widget.groupId}, name: $groupName');
          }
          
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('保存成功')));

            // 返回上一页
            Navigator.of(context).pop(true);
          }
        } else {
          logger.error('❌ 保存失败: ${response['message']}');
          throw Exception(response['message'] ?? '保存失败');
        }
        logger.debug('========== [保存完成] ==========');
        logger.debug('');
      } else {
        // 创建模式：先上传头像（如果有选择）
        String? avatarUrl;
        if (_selectedAvatar != null) {
          avatarUrl = await _uploadGroupAvatar();
        }

        // 创建模式：调用创建群组API
        final response = await ApiService.createGroup(
          token: token,
          name: _groupNameController.text.trim(),
          announcement: _announcementController.text.trim().isEmpty
              ? null
              : _announcementController.text.trim(),
          avatar: avatarUrl,
          nickname: _nicknameController.text.trim().isEmpty
              ? null
              : _nicknameController.text.trim(),
          memberIds: _selectedContactIds.toList(),
        );

        if (response['code'] == 0) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('群组创建成功')));

            // 🔴 关键修复：立即将当前用户添加到本地 group_members 表
            final groupData = response['data']['group'];
            final groupId = groupData['id'] as int?;
            if (groupId != null) {
              try {
                final currentUserId = await Storage.getUserId();
                if (currentUserId != null) {
                  final localDb = LocalDatabaseService();
                  await localDb.addGroupMember(groupId, currentUserId, role: 'owner');
                  logger.debug('✅ 已将当前用户添加到本地group_members表: groupId=$groupId, userId=$currentUserId');
                }
              } catch (e) {
                logger.error('❌ 添加群组成员到本地数据库失败: $e');
              }
            }

            // 如果有回调，调用回调
            if (widget.onCreateGroup != null) {
              final group = GroupModel.fromJson(groupData);
              widget.onCreateGroup!(group);
            }

            // 返回上一页
            Navigator.of(context).pop(true);
          }
        } else {
          throw Exception(response['message'] ?? '创建群组失败');
        }
      }
    } catch (e) {
      logger.error('${widget.isEditMode ? "保存" : "创建"}群组失败: $e');
      // 提取友好的错误消息
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // 移除 "Exception: " 前缀
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.isEditMode ? '群组设置' : '创建群组'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _handleCreateGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.isEditMode ? '保存' : '创建',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白处关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24, // 底部安全区域 + 额外间距
          ),
          child: Column(
            children: [
              // 群组信息部分
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // 群组头像
                    GestureDetector(
                      onTap: (!widget.isEditMode || _currentUserRole == 'owner' || _currentUserRole == 'admin')
                          ? _pickGroupAvatar
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera, color: Color(0xFF4A90E2)),
                            const SizedBox(width: 12),
                            const Text(
                              '群组头像',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFF4A90E2),
                                  backgroundImage: _selectedAvatar != null
                                      ? FileImage(_selectedAvatar!)
                                      : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                                          ? NetworkImage(_currentAvatarUrl!)
                                          : null) as ImageProvider?,
                                  child: (_selectedAvatar == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                                      ? const Icon(
                                          Icons.group,
                                          size: 32,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                if (_isUploadingAvatar)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            if (!widget.isEditMode || _currentUserRole == 'owner' || _currentUserRole == 'admin')
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // 群组二维码（仅编辑模式显示）
                    if (widget.isEditMode && widget.groupId != null)
                      GestureDetector(
                        onTap: _showGroupQRCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          color: Colors.grey[50],
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code, color: Color(0xFF4A90E2)),
                              SizedBox(width: 12),
                              Text(
                                '群组二维码',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.isEditMode && widget.groupId != null)
                      Divider(height: 1, color: Colors.grey[200]),
                    // 群组名称
                    TextField(
                      controller: _groupNameController,
                      enabled: !widget.isEditMode || _currentUserRole == 'owner' || _currentUserRole == 'admin',
                      decoration: InputDecoration(
                        labelText: '群组名称',
                        hintText: '请输入群组名称',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        prefixIcon: const Icon(Icons.group),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // 群公告
                    TextField(
                      controller: _announcementController,
                      enabled: !widget.isEditMode || _currentUserRole == 'owner' || _currentUserRole == 'admin',
                      decoration: InputDecoration(
                        labelText: '群公告（可选）',
                        hintText: '请输入群公告',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        prefixIcon: const Icon(Icons.announcement),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 1),
                    // 我在本群的昵称
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: '我在本群的昵称（可选）',
                        hintText: '请输入昵称',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        logger.debug('📝 昵称输入变化: "$value"');
                      },
                      onTap: () {
                        logger.debug('👆 点击昵称输入框');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 群管理和消息免打扰
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // 群管理按钮（仅群主和管理员可见）
                    if (_currentUserRole == 'owner' ||
                        _currentUserRole == 'admin') ...[
                      InkWell(
                        onTap: _showGroupManagementDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.settings,
                                color: Color(0xFF4A90E2),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '群管理',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                    ],
                    // 消息免打扰开关
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_off_outlined,
                            color: Color(0xFF4A90E2),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '消息免打扰',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: '开启后，该群组的消息将不会有通知提示',
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _doNotDisturb,
                            onChanged: widget.isEditMode
                                ? (value) async {
                                    // 编辑模式下立即生效
                                    await _updateDoNotDisturb(value);
                                  }
                                : (value) {
                                    // 创建模式下只更新本地状态
                                    setState(() {
                                      _doNotDisturb = value;
                                    });
                                  },
                            activeColor: const Color(0xFF4A90E2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 搜索框和添加按钮
              Container(
                key: _searchFieldKey,
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: '搜索群组成员',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          // 添加清除按钮
                          suffixIcon: _searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchText = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    ),
                    // 添加成员按钮（仅编辑模式显示）
                    if (widget.isEditMode) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: const Color(0xFF4A90E2),
                        onPressed: _showAddMembersDialog,
                      ),
                    ],
                  ],
                ),
              ),
              // 联系人列表
              // 成员列表区域
              if (widget.isEditMode) ...[
                // 编辑模式：显示群组成员列表，固定高度显示4个成员
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 292, // 约4个成员项的高度 (73 * 4)
                    minHeight: 100,
                  ),
                  child: _buildContactsList(),
                ),
                // 退出群聊按钮（仅编辑模式且为群组成员时显示）
                if (_currentUserRole != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLeaveGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '退出群聊',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                // 创建模式：显示联系人列表
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: _buildContactsList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    // 编辑模式：显示群组成员列表
    if (widget.isEditMode) {
      return _buildGroupMembersList();
    }

    // 创建模式：显示联系人列表
    if (_isLoadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contactsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_contactsError!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadContacts, child: const Text('重试')),
          ],
        ),
      );
    }

    final contacts = _filteredContacts;

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchText.isEmpty ? '暂无联系人' : '无搜索结果',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = _selectedContactIds.contains(contact.friendId);

        return Container(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 1),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              _toggleContact(contact.friendId);
            },
            secondary: CircleAvatar(
              radius: 24,
              backgroundColor: contact.avatar.isNotEmpty
                  ? Colors.transparent
                  : const Color(0xFF4A90E2),
              backgroundImage: contact.avatar.isNotEmpty
                  ? NetworkImage(contact.avatar)
                  : null,
              child: contact.avatar.isEmpty
                  ? Text(
                      (contact.fullName ?? contact.username).isNotEmpty
                          ? (contact.fullName ?? contact.username)[0]
                                .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            title: Text(
              contact.fullName ?? contact.username,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            subtitle:
                contact.department != null && contact.department!.isNotEmpty
                ? Text(
                    contact.department!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  )
                : null,
            activeColor: const Color(0xFF4A90E2),
          ),
        );
      },
    );
  }

  // 构建群组成员列表（编辑模式）
  Widget _buildGroupMembersList() {
    // 使用过滤后的成员列表
    final filteredMembers = _filteredGroupMembers;

    if (_groupMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无成员', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    // 如果搜索后没有结果
    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的成员',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '搜索: "$_searchText"',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredMembers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildGroupMemberItem(member);
      },
    );
  }

  // 构建群组成员项
  Widget _buildGroupMemberItem(Map<String, dynamic> member) {
    final userId = member['user_id'] as int;
    // 优先显示群昵称，其次是用户昵称，最后是用户名
    final nickname = member['nickname'] as String?;
    final fullName = member['full_name'] as String?;
    final username = member['username'] as String?;
    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (username ?? '');
    final role = member['role'] as String;
    final isMuted = member['is_muted'] as bool? ?? false;
    final avatar = member['avatar'] as String?;

    final isOwner = role == 'owner';
    final isAdmin = role == 'admin';
    final isCurrentUser = userId == _currentUserId;
    // 只有群主或管理员可以管理成员，但不能管理自己、群主和管理员
    final canManage =
        (_currentUserRole == 'owner' || _currentUserRole == 'admin') &&
        !isCurrentUser &&
        !isOwner &&
        !isAdmin; // 管理员不显示禁言和移除按钮

    // 判断成员是否实际被禁言（个人禁言 或 全体禁言且不是群主/管理员）
    final isEffectivelyMuted = isMuted || (_allMuted && !isOwner && !isAdmin);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24,
            backgroundColor: avatar != null && avatar.isNotEmpty
                ? Colors.transparent
                : const Color(0xFF4A90E2),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // 名称和用户名
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // 禁言徽章（仅显示在普通成员且被禁言时）
                    if (isEffectivelyMuted && !isOwner && !isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: const Color(0xFFFFA726),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mic_off,
                              size: 10,
                              color: Color(0xFFFFA726),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _allMuted && !isMuted ? '全体禁言' : '禁言',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFFA726),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 角色标签和操作按钮
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '群主',
                style: TextStyle(fontSize: 12, color: Color(0xFFE53935)),
              ),
            ),
          if (!isOwner && isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '管理员',
                style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
              ),
            ),

          // 操作按钮（普通成员）
          if (canManage) ...[
            // 禁言按钮（全体禁言时禁用）
            ElevatedButton(
              onPressed: _allMuted
                  ? null
                  : () => _toggleMuteStatus(userId, isMuted),
              style: ElevatedButton.styleFrom(
                backgroundColor: _allMuted
                    ? Colors.grey[400]
                    : (isMuted
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFFA726)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(60, 32),
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
              ),
              child: Text(
                _allMuted ? '全体禁言' : (isMuted ? '解除' : '禁言'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            // 移除按钮
            ElevatedButton(
              onPressed: () => _removeMember(userId, displayName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(60, 32),
              ),
              child: const Text('移除', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  // 切换禁言状态
  Future<void> _toggleMuteStatus(int userId, bool currentlyMuted) async {
    try {
      final token = await Storage.getToken();
      if (token == null) return;

      final response = currentlyMuted
          ? await ApiService.unmuteGroupMember(
              token: token,
              groupId: widget.groupId!,
              userId: userId,
            )
          : await ApiService.muteGroupMember(
              token: token,
              groupId: widget.groupId!,
              userId: userId,
            );

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(currentlyMuted ? '已解除禁言' : '已禁言')),
          );
        }
        // 刷新成员列表
        await _loadGroupDetails();
      } else {
        throw Exception(response['message'] ?? '操作失败');
      }
    } catch (e) {
      logger.error('切换禁言状态失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  // 移除成员
  Future<void> _removeMember(int userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 $displayName 移除出群吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await Storage.getToken();
      if (token == null) return;

      final response = await ApiService.updateGroup(
        token: token,
        groupId: widget.groupId!,
        removeMembers: [userId],
      );

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已移除成员')));
        }
        // 刷新成员列表
        await _loadGroupDetails();
      } else {
        throw Exception(response['message'] ?? '移除失败');
      }
    } catch (e) {
      logger.error('移除群成员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败: $e')));
      }
    }
  }

  // 显示添加成员弹窗
  void _showAddMembersDialog() {
    logger.debug('');
    logger.debug('========== [显示添加成员弹窗] ==========');

    // 获取群组中已有的成员ID列表
    final existingMemberIds = _groupMembers
        .map((m) => m['user_id'] as int)
        .toSet();

    logger.debug('👥 当前群组成员数: ${_groupMembers.length}');
    logger.debug('👥 已有成员ID: $existingMemberIds');
    logger.debug('📋 可选联系人数: ${_contacts.length}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMembersDialog(
        contacts: _contacts,
        existingMemberIds: existingMemberIds,
        onConfirm: (selectedIds) {
          logger.debug('✅ 用户选择了 ${selectedIds.length} 个成员: $selectedIds');
          _addMembers(selectedIds);
        },
      ),
    );
  }

  // 添加成员到群组
  Future<void> _addMembers(List<int> memberIds) async {
    logger.debug('');
    logger.debug('========== [添加群组成员] ==========');
    logger.debug('➕ 准备添加成员: $memberIds');

    if (memberIds.isEmpty) {
      logger.debug('⚠️ 成员列表为空，取消添加');
      return;
    }

    try {
      final token = await Storage.getToken();
      if (token == null) {
        logger.error('❌ Token为空');
        return;
      }

      logger.debug('📤 调用API添加成员...');
      final response = await ApiService.updateGroup(
        token: token,
        groupId: widget.groupId!,
        addMembers: memberIds,
      );

      logger.debug('📥 API响应: ${response['code']} - ${response['message']}');

      if (response['code'] == 0) {
        logger.debug('✅ 添加成功');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${memberIds.length} 个成员')),
          );
        }
        // 刷新成员列表
        logger.debug('🔄 刷新成员列表...');
        await _loadGroupDetails();
      } else {
        logger.error('❌ 添加失败: ${response['message']}');
        throw Exception(response['message'] ?? '添加失败');
      }

      logger.debug('========== [添加完成] ==========');
      logger.debug('');
    } catch (e) {
      logger.error('❌ 添加群成员异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加失败: $e')));
      }
    }
  }

  // 显示群管理对话框
  void _showGroupManagementDialog() {
    // 使用本地状态变量来显示和修改（避免直接修改类状态变量）
    bool allMuted = _allMuted;
    bool inviteConfirmation = _inviteConfirmation;
    bool memberViewPermission = _memberViewPermission;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('群管理'),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7, // 限制高度为屏幕的70%
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // 全体禁言
                    SwitchListTile(
                      title: const Text('全体禁言'),
                      subtitle: const Text('开启后，只有群主和管理员可以发言'),
                      value: allMuted,
                      onChanged: (value) {
                        setState(() {
                          allMuted = value;
                        });
                      },
                      activeColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1),
                    // 群聊邀请确认
                    SwitchListTile(
                      title: const Text('群聊邀请确认'),
                      subtitle: const Text('开启后，群成员邀请需要群主或管理员审核'),
                      value: inviteConfirmation,
                      onChanged: (value) {
                        setState(() {
                          inviteConfirmation = value;
                        });
                      },
                      activeColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1),
                    // 群成员查看权限
                    SwitchListTile(
                      title: const Text('群成员查看权限'),
                      subtitle: const Text('开启后，普通成员可以查看其他成员信息'),
                      value: memberViewPermission,
                      onChanged: (value) {
                        setState(() {
                          memberViewPermission = value;
                        });
                      },
                      activeColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1),
                    // 群组管理权限转让（仅群主可见）
                    if (_currentUserRole == 'owner') ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF4A90E2),
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          '群组管理权限转让',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          '将群主权限转让给其他成员',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFCCCCCC),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showTransferOwnershipDialog();
                        },
                      ),
                      const Divider(height: 1),
                      // 群管理员设置
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_alt_outlined,
                            color: Color(0xFFFFA726),
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          '群管理员设置',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          '设置群组管理员（最多5个）',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFCCCCCC),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showSetAdminsDialog();
                        },
                      ),
                      const Divider(height: 1),
                      // 解散该群聊
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE53935),
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          '解散该群聊',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE53935),
                          ),
                        ),
                        subtitle: const Text(
                          '解散后该群聊将不再显示',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFCCCCCC),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _handleDisbandGroup();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 保存群管理设置
                    Navigator.of(context).pop();
                    await _saveGroupManagementSettings(
                      allMuted: allMuted,
                      inviteConfirmation: inviteConfirmation,
                      memberViewPermission: memberViewPermission,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 更新消息免打扰状态（立即生效）
  Future<void> _updateDoNotDisturb(bool value) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      if (!widget.isEditMode || widget.groupId == null) {
        logger.debug('⚠️ 非编辑模式或群组ID为空，跳过更新');
        return;
      }

      logger.debug('');
      logger.debug('========== [更新消息免打扰状态] ==========');
      logger.debug('🔔 群组ID: ${widget.groupId}');
      logger.debug('🔔 免打扰状态: $value');

      // 调用API更新消息免打扰状态
      final response = await ApiService.updateGroup(
        token: token,
        groupId: widget.groupId!,
        doNotDisturb: value,
      );

      logger.debug('📥 更新响应: ${response['code']} - ${response['message']}');

      if (response['code'] == 0) {
        setState(() {
          _doNotDisturb = value;
        });

        logger.debug('✅ 消息免打扰状态更新成功');

        // 调用静态回调通知其他页面更新
        if (MobileCreateGroupPage.onDoNotDisturbChanged != null) {
          MobileCreateGroupPage.onDoNotDisturbChanged!(widget.groupId!, value);
          logger.debug('📣 已通知其他页面更新 doNotDisturb 状态');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? '已开启消息免打扰' : '已关闭消息免打扰'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        logger.error('❌ 更新失败: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '更新失败')),
          );
        }
      }

      logger.debug('========== [更新完成] ==========');
      logger.debug('');
    } catch (e) {
      logger.error('❌ 更新消息免打扰状态失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  // 保存群组管理设置
  Future<void> _saveGroupManagementSettings({
    required bool allMuted,
    required bool inviteConfirmation,
    required bool memberViewPermission,
  }) async {
    try {
      if (!widget.isEditMode || widget.groupId == null) {
        logger.debug('⚠️ 非编辑模式或群组ID为空，跳过保存');
        return;
      }

      logger.debug('');
      logger.debug('========== [保存群组管理设置] ==========');
      logger.debug('🔧 群组ID: ${widget.groupId}');
      logger.debug('🔧 全体禁言: $allMuted (原值: $_allMuted)');
      logger.debug('🔧 邀请确认: $inviteConfirmation (原值: $_inviteConfirmation)');
      logger.debug('🔧 成员查看权限: $memberViewPermission (原值: $_memberViewPermission)');

      final token = await Storage.getToken();
      if (token == null) {
        throw Exception('未登录');
      }

      // 🔴 修复：只调用发生变化的设置项的API，避免不必要的通知推送
      final List<Future<Map<String, dynamic>>> apiCalls = [];
      
      // 1. 全体禁言 - 只有状态改变时才调用
      if (allMuted != _allMuted) {
        logger.debug('📢 全体禁言状态已变化，将调用API并推送通知');
        apiCalls.add(
          ApiService.updateGroupAllMuted(
            token: token,
            groupId: widget.groupId!,
            allMuted: allMuted,
          ),
        );
      } else {
        logger.debug('⏭️ 全体禁言状态未变化，跳过API调用');
      }
      
      // 2. 邀请确认 - 只有状态改变时才调用
      if (inviteConfirmation != _inviteConfirmation) {
        logger.debug('📢 邀请确认状态已变化，将调用API');
        apiCalls.add(
          ApiService.updateGroupInviteConfirmation(
            token: token,
            groupId: widget.groupId!,
            inviteConfirmation: inviteConfirmation,
          ),
        );
      } else {
        logger.debug('⏭️ 邀请确认状态未变化，跳过API调用');
      }
      
      // 3. 成员查看权限 - 只有状态改变时才调用
      if (memberViewPermission != _memberViewPermission) {
        logger.debug('📢 成员查看权限状态已变化，将调用API');
        apiCalls.add(
          ApiService.updateGroupMemberViewPermission(
            token: token,
            groupId: widget.groupId!,
            memberViewPermission: memberViewPermission,
          ),
        );
      } else {
        logger.debug('⏭️ 成员查看权限状态未变化，跳过API调用');
      }

      // 如果没有任何变化，直接返回
      if (apiCalls.isEmpty) {
        logger.debug('ℹ️ 所有设置均未变化，无需调用API');
        return;
      }

      // 调用API保存变化的设置
      logger.debug('🚀 调用 ${apiCalls.length} 个API...');
      final results = await Future.wait(apiCalls);

      // 检查所有API调用是否成功
      bool allSuccess = true;
      for (int i = 0; i < results.length; i++) {
        if (results[i]['code'] != 0) {
          allSuccess = false;
          logger.error('❌ 设置${i + 1}保存失败: ${results[i]['message']}');
        }
      }

      if (allSuccess) {
        logger.debug('✅ 所有设置保存成功');

        // 更新本地状态
        if (mounted) {
          setState(() {
            _allMuted = allMuted;
            _inviteConfirmation = inviteConfirmation;
            _memberViewPermission = memberViewPermission;
          });
        }

        // 重新加载群组详情，刷新成员列表（特别是全体禁言后的显示状态）
        logger.debug('🔄 重新加载群组详情以刷新UI...');
        await _loadGroupDetails();

        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('群管理设置已保存')));
        }
      } else {
        throw Exception('部分设置保存失败');
      }

      logger.debug('========== [保存完成] ==========');
      logger.debug('');
    } catch (e) {
      logger.error('❌ 保存群组管理设置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  // 显示转让群主权限对话框
  Future<void> _showTransferOwnershipDialog() async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 获取群组成员列表（排除自己）
      final response = await ApiService.getGroupDetail(
        token: token,
        groupId: widget.groupId!,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] != 0 || response['data'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '获取群成员失败')),
          );
        }
        return;
      }

      final membersData = response['data']['members'] as List?;
      if (membersData == null || membersData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('群组暂无其他成员')));
        }
        return;
      }

      // 过滤掉自己，只显示其他成员
      final otherMembers = membersData
          .where((member) => member['user_id'] != _currentUserId)
          .toList();

      if (otherMembers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('群组暂无其他成员')));
        }
        return;
      }

      // 显示成员选择对话框
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择新群主'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: otherMembers.length,
              itemBuilder: (context, index) {
                final member = otherMembers[index];
                final userId = member['user_id'] as int;
                final nickname = member['nickname'] as String?;
                final username = member['username'] as String?;
                final displayName = nickname ?? username ?? '用户$userId';
                final avatarUrl = member['avatar'] as String?;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(8),
                      image: avatarUrl != null && avatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Center(
                            child: Text(
                              displayName.length >= 2
                                  ? displayName.substring(
                                      displayName.length - 2,
                                    )
                                  : displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                  ),
                  title: Text(displayName),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmTransferOwnership(userId, displayName);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('获取群成员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取群成员失败: $e')));
      }
    }
  }

  // 确认转让群主权限
  void _confirmTransferOwnership(int newOwnerId, String newOwnerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认转让'),
        content: Text('确定要将群主权限转让给 $newOwnerName 吗？\n\n转让后您将成为普通成员，无法撤销此操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeTransferOwnership(newOwnerId);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D4F),
            ),
            child: const Text('确认转让'),
          ),
        ],
      ),
    );
  }

  // 执行转让群主权限
  Future<void> _executeTransferOwnership(int newOwnerId) async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService.transferGroupOwnership(
        token: token,
        groupId: widget.groupId!,
        newOwnerId: newOwnerId,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('群主权限转让成功'),
              backgroundColor: Color(0xFF52C41A),
            ),
          );

          // 重新加载群组详情
          await _loadGroupDetails();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '转让失败')),
          );
        }
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('转让群主权限失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('转让失败: $e')));
      }
    }
  }

  // 显示设置管理员对话框
  Future<void> _showSetAdminsDialog() async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 获取群组成员列表
      final response = await ApiService.getGroupDetail(
        token: token,
        groupId: widget.groupId!,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] != 0 || response['data'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '获取群成员失败')),
          );
        }
        return;
      }

      final membersData = response['data']['members'] as List?;
      if (membersData == null || membersData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('群组暂无成员')));
        }
        return;
      }

      // 过滤掉群主，只显示普通成员和管理员
      final selectableMembers = membersData
          .where((member) => member['role'] != 'owner')
          .toList();

      if (selectableMembers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('群组暂无可设置的成员')));
        }
        return;
      }

      // 获取当前的管理员ID列表
      final currentAdminIds = selectableMembers
          .where((member) => member['role'] == 'admin')
          .map((member) => member['user_id'] as int)
          .toSet();

      // 显示成员选择对话框
      if (!mounted) return;
      final selectedAdminIds = await showDialog<Set<int>>(
        context: context,
        builder: (context) => _SetAdminsDialog(
          members: selectableMembers.cast<Map<String, dynamic>>(),
          currentAdminIds: currentAdminIds,
        ),
      );

      if (selectedAdminIds != null) {
        // 保存管理员设置
        await _executeSetAdmins(selectedAdminIds.toList());
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('获取群成员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取群成员失败: $e')));
      }
    }
  }

  // 执行设置管理员
  Future<void> _executeSetAdmins(List<int> adminIds) async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService.setGroupAdmins(
        token: token,
        groupId: widget.groupId!,
        adminIds: adminIds,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('管理员设置成功'),
              backgroundColor: Color(0xFF52C41A),
            ),
          );

          // 重新加载群组详情
          await _loadGroupDetails();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '设置失败')),
          );
        }
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('设置管理员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('设置失败: $e')));
      }
    }
  }

  // 处理解散群聊
  Future<void> _handleDisbandGroup() async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    // 弹出确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认解散'),
        content: const Text('确定要解散该群聊吗？解散后该群聊将不再显示，但数据仍会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('确定解散'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 调用API删除群组
      final response = await ApiService.deleteGroup(
        token: token,
        groupId: widget.groupId!,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('该群聊已解散'),
              backgroundColor: Color(0xFF52C41A),
            ),
          );

          // 返回上一页
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '解散失败')),
          );
        }
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('解散群组失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解散失败: $e')));
      }
    }
  }

  // 处理退出群聊
  Future<void> _handleLeaveGroup() async {
    if (!widget.isEditMode || widget.groupId == null) {
      return;
    }

    // 弹出确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出该群聊吗？退出后您将不再接收此群的消息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await Storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 调用API退出群组
      final response = await ApiService.leaveGroup(
        token: token,
        groupId: widget.groupId!,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['code'] == 0) {
        logger.debug('✅ 退出群组成功');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已成功退出群聊')));
          // 返回到会话列表页面
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '退出失败')),
          );
        }
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      logger.error('退出群组失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('退出失败: $e')));
      }
    }
  }
}

/// 添加成员弹窗
class _AddMembersDialog extends StatefulWidget {
  final List<ContactModel> contacts;
  final Set<int> existingMemberIds;
  final Function(List<int>) onConfirm;

  const _AddMembersDialog({
    Key? key,
    required this.contacts,
    required this.existingMemberIds,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<_AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<_AddMembersDialog> {
  final Set<int> _selectedIds = {};
  String _searchText = '';

  List<ContactModel> get _filteredContacts {
    if (_searchText.isEmpty) return widget.contacts;

    return widget.contacts.where((contact) {
      final name = (contact.fullName ?? contact.username).toLowerCase();
      final search = _searchText.toLowerCase();
      return name.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖动指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    '添加群成员',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '已选 ${_selectedIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 搜索框
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索联系人',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchText = value);
                },
              ),
            ),

            // 联系人列表
            Expanded(
              child: _filteredContacts.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无可添加的联系人',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final isExisting = widget.existingMemberIds.contains(
                          contact.friendId,
                        );
                        final isSelected = _selectedIds.contains(
                          contact.friendId,
                        );

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isExisting
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedIds.remove(contact.friendId);
                                      } else {
                                        _selectedIds.add(contact.friendId);
                                      }
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // 头像
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: contact.avatar.isNotEmpty
                                        ? Colors.transparent
                                        : const Color(0xFF4A90E2),
                                    backgroundImage: contact.avatar.isNotEmpty
                                        ? NetworkImage(contact.avatar)
                                        : null,
                                    child: contact.avatar.isEmpty
                                        ? Text(
                                            (contact.fullName ??
                                                        contact.username)
                                                    .isNotEmpty
                                                ? (contact.fullName ??
                                                          contact.username)[0]
                                                      .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // 名称和部门
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.fullName ?? contact.username,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isExisting
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (contact.department != null &&
                                            contact.department!.isNotEmpty)
                                          Text(
                                            contact.department!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),

                                  // 已在群组标签或选择框
                                  if (isExisting)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '已在群组',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  else
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedIds.add(contact.friendId);
                                          } else {
                                            _selectedIds.remove(
                                              contact.friendId,
                                            );
                                          }
                                        });
                                      },
                                      activeColor: const Color(0xFF4A90E2),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF4A90E2)),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: Color(0xFF4A90E2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () {
                              widget.onConfirm(_selectedIds.toList());
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        _selectedIds.isEmpty
                            ? '确认添加'
                            : '确认添加 (${_selectedIds.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置管理员对话框
class _SetAdminsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final Set<int> currentAdminIds;

  const _SetAdminsDialog({
    Key? key,
    required this.members,
    required this.currentAdminIds,
  }) : super(key: key);

  @override
  State<_SetAdminsDialog> createState() => _SetAdminsDialogState();
}

class _SetAdminsDialogState extends State<_SetAdminsDialog> {
  late Set<int> _selectedAdminIds;

  @override
  void initState() {
    super.initState();
    _selectedAdminIds = Set<int>.from(widget.currentAdminIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置群管理员'),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 提示文本
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFFA726),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '最多可选择5个管理员，已选择 ${_selectedAdminIds.length}/5',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 成员列表
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (context, index) {
                  final member = widget.members[index];
                  final userId = member['user_id'] as int;
                  final nickname = member['nickname'] as String?;
                  final username = member['username'] as String?;
                  final displayName = nickname ?? username ?? '用户$userId';
                  final avatarUrl = member['avatar'] as String?;
                  final isAdmin = _selectedAdminIds.contains(userId);

                  return CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(8),
                        image: avatarUrl != null && avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Center(
                              child: Text(
                                displayName.length >= 2
                                    ? displayName.substring(
                                        displayName.length - 2,
                                      )
                                    : displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                    ),
                    title: Text(displayName),
                    value: isAdmin,
                    activeColor: const Color(0xFF4A90E2),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          // 检查是否超过5个
                          if (_selectedAdminIds.length >= 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('最多只能设置5个管理员'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _selectedAdminIds.add(userId);
                        } else {
                          _selectedAdminIds.remove(userId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedAdminIds);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
          ),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
