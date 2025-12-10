import 'package:flutter/material.dart';

/// 群组成员模型（用于语音通话选择）
class GroupCallMember {
  final int userId;
  final String fullName;
  final String username;
  final String? avatar;

  GroupCallMember({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatar,
  });

  /// 获取显示文本
  String get displayText => fullName.isNotEmpty ? fullName : username;

  /// 获取头像文字（取最后两个字符）
  String get avatarText {
    final text = fullName.isNotEmpty ? fullName : username;
    return text.length >= 2 ? text.substring(text.length - 2) : text;
  }
}

/// 群组语音通话成员选择弹窗
class GroupCallMemberPicker extends StatefulWidget {
  final List<GroupCallMember> members; // 群组成员列表
  final Function(List<int> selectedUserIds) onConfirm; // 确认回调
  final int currentUserId; // 当前用户ID

  const GroupCallMemberPicker({
    super.key,
    required this.members,
    required this.onConfirm,
    required this.currentUserId,
  });

  @override
  State<GroupCallMemberPicker> createState() => _GroupCallMemberPickerState();
}

class _GroupCallMemberPickerState extends State<GroupCallMemberPicker> {
  final Set<int> _selectedUserIds = {}; // 已选择的用户ID集合
  final TextEditingController _searchController = TextEditingController();
  List<GroupCallMember> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.members;
    _searchController.addListener(_filterMembers);

    // 自动选中当前用户（发起人自己）
    _selectedUserIds.add(widget.currentUserId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMembers() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        _filteredMembers = widget.members;
      } else {
        _filteredMembers = widget.members.where((member) {
          return member.fullName.toLowerCase().contains(keyword) ||
              member.username.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  void _toggleMember(int userId) {
    // 禁止取消选中当前用户（发起人）
    if (userId == widget.currentUserId) {
      return;
    }

    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _removeSelectedMember(int userId) {
    // 禁止删除当前用户（发起人）
    if (userId == widget.currentUserId) {
      return;
    }

    setState(() {
      _selectedUserIds.remove(userId);
    });
  }

  // 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        // 如果已经全选，则取消全选（但保留当前用户）
        _selectedUserIds.clear();
        _selectedUserIds.add(widget.currentUserId);
      } else {
        // 否则全选当前筛选的成员
        _selectedUserIds.clear();
        _selectedUserIds.addAll(_filteredMembers.map((m) => m.userId));
      }
    });
  }

  // 计算全选复选框的状态值
  bool? get _selectAllCheckboxValue {
    if (_filteredMembers.isEmpty) {
      return false;
    }

    // 计算当前筛选成员中有多少被选中
    final selectedFilteredCount = _filteredMembers
        .where((m) => _selectedUserIds.contains(m.userId))
        .length;

    if (selectedFilteredCount == 0) {
      return false; // 未选中
    } else if (selectedFilteredCount == _filteredMembers.length) {
      return true; // 全选
    } else {
      return null; // 部分选中（半选状态）
    }
  }

  // 是否全选
  bool get _isAllSelected {
    return _selectAllCheckboxValue == true;
  }

