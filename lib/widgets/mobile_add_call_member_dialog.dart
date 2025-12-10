import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 移动端邀请成员加入通话对话框
class MobileAddCallMemberDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableMembers; // 可邀请的成员
  final List<Map<String, dynamic>> currentCallMembers; // 当前通话中的成员

  const MobileAddCallMemberDialog({
    super.key,
    required this.availableMembers,
    required this.currentCallMembers,
  });

  @override
  State<MobileAddCallMemberDialog> createState() =>
      _MobileAddCallMemberDialogState();
}

class _MobileAddCallMemberDialogState extends State<MobileAddCallMemberDialog> {
  final Set<int> _newSelectedIds = <int>{}; // 新选中的成员ID
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.availableMembers;
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
        _filteredMembers = widget.availableMembers;
      } else {
        _filteredMembers = widget.availableMembers.where((member) {
          final fullName = (member['fullName'] as String? ?? '').toLowerCase();
          final username = (member['username'] as String? ?? '').toLowerCase();
          return fullName.contains(keyword) || username.contains(keyword);
        }).toList();
      }
    });
  }

  void _toggleMember(int userId) {
    setState(() {
      if (_newSelectedIds.contains(userId)) {
        _newSelectedIds.remove(userId);
      } else {
        _newSelectedIds.add(userId);
      }
    });
    logger.debug('📞 [Mobile] 选中成员变化: $_newSelectedIds');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '邀请成员加入通话',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF666666)),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 当前通话成员（已连接）- 只读显示
          if (widget.currentCallMembers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF8F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Color(0xFF52C41A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '通话中 (${widget.currentCallMembers.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF52C41A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.currentCallMembers.map((member) {
                      return Chip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF4A90E2),
                          child: Text(
                            member['avatarText'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        label: Text(
                          member['displayName'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
          ),

          // 可邀请成员标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
            child: Row(
              children: [
                const Text(
                  '可邀请成员',
                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
                const Spacer(),
                Text(
                  '已选 ${_newSelectedIds.length} 人',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 可邀请成员列表
          Expanded(
            child: _filteredMembers.isEmpty
                ? const Center(
                    child: Text(
                      '暂无可邀请成员',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      final userId = member['userId'] as int;
                      final isSelected = _newSelectedIds.contains(userId);

                      return InkWell(
                        onTap: () => _toggleMember(userId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF5F9FF)
                                : Colors.white,
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFFF5F5F5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 复选框
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) => _toggleMember(userId),
                                activeColor: const Color(0xFF4A90E2),
                              ),
                              const SizedBox(width: 12),
                              // 头像
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE5E5E5),
                                child: Text(
                                  member['avatarText'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 名称信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      member['fullName'] as String,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '@${member['username']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
                                      ),
                                      overflow: TextOverflow.ellipsis,
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

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
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
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _newSelectedIds.isEmpty
                        ? null
                        : () {
                            logger.debug(
                              '📞 [Mobile] 确认邀请成员: $_newSelectedIds',
                            );
                            Navigator.of(context).pop(_newSelectedIds.toList());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                    ),
                    child: Text(
                      '确定 (${_newSelectedIds.length})',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
