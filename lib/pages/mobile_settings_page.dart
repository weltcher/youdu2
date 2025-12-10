import 'package:flutter/material.dart';
import 'package:youdu/utils/storage.dart';
import 'package:youdu/utils/app_localizations.dart';
import 'package:youdu/main.dart';

/// 移动端设置页面
class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  // 语言设置
  String _selectedLanguage = '简体中文';

  // 消息通知设置
  bool _newMessageSoundEnabled = false;
  bool _newMessagePopupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载保存的设置
  Future<void> _loadSettings() async {
    final languageCode = await Storage.getLanguage();
    final soundEnabled = await Storage.getNewMessageSoundEnabled();
    final popupEnabled = await Storage.getNewMessagePopupEnabled();

    setState(() {
      _selectedLanguage = AppLocalizations.getLanguageName(languageCode);
      _newMessageSoundEnabled = soundEnabled;
      _newMessagePopupEnabled = popupEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '设置',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // 设置项列表（去掉分组标题）
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildLanguageSetting(),
                const Divider(height: 1, indent: 16),
                _buildSwitchItem(
                  title: '新消息提示音',
                  value: _newMessageSoundEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _newMessageSoundEnabled = value;
                    });
                    // 保存到本地存储
                    await Storage.saveNewMessageSoundEnabled(value);
                  },
                ),
                const Divider(height: 1, indent: 16),
                _buildSwitchItem(
                  title: '新消息弹窗显示',
                  value: _newMessagePopupEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _newMessagePopupEnabled = value;
                    });
                    // 保存到本地存储
                    await Storage.saveNewMessagePopupEnabled(value);
                  },
                ),
                const Divider(height: 1, indent: 16),
                _buildArrowItem(
                  title: '版本信息',
                  subtitle: 'v10.0.12-2025102401',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 版权信息
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Copyright (c) 2014-2025 youdu.cn\nAll rights reserved',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 语言设置项
  Widget _buildLanguageSetting() {
    return InkWell(
      onTap: () {
        _showLanguageDialog();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Text(
              '语言设置',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const Spacer(),
            Text(
              _selectedLanguage,
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  /// 开关设置项
  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }

  /// 箭头设置项
  Widget _buildArrowItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  /// 显示语言选择对话框
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('简体中文'),
            _buildLanguageOption('English'),
            _buildLanguageOption('繁體中文'),
          ],
        ),
      ),
    );
  }

  /// 语言选项
  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _selectedLanguage,
      activeColor: const Color(0xFF4A90E2),
      selected: isSelected,
      onChanged: (value) async {
        if (value == null) return;

        setState(() {
          _selectedLanguage = value;
        });

        // 将语言名称转换为语言代码
        final languageCode = AppLocalizations.getLanguageCode(value);

        // 保存到本地存储
        await Storage.saveLanguage(languageCode);

        // 立即切换应用语言
        final locale = AppLocalizations.getLocaleFromCode(languageCode);
        if (mounted) {
          MyApp.setLocale(context, locale);
          Navigator.pop(context); // 关闭对话框
        }
      },
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('有度即时通'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('版本', 'v10.0.12-2025102401'),
            const SizedBox(height: 12),
            _buildInfoRow('发布时间', '2025-10-24'),
            const SizedBox(height: 24),
            const Text(
              '有度是一款专为企业打造的安全、高效的即时通讯工具。',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label：',
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ],
    );
  }
}
