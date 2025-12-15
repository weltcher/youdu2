import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'package:youdu/services/api_service.dart';
import 'package:youdu/utils/storage.dart';
import 'package:youdu/utils/app_localizations.dart';
import '../utils/logger.dart';
import 'mobile_chat_page.dart';
import 'mobile_contacts_page.dart';
import 'mobile_home_page.dart';

class LoginPage extends StatefulWidget {
  final bool clearCredentials; // 是否清空保存的账号密码
  final String? prefillAccount; // 预填充的账号（用于切换账号时）
  
  const LoginPage({super.key, this.clearCredentials = false, this.prefillAccount});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();
  // PC端保留记住密码和自动登录选项
  bool _rememberPassword = false;
  bool _autoLogin = false;
  bool _obscurePassword = true;
  String _selectedLanguage = '简体中文'; // 当前选择的语言
  bool _canLogin = false;
  bool _isLoading = false; // 登录加载状态

  // 验证码倒计时相关
  int _countdown = 0;
  bool _isCountingDown = false;

  // 登录方式选择：0=账号登录，1=验证码登录
  int _selectedTabIndex = 0;

  // 检测是否是PC端
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  // 统一的标签样式
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF333333),
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
  );

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_checkCanLogin);
    _passwordController.addListener(_checkCanLogin);

    // 加载保存的登录信息
    _loadSavedCredentials();
  }

  // 加载保存的登录配置和账号密码信息
  Future<void> _loadSavedCredentials() async {
    logger.debug('🔍 开始加载保存的登录配置...');
    
    // 如果是切换账号进入，清空输入框
    if (widget.clearCredentials) {
      logger.debug('🗑️ 切换账号模式，清空输入框');
      setState(() {
        _accountController.clear();
        _passwordController.clear();
        _phoneController.clear();
        _verifyCodeController.clear();
      });
      return;
    }
    
    // 如果有预填充的账号，先填充
    if (widget.prefillAccount != null && widget.prefillAccount!.isNotEmpty) {
      logger.debug('📝 预填充账号: ${widget.prefillAccount}');
      setState(() {
        _accountController.text = widget.prefillAccount!;
      });
    }
    
    // 获取最近一次登录的用户ID
    final lastUserId = await Storage.getLastLoggedInUserId();
    if (lastUserId != null) {
      if (_isDesktop) {
        // PC端：加载记住密码和自动登录配置
        final rememberPassword = await Storage.getRememberPassword(lastUserId);
        final autoLogin = await Storage.getAutoLogin(lastUserId);
        
        logger.debug('📋 PC端加载的配置: rememberPassword=$rememberPassword, autoLogin=$autoLogin');
        
        setState(() {
          _rememberPassword = rememberPassword;
          _autoLogin = autoLogin;
        });
        
        // 如果勾选了记住密码，加载账号密码
        if (rememberPassword) {
          final savedAccount = await Storage.getSavedAccountForLastUser();
          final savedPassword = await Storage.getSavedPasswordForLastUser();

          logger.debug(
            '📋 加载的账号密码: account=${savedAccount != null ? "已保存" : "未保存"}, password=${savedPassword != null ? "已保存" : "未保存"}',
          );

          if (savedAccount != null && savedPassword != null) {
            setState(() {
              _accountController.text = savedAccount;
              _passwordController.text = savedPassword;
            });
            logger.debug('✅ 已填充账号密码到输入框');
          }
        }
      } else {
        // 移动端：直接加载最近一次登录的账号密码（简化逻辑）
        final savedAccount = await Storage.getSavedAccountForLastUser();
        final savedPassword = await Storage.getSavedPasswordForLastUser();

        logger.debug(
          '📋 移动端加载的账号密码: account=${savedAccount != null ? "已保存" : "未保存"}, password=${savedPassword != null ? "已保存" : "未保存"}',
        );

        if (savedAccount != null && savedPassword != null) {
          setState(() {
            _accountController.text = savedAccount;
            _passwordController.text = savedPassword;
          });
          logger.debug('✅ 已填充账号密码到输入框');
        }
      }
    } else {
      logger.debug('ℹ️ 没有最近登录的用户ID');
    }
  }

  void _checkCanLogin() {
    setState(() {
      // 账号登录：账号和密码都有内容
      _canLogin =
          _accountController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  // 处理账号密码登录
  Future<void> _handleAccountLogin() async {
    // 设置加载状态
    setState(() {
      _isLoading = true;
    });

    final username = _accountController.text.trim();
    final password = _passwordController.text;

    try {
      final result = await ApiService.login(
        username: username,
        password: password,
      );

      if (result['code'] == 0) {
        // 登录成功
        final token = result['data']['token'];
        final user = result['data']['user'];

        // 保存token和用户信息
        await Storage.saveLoginInfo(
          token: token,
          userId: user['id'],
          username: user['username'],
          fullName: user['full_name'],
          avatar: user['avatar'],
        );

        // 重新初始化日志系统（使用用户ID）
        await logger.init(userId: user['id'].toString());
        logger.info('📝 日志系统已重新初始化，用户ID: ${user['id']}');

        // 保存登录配置和账号密码（根据平台和用户选择）
        await _saveCredentials(user['id'], username, password);

        // 注意：用户状态已在后端登录接口中自动设置为 online，无需前端再次设置
        logger.debug('✅ 用户登录成功，状态: ${user['status']}');

        // 🔴 登录成功后清除所有本地缓存
        logger.info('🗑️ 账号密码登录成功，开始清除所有本地缓存...');
        MobileChatPage.clearAllCache();
        MobileContactsPage.clearAllCache();
        MobileHomePage.clearAllCache();
        logger.info('✅ 所有本地缓存已清除，即将重新加载数据');

        _showSuccess('登录成功');

        // 跳转到主页
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // 登录失败，重置加载状态
        setState(() {
          _isLoading = false;
        });

        // 显示错误消息（服务器会自动踢掉已登录的设备，不需要特殊处理）
        final message = result['message'] ?? '登录失败';
        _showError(message);
      }
    } catch (e) {
      // 出错时重置加载状态
      setState(() {
        _isLoading = false;
      });
      _showError('登录失败: $e');
    }
  }

  // 根据平台和用户选择保存登录配置
  Future<void> _saveCredentials(
    int userId,
    String username,
    String password,
  ) async {
    if (_isDesktop) {
      // PC端：根据用户选择保存配置
      logger.debug('💾 PC端保存登录配置: userId=$userId, rememberPassword=$_rememberPassword, autoLogin=$_autoLogin');
      
      // 保存记住密码和自动登录配置
      await Storage.saveRememberPassword(userId, _rememberPassword);
      await Storage.saveAutoLogin(userId, _autoLogin);
      
      // 如果勾选了记住密码，保存账号密码
      if (_rememberPassword) {
        await Storage.saveSavedAccount(userId, username);
        await Storage.saveSavedPassword(userId, password);
        logger.debug('✅ PC端已保存账号密码');
      } else {
        // 如果没有勾选记住密码，清除之前保存的账号密码
        // 注意：这里只清除账号密码，不清除配置选项本身
        await Storage.saveSavedAccount(userId, '');
        await Storage.saveSavedPassword(userId, '');
        logger.debug('🗑️ PC端已清除账号密码');
      }
      
      logger.debug('✅ PC端登录配置已保存');
    } else {
      // 移动端：自动保存账号密码和登录配置（简化逻辑）
      logger.debug('💾 移动端自动保存登录配置: userId=$userId, username=$username');
      
      // 自动启用记住密码和自动登录
      await Storage.saveRememberPassword(userId, true);
      await Storage.saveAutoLogin(userId, true);
      
      // 保存账号密码
      await Storage.saveSavedAccount(userId, username);
      await Storage.saveSavedPassword(userId, password);
      
      logger.debug('✅ 移动端登录配置已自动保存（记住密码: true, 自动登录: true）');
    }
  }

  // 处理验证码登录
  Future<void> _handleVerifyCodeLogin() async {
    final account = _phoneController.text.trim();
    final code = _verifyCodeController.text.trim();

    // 验证手机号格式
    if (!_isValidPhoneNumber(account)) {
      _showError('请输入正确的手机号格式');
      return;
    }

    // 验证验证码格式
    if (!_isValidVerifyCode(code)) {
      _showError('验证码必须是6位数字');
      return;
    }

    // 设置加载状态
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.verifyCodeLogin(
        account: account,
        code: code,
      );

      if (result['code'] == 0) {
        // 登录成功
        final token = result['data']['token'];
        final user = result['data']['user'];

        // 保存token和用户信息
        await Storage.saveLoginInfo(
          token: token,
          userId: user['id'],
          username: user['username'],
          fullName: user['full_name'],
          avatar: user['avatar'],
        );

        // 重新初始化日志系统（使用用户ID）
        await logger.init(userId: user['id'].toString());
        logger.info('📝 日志系统已重新初始化，用户ID: ${user['id']}');

        // 验证码登录：保存手机号但不保存验证码（验证码是一次性的）
        if (_isDesktop) {
          // PC端：根据用户选择保存配置
          await Storage.saveRememberPassword(user['id'], _rememberPassword);
          await Storage.saveAutoLogin(user['id'], _autoLogin);
          
          if (_rememberPassword) {
            await Storage.saveSavedAccount(user['id'], account);
            logger.debug('✅ PC端验证码登录：已保存手机号');
          }
          await Storage.saveSavedPassword(user['id'], ''); // 清空密码字段
        } else {
          // 移动端：自动保存配置
          await Storage.saveRememberPassword(user['id'], true);
          await Storage.saveAutoLogin(user['id'], true);
          await Storage.saveSavedAccount(user['id'], account);
          await Storage.saveSavedPassword(user['id'], ''); // 清空密码字段
          logger.debug('✅ 移动端验证码登录：登录配置已自动保存（记住密码: true, 自动登录: true）');
        }

        // 注意：用户状态已在后端登录接口中自动设置为 online，无需前端再次设置
        logger.debug('✅ 用户登录成功，状态: ${user['status']}');

        // 🔴 登录成功后清除所有本地缓存
        logger.info('🗑️ 验证码登录成功，开始清除所有本地缓存...');
        MobileChatPage.clearAllCache();
        MobileContactsPage.clearAllCache();
        MobileHomePage.clearAllCache();
        logger.info('✅ 所有本地缓存已清除，即将重新加载数据');

        _showSuccess('登录成功');

        // 跳转到主页
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // 登录失败，重置加载状态
        setState(() {
          _isLoading = false;
        });

        // 显示错误消息（服务器会自动踢掉已登录的设备，不需要特殊处理）
        final message = result['message'] ?? '登录失败';
        _showError(message);
      }
    } catch (e) {
      // 出错时重置加载状态
      setState(() {
        _isLoading = false;
      });
      _showError('登录失败: $e');
    }
  }

  // 验证手机号格式
  bool _isValidPhoneNumber(String phone) {
    // 中国大陆手机号：1开头，第二位是3-9，共11位数字
    final RegExp phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // 验证验证码格式
  bool _isValidVerifyCode(String code) {
    // 验证码必须是6位纯数字
    final RegExp codeRegex = RegExp(r'^\d{6}$');
    return codeRegex.hasMatch(code);
  }

  // 发送验证码
  Future<void> _sendVerifyCode() async {
    logger.debug('=== 开始发送验证码 ===');
    // 如果正在倒计时，不处理
    if (_isCountingDown) {
      logger.debug('倒计时中，忽略点击');
      return;
    }

    final phone = _phoneController.text.trim();
    logger.debug('手机号/账号: $phone');

    if (phone.isEmpty) {
      _showError('请输入手机号');
      return;
    }

    // 验证手机号格式
    if (!_isValidPhoneNumber(phone)) {
      _showError('请输入正确的手机号格式');
      return;
    }

    try {
      logger.debug('调用API发送验证码...');
      final result = await ApiService.sendVerifyCode(
        account: phone,
        type: 'login',
      );

      logger.debug('API返回结果: $result');

      if (result['code'] == 0) {
        _showSuccess('验证码已发送');
        // 开发环境下服务器会返回验证码
        if (result['data'] != null && result['data']['code'] != null) {
          logger.debug('✅ 验证码: ${result['data']['code']}');
        }

        // 启动倒计时
        logger.debug('启动倒计时...');
        _startCountdown();
      } else {
        logger.debug('❌ 发送失败: ${result['message']}');
        _showError(result['message'] ?? '发送失败');
      }
    } catch (e) {
      logger.debug('❌ 发送验证码异常: $e');
      _showError('发送验证码失败: $e');
    }
  }

  // 启动倒计时
  void _startCountdown() {
    setState(() {
      _countdown = 120;
      _isCountingDown = true;
    });

    // 开始倒计时
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        setState(() {
          _isCountingDown = false;
        });
        return false;
      }
      return true;
    });
  }

  // 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 显示成功提示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  void dispose() {
    _accountController.removeListener(_checkCanLogin);
    _passwordController.removeListener(_checkCanLogin);
    _accountController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/登录/背景图.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(child: _buildLoginForm()),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 400,
      height: 550,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部区域 - logo左对齐，语言设置右对齐
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 30,
                right: 30,
                bottom: 35,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/登录/登录顶部图片.svg',
                    width: 120,
                    height: 32,
                  ),
                  _buildLanguageDropdown(),
                ],
              ),
            ),
            // 表单内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _buildAccountLoginForm(),
            ),
          ],
        ),
      ),
    );
  }

  // 账号登录表单
  Widget _buildAccountLoginForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        // 账号输入框（支持用户名或邮箱）
        _buildInputField(
          label: l10n.translate('account'),
          controller: _accountController,
          hintText: '请输入用户名/手机号/邮箱',
        ),
        const SizedBox(height: 20),
        // 密码输入框
        _buildPasswordField(),
        const SizedBox(height: 20),
        // 只在PC端显示"记住密码"和"下次自动登录"选项
        if (_isDesktop) ...[
          _buildCheckboxRow(),
          const SizedBox(height: 48),
        ] else ...[
          const SizedBox(height: 68), // 移动端增加间距
        ],
        // 登录按钮
        _buildLoginButton(),
        const SizedBox(height: 20),
        // 忘记密码
        _buildForgotPassword(),
        const SizedBox(height: 38),
      ],
    );
  }

  // 验证码登录表单
  Widget _buildVerifyCodeLoginForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 手机号输入框
        _buildInputField(
          label: l10n.translate('phone_number'),
          controller: _phoneController,
          hintText: l10n.translate('phone_number'),
        ),
        const SizedBox(height: 20),
        // 验证码输入框
        _buildVerifyCodeField(),
        const SizedBox(height: 68), // 移除复选框后增加间距
        // 移动端不再显示"下次自动登录"选项
        // _buildAutoLoginCheckbox(),
        // const SizedBox(height: 48),
        // 登录按钮
        _buildLoginButton(),
        const SizedBox(height: 20),
        // 忘记密码
        _buildForgotPassword(),
        const SizedBox(height: 38),
      ],
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildTab(l10n.translate('account_login'), 0),
        const SizedBox(width: 40),
        _buildTab(l10n.translate('verify_code_login'), 1),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _checkCanLogin(); // 切换tab时重新检查
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF333333)
                  : const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
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

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('password'), style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textAlignVertical: TextAlignVertical.center,
            onSubmitted: (_) {
              // 按下 Enter 键时，如果可以登录则执行登录
              if (_canLogin) {
                _handleAccountLogin();
              }
            },
            decoration: InputDecoration(
              hintText: l10n.translate('password'),
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
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF999999),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyCodeField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('verify_code'), style: _labelStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _verifyCodeController,
                  textAlignVertical: TextAlignVertical.center,
                  onSubmitted: (_) {
                    // 按下 Enter 键时，如果可以登录则执行登录
                    if (_canLogin) {
                      _handleVerifyCodeLogin();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.translate('verify_code'),
                    hintStyle: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _isCountingDown ? null : _sendVerifyCode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                minimumSize: const Size(0, 42),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                disabledForegroundColor: const Color(0xFF999999),
              ),
              child: Text(
                _isCountingDown 
                    ? '$_countdown${l10n.translate('resend_after')}' 
                    : l10n.translate('get_verify_code'),
                style: TextStyle(
                  fontSize: 14,
                  color: _isCountingDown
                      ? const Color(0xFF999999)
                      : const Color(0xFF4A90E2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // PC端复选框相关的UI组件
  Widget _buildCheckboxRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAutoLoginCheckbox(),
        _buildRememberPasswordCheckbox(),
      ],
    );
  }

  Widget _buildRememberPasswordCheckbox() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _rememberPassword,
            onChanged: (value) {
              setState(() {
                _rememberPassword = value ?? false;
                // 如果取消记住密码，也要取消自动登录
                if (!_rememberPassword) {
                  _autoLogin = false;
                }
              });
            },
            activeColor: const Color(0xFF4A90E2),
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberPassword = !_rememberPassword;
              // 如果取消记住密码，也要取消自动登录
              if (!_rememberPassword) {
                _autoLogin = false;
              }
            });
          },
          child: Text(
            l10n.translate('remember_password'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoLoginCheckbox() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _autoLogin,
            onChanged: _rememberPassword ? (value) {
              setState(() {
                _autoLogin = value ?? false;
              });
            } : null, // 只有记住密码时才能勾选自动登录
            activeColor: const Color(0xFF4A90E2),
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _rememberPassword ? () {
            setState(() {
              _autoLogin = !_autoLogin;
            });
          } : null,
          child: Text(
            l10n.translate('auto_login_next_time'),
            style: TextStyle(
              fontSize: 14,
              color: _rememberPassword ? const Color(0xFF666666) : const Color(0xFFCCCCCC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordPage(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.translate('forgot_password_question'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ),
        const SizedBox(width: 20),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.translate('go_to_register'),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4A90E2),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF4A90E2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: (_canLogin && !_isLoading)
            ? () {
                if (_selectedTabIndex == 0) {
                  _handleAccountLogin();
                } else {
                  _handleVerifyCodeLogin();
                }
              }
            : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE5E5E5);
            }
            // 加载状态时显示较深的灰色
            if (_isLoading) {
              return const Color(0xFF9E9E9E);
            }
            return const Color(0xFF4A90E2);
          }),
          foregroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          elevation: WidgetStateProperty.all(0),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.translate('login')}...',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : Text(
                l10n.translate('login'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      tooltip: '',
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
      ),
      padding: EdgeInsets.zero,
      onSelected: (String value) {
        setState(() {
          _selectedLanguage = value;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: '简体中文',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: const Text('简体中文', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'English',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: const Text('English', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: '繁體中文',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: const Text('繁體中文', style: TextStyle(fontSize: 14)),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/登录/语言设置.svg', width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              _selectedLanguage,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF666666),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