  List<GroupCallMember> get _selectedMembers {
    final selected = widget.members
        .where((member) => _selectedUserIds.contains(member.userId))
        .toList();

    // 将当前用户排在第一位
    selected.sort((a, b) {
      if (a.userId == widget.currentUserId) return -1;
      if (b.userId == widget.currentUserId) return 1;
      return 0;
    });

    return selected;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 标题
            const Text(
              '选择语音通话成员',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索成员...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            // 主要内容区域（左右布局）
            Expanded(
              child: Row(
                children: [
                  // 左侧：所有成员列表
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左侧标题（带全选复选框）
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E5E5)),
                              ),
                            ),
                            child: Row(
                              children: [
                                // 全选复选框
                                Checkbox(
                                  value: _selectAllCheckboxValue,
                                  tristate: true,
                                  onChanged: (_filteredMembers.isEmpty)
                                      ? null
                                      : (value) => _toggleSelectAll(),
                                  activeColor: const Color(0xFF4A90E2),
                                ),
                                const SizedBox(width: 8),
                                // 标题文字
                                const Text(
                                  '群组成员',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const Spacer(),
                                // 显示选中数量
                                if (_selectedUserIds.isNotEmpty)
                                  Text(
                                    '已选 ${_selectedUserIds.length}/${_filteredMembers.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // 成员列表
                          Expanded(
                            child: _filteredMembers.isEmpty
                                ? const Center(
                                    child: Text(
                                      '暂无成员',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _filteredMembers[index];
                                      final isSelected = _selectedUserIds
                                          .contains(member.userId);
                                      final isCurrentUser =
                                          member.userId == widget.currentUserId;
                                      return InkWell(
                                        onTap: isCurrentUser
                                            ? null
                                            : () =>
                                                  _toggleMember(member.userId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFE8F4FD)
                                                : Colors.white,
                                            border: const Border(
                                              bottom: BorderSide(
                                                color: Color(0xFFF5F5F5),
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // 复选框（当前用户禁用）
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: isCurrentUser
                                                    ? null
                                                    : (value) => _toggleMember(
                                                        member.userId,
                                                      ),
                                                activeColor: const Color(
                                                  0xFF4A90E2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // 头像
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(
                                                  0xFFE5E5E5,
                                                ),
                                                backgroundImage:
                                                    member.avatar != null &&
                                                        member
                                                            .avatar!
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                        member.avatar!,
                                                      )
                                                    : null,
                                                child:
                                                    member.avatar == null ||
                                                        member.avatar!.isEmpty
                                                    ? Text(
                                                        member.avatarText,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF666666,
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              // 名称信息（昵称 + 用户名）
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // 昵称（如果有）
                                                    if (member
                                                        .fullName
                                                        .isNotEmpty)
                                                      Text(
                                                        member.fullName,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Color(
                                                            0xFF333333,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    // 用户名
                                                    Text(
                                                      '@${member.username}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            member
                                                                .fullName
                                                                .isNotEmpty
                                                            ? 12
                                                            : 14,
                                                        color:
                                                            member
                                                                .fullName
                                                                .isNotEmpty
                                                            ? const Color(
                                                                0xFF999999,
                                                              )
                                                            : const Color(
                                                                0xFF333333,
                                                              ),
                                                        fontWeight:
                                                            member
                                                                .fullName
                                                                .isEmpty
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 右侧：已选择成员列表
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 右侧标题
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E5E5)),
                              ),
                            ),
                            child: Text(
                              '已选择 (${_selectedUserIds.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          // 已选择成员列表
                          Expanded(
                            child: _selectedMembers.isEmpty
                                ? const Center(
                                    child: Text(
                                      '请从左侧选择成员',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _selectedMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _selectedMembers[index];
                                      final isCurrentUser =
                                          member.userId == widget.currentUserId;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFF5F5F5),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // 头像
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: const Color(
                                                0xFFE5E5E5,
                                              ),
                                              backgroundImage:
                                                  member.avatar != null &&
                                                      member.avatar!.isNotEmpty
                                                  ? NetworkImage(member.avatar!)
                                                  : null,
                                              child:
                                                  member.avatar == null ||
                                                      member.avatar!.isEmpty
                                                  ? Text(
                                                      member.avatarText,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                          0xFF666666,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            // 名称信息（昵称 + 用户名）
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // 昵称（如果有）
                                                  if (member
                                                      .fullName
                                                      .isNotEmpty)
                                                    Text(
                                                      member.fullName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xFF333333,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  // 用户名
                                                  Text(
                                                    '@${member.username}',
                                                    style: TextStyle(
                                                      fontSize:
                                                          member
                                                              .fullName
                                                              .isNotEmpty
                                                          ? 12
                                                          : 14,
                                                      color:
                                                          member
                                                              .fullName
                                                              .isNotEmpty
                                                          ? const Color(
                                                              0xFF999999,
                                                            )
                                                          : const Color(
                                                              0xFF333333,
                                                            ),
                                                      fontWeight:
                                                          member
                                                              .fullName
                                                              .isEmpty
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 删除按钮（当前用户不显示）
                                            if (!isCurrentUser)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Color(0xFF999999),
                                                ),
                                                onPressed: () =>
                                                    _removeSelectedMember(
                                                      member.userId,
                                                    ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            // 当前用户显示标签
                                            if (isCurrentUser)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF4A90E2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  '我',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedUserIds.isEmpty
                      ? null
                      : () {
                          print('🎯 [GroupCallMemberPicker] 用户点击确定按钮');
                          print(
                            '🎯 [GroupCallMemberPicker] 选中的用户ID: $_selectedUserIds',
                          );
                          print(
                            '🎯 [GroupCallMemberPicker] 选中的用户数量: ${_selectedUserIds.length}',
                          );
                          Navigator.of(context).pop();
                          print(
                            '🎯 [GroupCallMemberPicker] 对话框已关闭，准备调用onConfirm回调',
                          );
                          widget.onConfirm(_selectedUserIds.toList());
                          print('🎯 [GroupCallMemberPicker] onConfirm回调已调用完成');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('确定', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
