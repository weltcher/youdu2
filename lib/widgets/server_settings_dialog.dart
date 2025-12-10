import 'package:flutter/material.dart';
import 'package:youdu/config/api_config.dart';
import '../utils/logger.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _serverAddressController;
  late final TextEditingController _portController;
  final TextEditingController _companyIdController = TextEditingController();
  int _selectedTabIndex = 0; // 0: 服务器地址, 1: 企业号

  @override
  void initState() {
    super.initState();
    // 从 ApiConfig 获取当前配置
    _serverAddressController = TextEditingController(text: ApiConfig.host);
    _portController = TextEditingController(text: ApiConfig.port);
  }

  // 统一的标签样式
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF333333),
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
  );

  @override
  void dispose() {
    _serverAddressController.dispose();
    _portController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(),
            // Tab栏
            _buildTabBar(),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(30),
              child: _selectedTabIndex == 0
                  ? _buildServerAddressForm()
                  : _buildCompanyIdForm(),
            ),
            // 底部按钮
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '服务器设置',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          _buildTab('服务器地址', 0),
          const SizedBox(width: 40),
          _buildTab('企业号', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF4A90E2)
                : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _buildServerAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 服务器地址
        _buildInputField(
          label: '服务器地址',
          controller: _serverAddressController,
          hintText: '请输入服务器地址',
          isRequired: true,
        ),
        const SizedBox(height: 20),
        // 端口
        _buildInputField(
          label: '端口',
          controller: _portController,
          hintText: '请输入端口',
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildCompanyIdForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: '企业号',
          controller: _companyIdController,
          hintText: '请输入企业号',
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isRequired)
              const Text(
                '* ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF0000),
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(label, style: _labelStyle),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
          ),
          child: TextField(
            controller: controller,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 取消按钮
          SizedBox(
            width: 100,
            height: 36,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 确认按钮
          SizedBox(
            width: 100,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // 保存服务器设置到 ApiConfig
                final host = _serverAddressController.text.trim();
                final port = _portController.text.trim();

                if (host.isEmpty || port.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('服务器地址和端口不能为空')));
                  return;
                }

                ApiConfig.setServer(host, port);
                logger.debug('服务器设置已保存: ${ApiConfig.baseUrl}');
                logger.debug('企业号: ${_companyIdController.text}');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('服务器地址已设置为: ${ApiConfig.baseUrl}')),
                );

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                '确认',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
