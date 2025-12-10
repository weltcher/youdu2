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

  /// 获取头像文字（取名字的第一个字符）
  String get avatarText {
    final text = fullName.isNotEmpty ? fullName : username;
    return text.isNotEmpty ? text[0].toUpperCase() : '?';
  }
}

/// 移动端群组语音/视频通话成员选择弹窗
class MobileGroupCallMemberPicker extends StatefulWidget {
  final List<GroupCallMember> members; // 群组成员列表
  final Function(List<int> selectedUserIds) onConfirm; // 确认回调
  final int currentUserId; // 当前用户ID
  final bool isVideoCall; // 是否是视频通话

  const MobileGroupCallMemberPicker({
    super.key,
    required this.members,
    required this.onConfirm,
    required this.currentUserId,
    this.isVideoCall = false,
  });

  @override
  State<MobileGroupCallMemberPicker> createState() =>
      _MobileGroupCallMemberPickerState();
}

class _MobileGroupCallMemberPickerState
    extends State<MobileGroupCallMemberPicker> {
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

  // 获取选中的成员数量（不包括自己）
  int get _selectedOthersCount {
    return _selectedUserIds.length -
        (_selectedUserIds.contains(widget.currentUserId) ? 1 : 0);
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

  // 是否全选
  bool get _isAllSelected {
    if (_filteredMembers.isEmpty) return false;

    // 检查所有筛选出的成员是否都被选中
    return _filteredMembers.every(
      (member) => _selectedUserIds.contains(member.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75; // 最大高度为屏幕的75%

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 标题
                    Row(
                      children: [
                        Icon(
                          widget.isVideoCall ? Icons.videocam : Icons.phone,
                          color: const Color(0xFF4A90E2),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.isVideoCall ? '选择视频通话成员' : '选择语音通话成员',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 搜索框
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: '搜索成员...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF999999),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // 成员信息栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: const Color(0xFFF8F8F8),
                child: Row(
                  children: [
                    // 全选按钮
                    InkWell(
                      onTap: _toggleSelectAll,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _isAllSelected
                                      ? const Color(0xFF4A90E2)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: _isAllSelected
                                    ? const Color(0xFF4A90E2)
                                    : Colors.transparent,
                              ),
                              child: _isAllSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '全选',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已选 $_selectedOthersCount/${widget.members.length - 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 成员列表
              Flexible(
                child: _filteredMembers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '没有找到相关成员',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final isSelected = _selectedUserIds.contains(
                            member.userId,
                          );
                          final isCurrentUser =
                              member.userId == widget.currentUserId;

                          return Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: isCurrentUser
                                  ? null
                                  : () => _toggleMember(member.userId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // 选择框
                                    Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF4A90E2)
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF4A90E2)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),

                                    // 头像
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            member.avatar != null &&
                                                member.avatar!.isNotEmpty
                                            ? null
                                            : _getAvatarColor(member.userId),
                                        image:
                                            member.avatar != null &&
                                                member.avatar!.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  member.avatar!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child:
                                          member.avatar == null ||
                                              member.avatar!.isEmpty
                                          ? Center(
                                              child: Text(
                                                member.avatarText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),

                                    // 用户信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  member.fullName.isNotEmpty
                                                      ? member.fullName
                                                      : '@${member.username}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF333333),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF4A90E2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    '我',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (member.fullName.isNotEmpty)
                                            Text(
                                              '@${member.username}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
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
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedOthersCount == 0
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                widget.onConfirm(_selectedUserIds.toList());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // 获取头像背景色
  Color _getAvatarColor(int userId) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFF50C878),
      const Color(0xFFF39C12),
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFF34495E),
      const Color(0xFFF1C40F),
    ];
    return colors[userId % colors.length];
  }
}
