import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../utils/storage.dart';
import 'mobile_chat_page.dart';

/// 加入群组页面（扫码后跳转）
class JoinGroupFromQRPage extends StatefulWidget {
  final int groupId; // 从二维码解析出的群组ID

  const JoinGroupFromQRPage({
    super.key,
    required this.groupId,
  });

  @override
  State<JoinGroupFromQRPage> createState() => _JoinGroupFromQRPageState();
}

class _JoinGroupFromQRPageState extends State<JoinGroupFromQRPage> {
  bool _isLoading = true;
  bool _isJoining = false;
  Map<String, dynamic>? _groupInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  // 加载群组信息
  Future<void> _loadGroupInfo() async {
    try {
      final token = await Storage.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = '未登录';
          _isLoading = false;
        });
        return;
      }

      // 获取群组信息
      final response = await ApiService.getGroupInfo(
        token: token,
        groupId: widget.groupId,
      );

      if (response['code'] == 0 && response['data'] != null) {
        setState(() {
          // 后端返回的数据结构是 { group: {...}, members: [...], member_role: "..." }
          // 我们需要提取 group 对象
          final data = response['data'] as Map<String, dynamic>;
          _groupInfo = data['group'] as Map<String, dynamic>?;
          // 同时保存 members 信息用于显示成员数量
          if (_groupInfo != null && data['members'] != null) {
            _groupInfo!['members'] = data['members'];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? '群组不存在';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.error('加载群组信息失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  // 加入群组
  Future<void> _joinGroup() async {
    if (_isJoining || _groupInfo == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final token = await Storage.getToken();
      if (token == null) {
        _showError('未登录');
        return;
      }

      final response = await ApiService.joinGroup(
        token: token,
        groupId: widget.groupId,
      );

      if (response['code'] == 0) {
        _showSuccess(response['message'] ?? '群组加入成功');
        // 延迟返回
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showError(response['message'] ?? '加入失败');
      }
    } catch (e) {
      logger.error('加入群组失败: $e');
      _showError('加入失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFF999999),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildGroupInfo(),
    );
  }

  Widget _buildGroupInfo() {
    if (_groupInfo == null) return const SizedBox();

    final groupName = _groupInfo!['name'] as String? ?? '未命名群组';
    final groupAvatar = _groupInfo!['avatar'] as String?;
    final memberCount = (_groupInfo!['members'] as List?)?.length ?? 0;
    final description = _groupInfo!['description'] as String?;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 群组头像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF52C41A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: groupAvatar != null && groupAvatar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            groupAvatar,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(groupName);
                            },
                          ),
                        )
                      : _buildDefaultAvatar(groupName),
                ),
                const SizedBox(height: 16),
                // 群组名称
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // 成员数量
                Text(
                  '群成员：$memberCount人',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 40),
                // 群组描述
                if (description != null && description.isNotEmpty)
                  _buildInfoItem('群组描述', description),
              ],
            ),
          ),
        ),
        // 底部按钮
        Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isJoining ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52C41A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '加入群组',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.length >= 2 ? name.substring(name.length - 2) : name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
