import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/contact_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';
import '../utils/storage.dart';

/// 转发消息页面 - 用于选择转发目标
class ForwardMessagePage extends StatefulWidget {
  final MessageModel message;

  const ForwardMessagePage({super.key, required this.message});

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  // 控制器
  final TextEditingController _searchController = TextEditingController();
  final WebSocketService _wsService = WebSocketService();

  // 数据列表
  List<ContactModel> _contacts = [];
  List<GroupModel> _groups = [];
  List<dynamic> _searchResults = []; // 搜索结果（包含联系人和群组）

  // 选中的目标
  final Set<String> _selectedTargets = {}; // 格式: "user_123" 或 "group_456"

  // 状态
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSearching = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _token = await Storage.getToken();

    if (_token == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 并行加载联系人和群组
      final results = await Future.wait([
        ApiService.getContacts(token: _token!),
        ApiService.getUserGroups(token: _token!),
      ]);

      final contactsResponse = results[0];
      final groupsResponse = results[1];

      if (mounted) {
        setState(() {
          if (contactsResponse['code'] == 0 &&
              contactsResponse['data'] != null) {
            _contacts = (contactsResponse['data'] as List)
                .map((json) => ContactModel.fromJson(json))
                .toList();
          }

          if (groupsResponse['code'] == 0 &&
              groupsResponse['data'] != null) {
            final groupsData = groupsResponse['data']['groups'] as List?;
            _groups = (groupsData ?? [])
                .map((json) => GroupModel.fromJson(json))
                .toList();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      logger.error('加载数据失败', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];

      // 搜索联系人
      _searchResults.addAll(
        _contacts.where((contact) {
          final name = contact.displayName;
          return name.toLowerCase().contains(query.toLowerCase());
        }),
      );

      // 搜索群组
      _searchResults.addAll(
        _groups.where((group) {
          final name = group.nickname ?? group.name;
          return name.toLowerCase().contains(query.toLowerCase());
        }),
      );
    });
  }

  Future<void> _forwardMessage() async {
    if (_selectedTargets.isEmpty || _token == null) return;

    setState(() => _isSending = true);

    try {
      int successCount = 0;
      int totalCount = _selectedTargets.length;

      for (final target in _selectedTargets) {
        final isGroup = target.startsWith('group_');
        final targetId = int.parse(target.split('_')[1]);

        bool success = false;

        if (isGroup) {
          // 发送群组消息
          success = await _wsService.sendGroupMessage(
            groupId: targetId,
            content: widget.message.content,
            messageType: widget.message.messageType,
            fileName: widget.message.fileName,
          );
        } else {
          // 发送私聊消息
          success = await _wsService.sendMessage(
            receiverId: targetId,
            content: widget.message.content,
            messageType: widget.message.messageType,
            fileName: widget.message.fileName,
          );
        }

        if (success) {
          successCount++;
        }

        // 添加小延迟，避免发送过快
        if (_selectedTargets.length > 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (mounted) {
        if (successCount == totalCount) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('成功转发到 $successCount 个目标')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('部分转发成功 ($successCount/$totalCount)')),
          );
        }
      }
    } catch (e) {
      logger.error('转发消息失败', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('转发失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择转发目标'),
        actions: [
          if (_selectedTargets.isNotEmpty)
            TextButton(
              onPressed: _isSending ? null : _forwardMessage,
              child: Text(
                _isSending ? '发送中...' : '发送(${_selectedTargets.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索联系人或群组',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _performSearch,
            ),
          ),
          // 内容列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      // 显示搜索结果
      if (_searchResults.isEmpty) {
        return const Center(child: Text('未找到匹配的联系人或群组'));
      }

      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          if (item is ContactModel) {
            return _buildContactItem(item);
          } else if (item is GroupModel) {
            return _buildGroupItem(item);
          }
          return const SizedBox();
        },
      );
    }

    // 显示所有联系人和群组
    return ListView(
      children: [
        // 联系人部分
        if (_contacts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Text(
              '联系人',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ..._contacts.map((contact) => _buildContactItem(contact)),
        ],

        // 群组部分
        if (_groups.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Text(
              '群组',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ..._groups.map((group) => _buildGroupItem(group)),
        ],
      ],
    );
  }

  Widget _buildContactItem(ContactModel contact) {
    final targetKey = 'user_${contact.friendId}';
    final isSelected = _selectedTargets.contains(targetKey);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(contact.displayName[0].toUpperCase()),
      ),
      title: Text(contact.displayName),
      subtitle: null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedTargets.add(targetKey);
            } else {
              _selectedTargets.remove(targetKey);
            }
          });
        },
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTargets.remove(targetKey);
          } else {
            _selectedTargets.add(targetKey);
          }
        });
      },
    );
  }

  Widget _buildGroupItem(GroupModel group) {
    final targetKey = 'group_${group.id}';
    final isSelected = _selectedTargets.contains(targetKey);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: const Icon(Icons.group, color: Colors.white),
      ),
      title: Text(group.nickname ?? group.name),
      subtitle: group.nickname != null
          ? Text(group.name)
          : Text('${group.memberIds.length}人'),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedTargets.add(targetKey);
            } else {
              _selectedTargets.remove(targetKey);
            }
          });
        },
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTargets.remove(targetKey);
          } else {
            _selectedTargets.add(targetKey);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
