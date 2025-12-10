import 'package:flutter/material.dart';
import '../../models/recent_contact_model.dart';

/// 转发对话框
class ForwardDialog extends StatefulWidget {
  final int? currentUserId;
  final List<RecentContactModel> recentContacts;
  final Function(List<int>) onConfirm;

  const ForwardDialog({
    super.key,
    required this.currentUserId,
    required this.recentContacts,
    required this.onConfirm,
  });

  @override
  State<ForwardDialog> createState() => _ForwardDialogState();
}

class _ForwardDialogState extends State<ForwardDialog> {
  final Set<int> _selectedUserIds = {};

  @override
  Widget build(BuildContext context) {
    // 过滤掉当前聊天的联系人
    final availableContacts = widget.recentContacts
        .where((contact) => contact.userId != widget.currentUserId)
        .toList();

    return AlertDialog(
      title: const Text('选择转发对象'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SizedBox(
        width: 400,
        height: 500,
        child: availableContacts.isEmpty
            ? const Center(
                child: Text(
                  '暂无可转发的联系人',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              )
            : ListView.builder(
                itemCount: availableContacts.length,
                itemBuilder: (context, index) {
                  final contact = availableContacts[index];
                  final isSelected = _selectedUserIds.contains(contact.userId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(contact.userId);
                        } else {
                          _selectedUserIds.remove(contact.userId);
                        }
                      });
                    },
                    title: Text(contact.displayName),
                    subtitle: contact.username.isNotEmpty
                        ? Text('@${contact.username}')
                        : null,
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        contact.displayName.length >= 2
                            ? contact.displayName.substring(
                                contact.displayName.length - 2,
                              )
                            : contact.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    activeColor: const Color(0xFF4A90E2),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectedUserIds.isEmpty
              ? null
              : () {
                  widget.onConfirm(_selectedUserIds.toList());
                  Navigator.pop(context);
                },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF4A90E2)),
          child: Text(
            '确认${_selectedUserIds.isNotEmpty ? '(${_selectedUserIds.length})' : ''}',
          ),
        ),
      ],
    );
  }
}
