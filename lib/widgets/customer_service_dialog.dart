import 'package:flutter/material.dart';

/// 客服与帮助对话框
class CustomerServiceDialog extends StatelessWidget {
  const CustomerServiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '客服与帮助',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 内容区域
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧联系信息
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 邮箱
                        _buildContactItem(
                          icon: Icons.email,
                          iconColor: const Color(0xFF4A90E2),
                          label: '邮箱：',
                          content: 'youdu.support@xindatech.cn',
                        ),
                        const SizedBox(height: 24),
                        // 官网
                        _buildContactItem(
                          icon: Icons.language,
                          iconColor: const Color(0xFF4A90E2),
                          label: '官网：',
                          content: 'https://youdu.cn/',
                          isLink: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 构建联系信息项
  Widget _buildContactItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图标
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        // 标签和内容
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isLink
                        ? const Color(0xFF4A90E2)
                        : const Color(0xFF333333),
                    decoration: isLink ? TextDecoration.underline : null,
                    decorationColor: isLink ? const Color(0xFF4A90E2) : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示客服与帮助对话框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CustomerServiceDialog(),
    );
  }
}
