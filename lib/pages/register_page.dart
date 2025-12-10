import 'package:flutter/material.dart';
import 'package:youdu/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _canRegister = false;

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
    _accountController.addListener(_checkCanRegister);
    _fullNameController.addListener(_checkCanRegister);
    _passwordController.addListener(_checkCanRegister);
    _confirmPasswordController.addListener(_checkCanRegister);
    _inviteCodeController.addListener(_checkCanRegister);
  }

  void _checkCanRegister() {
    // 注册条件：账号、昵称、密码、确认密码、邀请码都必须填写
    final hasAccount = _accountController.text.trim().isNotEmpty;
    final hasFullName = _fullNameController.text.trim().isNotEmpty;
    final hasPassword = _passwordController.text.trim().isNotEmpty;
    final hasConfirmPassword = _confirmPasswordController.text
        .trim()
        .isNotEmpty;
    final hasInviteCode = _inviteCodeController.text.trim().isNotEmpty;

    final canRegister =
        hasAccount &&
        hasFullName &&
        hasPassword &&
        hasConfirmPassword &&
        hasInviteCode;

    setState(() {
      _canRegister = canRegister;
    });
  }

  // 处理注册
  Future<void> _handleRegister() async {
    final username = _accountController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final inviteCode = _inviteCodeController.text.trim();

    // 验证用户名长度
    if (username.length < 3) {
      _showError('用户名长度至少3个字符');
      return;
    }

    // 验证用户名格式（只能包含英文字母和数字）
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      _showError('用户名只能包含英文字母和数字');
      return;
    }

    // 验证昵称（必填）
    if (fullName.isEmpty) {
      _showError('请输入昵称');
      return;
    }

    // 验证密码长度
    if (password.length < 8) {
      _showError('密码长度至少8位');
      return;
    }

    // 验证密码格式（必须包含字母和数字）
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    if (!hasLetter || !hasDigit) {
      _showError('密码必须包含字母和数字');
      return;
    }

    // 调用注册API
    try {
      final result = await ApiService.register(
        username: username,
        fullName: fullName,
        password: password,
        confirmPassword: confirmPassword,
        inviteCode: inviteCode,
      );

      // 获取错误码
      final code = result['code'];

      if (code == 0) {
        // 注册成功 - 关闭键盘
        FocusScope.of(context).unfocus();
        _showSuccess('注册成功！');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // 显示API返回的错误消息
        final errorMessage = result['message'];
        if (errorMessage != null && errorMessage.toString().isNotEmpty) {
          _showError(errorMessage.toString());
        } else {
          // 如果没有错误消息，显示错误码
          _showError('注册失败：错误码 $code');
        }
      }
    } catch (e) {
      // 捕获所有异常并显示详细错误信息
      _showError('注册失败：${e.toString()}');
    }
  }

  // 显示错误提示
  void _showError(String message) {
    // 关闭键盘，确保用户能看到错误提示
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _accountController.removeListener(_checkCanRegister);
    _fullNameController.removeListener(_checkCanRegister);
    _passwordController.removeListener(_checkCanRegister);
    _confirmPasswordController.removeListener(_checkCanRegister);
    _inviteCodeController.removeListener(_checkCanRegister);
    _accountController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          Image.asset('assets/登录/背景图.png', fit: BoxFit.cover),
          // 内容区域
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: 40,
                    bottom: 40 + keyboardHeight,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 80,
                    ),
                    child: Center(child: _buildRegisterForm()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              '注册账号',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 35),
            // 账号输入框
            _buildInputField(
              label: '账号',
              controller: _accountController,
              hintText: '请输入账号',
            ),
            const SizedBox(height: 24),
            // 昵称输入框
            _buildInputField(
              label: '昵称',
              controller: _fullNameController,
              hintText: '请输入昵称',
            ),
            const SizedBox(height: 24),
            // 密码输入框
            _buildPasswordField(),
            const SizedBox(height: 24),
            // 确认密码输入框
            _buildConfirmPasswordField(),
            const SizedBox(height: 24),
            // 邀请码输入框
            _buildInputField(
              label: '邀请码',
              controller: _inviteCodeController,
              hintText: '请输入邀请码',
            ),
            const SizedBox(height: 40),
            // 注册按钮
            _buildRegisterButton(),
            const SizedBox(height: 16),
            // 返回按钮
            _buildBackButton(),
          ],
        ),
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
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('密码', style: _labelStyle),
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
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '请输入密码',
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

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('确认密码', style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '请再次输入密码',
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
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: const Color(0xFF999999),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _canRegister ? _handleRegister : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE5E5E5);
            }
            return const Color(0xFF4A90E2);
          }),
          foregroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          elevation: WidgetStateProperty.all(0),
        ),
        child: const Text(
          '注册',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          '返回',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
