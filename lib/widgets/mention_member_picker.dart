import 'package:flutter/material.dart';

/// 群组成员模型（用于@功能）
class GroupMemberForMention {
  final int userId;
  final String fullName;
  final String username;

  GroupMemberForMention({
    required this.userId,
    required this.fullName,
    required this.username,
  });

  /// 获取显示文本，只显示昵称
  String get displayText => fullName;
}

/// @成员选择器弹窗
class MentionMemberPicker extends StatefulWidget {
  final List<GroupMemberForMention> members; // 群组成员列表（已排除自己）
  final Function(String mentionText, List<int> mentionedUserIds)
  onSelect; // 选择回调
  final String? currentUserRole; // 当前用户在群组中的角色（owner/admin/member）

  const MentionMemberPicker({
    super.key,
    required this.members,
    required this.onSelect,
    this.currentUserRole,
  });

  @override
  State<MentionMemberPicker> createState() => _MentionMemberPickerState();
}

class _MentionMemberPickerState extends State<MentionMemberPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupMemberForMention> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.members;
    _searchController.addListener(_filterMembers);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // 固定宽度，避免太宽
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '搜索成员...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // 成员列表
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // "所有成员"选项 - 只有群主和管理员才显示
                if (widget.currentUserRole == 'owner' ||
                    widget.currentUserRole == 'admin')
                  _buildMemberItem(
                    text: '所有成员',
                    onTap: () {
                      // @all，所有成员都会被提及
                      final allUserIds = widget.members
                          .map((m) => m.userId)
                          .toList();
                      widget.onSelect('@all', allUserIds);
                    },
                    isAllMembers: true,
                  ),
                // 具体成员列表
                ..._filteredMembers.map((member) {
                  return _buildMemberItem(
                    text: member.displayText,
                    onTap: () {
                      // 选择具体成员时，只使用昵称，去掉括号和用户名
                      widget.onSelect('@${member.fullName}', [member.userId]);
                    },
                    isAllMembers: false,
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem({
    required String text,
    required VoidCallback onTap,
    required bool isAllMembers,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
        ),
        child: Row(
          children: [
            // 图标
            Icon(
              isAllMembers ? Icons.groups : Icons.person,
              size: 20,
              color: const Color(0xFF4A90E2),
            ),
            const SizedBox(width: 12),
            // 文本
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
