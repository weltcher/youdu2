import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// 移动端个人资料编辑页面
class MobileProfileEditPage extends StatefulWidget {
  final String username;
  final String userId;
  final String token;
  final String? fullName;
  final String? gender;
  final String? phone;
  final String? email;
  final String? department;
  final String? position;
  final String? region;
  final String? avatar;
  final Function(Map<String, dynamic>)? onSave;

  const MobileProfileEditPage({
    super.key,
    required this.username,
    required this.userId,
    required this.token,
    this.fullName,
    this.gender,
    this.phone,
    this.email,
    this.department,
    this.position,
    this.region,
    this.avatar,
    this.onSave,
  });

  @override
  State<MobileProfileEditPage> createState() => _MobileProfileEditPageState();
}

class _MobileProfileEditPageState extends State<MobileProfileEditPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _regionController;

  String _selectedGender = '男';
  File? _selectedImage;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  // 转换性别：英文 -> 中文
  String _convertGenderToChinese(String? englishGender) {
    switch (englishGender?.toLowerCase()) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return '男';
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName ?? '');
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _departmentController = TextEditingController(
      text: widget.department ?? '',
    );
    _positionController = TextEditingController(text: widget.position ?? '');
    _regionController = TextEditingController(text: widget.region ?? '');
    _selectedGender = _convertGenderToChinese(widget.gender);
    _avatarUrl = widget.avatar;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  // 选择头像
  Future<void> _pickImage() async {
    try {
      // 🔐 请求存储权限
      if (Platform.isAndroid) {
        // Android 13+ 使用photos权限，Android 12及以下使用storage权限
        // 尝试请求photos权限（Android 13+）
        var status = await Permission.photos.request();
        
        // 如果photos权限不支持（Android 12及以下），则请求storage权限
        if (status == PermissionStatus.denied && 
            await Permission.storage.status != PermissionStatus.permanentlyDenied) {
          status = await Permission.storage.request();
        }

        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要存储权限才能选择图片')),
            );
          }
          logger.warning('⚠️ 存储权限被拒绝');
          return;
        }
        logger.debug('✅ 存储权限已授予');
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false, // 禁用自动压缩，避免权限问题
        allowCompression: false, // 禁用压缩
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = File(result.files.first.path!);
        });
        await _uploadAvatar();
      }
    } catch (e) {
      logger.error('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('选择图片失败')));
      }
    }
  }

  // 上传头像
  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.uploadAvatar(
        token: widget.token,
        filePath: _selectedImage!.path,
      );

      if (response['code'] == 0) {
        setState(() {
          _avatarUrl = response['data']['url'];
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('头像上传成功')));
        }
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '头像上传失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      logger.error('上传头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('头像上传失败')));
      }
    }
  }

  // 转换性别：中文 -> 英文
  String _convertGenderToEnglish(String chineseGender) {
    switch (chineseGender) {
      case '男':
        return 'male';
      case '女':
        return 'female';
      default:
        return 'male';
    }
  }

  // 校验手机号格式（中国手机号：11位数字，1开头）
  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return true; // 空值不校验
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // 校验邮箱格式
  bool _isValidEmail(String email) {
    if (email.isEmpty) return true; // 空值不校验
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // 保存资料
  Future<void> _saveProfile() async {
    // 📝 校验手机号格式（仅在不为空时校验）
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !_isValidPhoneNumber(phone)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('手机号格式不正确，请输入正确的11位手机号')),
        );
      }
      return;
    }

    // 📧 校验邮箱格式（仅在不为空时校验）
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邮箱格式不正确，请输入正确的邮箱地址')),
        );
      }
      return;
    }

    // 📧 如果邮箱有变化且不为空，检查邮箱是否已被其他用户绑定
    if (email.isNotEmpty && email != widget.email) {
      logger.debug('📧 检查邮箱是否已被绑定: $email');
      try {
        final result = await ApiService.checkEmailAvailability(
          token: widget.token,
          email: email,
        );
        
        if (result['code'] == 0) {
          final available = result['data']['available'] as bool;
          if (!available) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['data']['message'] ?? '该邮箱已被其他用户绑定')),
              );
            }
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? '邮箱验证失败')),
            );
          }
          return;
        }
      } catch (e) {
        logger.debug('❌ 检查邮箱失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('邮箱验证失败: $e')),
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService.updateUserProfile(
        token: widget.token,
        fullName: _fullNameController.text.trim(),
        gender: _convertGenderToEnglish(_selectedGender),
        phone: phone,
        email: email,
        department: _departmentController.text.trim(),
        position: _positionController.text.trim(),
        region: _regionController.text.trim(),
        avatar: _avatarUrl, // 添加头像URL参数
      );

      setState(() {
        _isSaving = false;
      });

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('保存成功')));
          if (widget.onSave != null) {
            widget.onSave!({
              'full_name': _fullNameController.text.trim(),
              'gender': _selectedGender,
              'phone': phone,
              'email': email,
              'department': _departmentController.text.trim(),
              'position': _positionController.text.trim(),
              'region': _regionController.text.trim(),
              'avatar': _avatarUrl,
            });
          }
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '保存失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      logger.error('保存资料失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '编辑个人资料',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 头像区域
            _buildAvatarSection(),
            const SizedBox(height: 32),
            // 表单区域
            _buildFormSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 头像区域
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            // 头像
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            ),
                          )
                        : _buildDefaultAvatar()),
            ),
            // 上传进度
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            // 编辑按钮
            if (!_isUploading)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isUploading ? null : _pickImage,
          child: const Text(
            '更改头像',
            style: TextStyle(color: Color(0xFF4A90E2), fontSize: 14),
          ),
        ),
      ],
    );
  }

  // 默认头像
  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 表单区域
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInputField('姓名', _fullNameController, '请输入姓名'),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          _buildInputField('账号', null, widget.username, enabled: false),
          const SizedBox(height: 16),
          _buildInputField(
            '手机',
            _phoneController,
            '请输入手机号',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            '邮箱',
            _emailController,
            '请输入邮箱',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildInputField('部门', _departmentController, '请输入部门'),
          const SizedBox(height: 16),
          _buildInputField('职务', _positionController, '请输入职务'),
          const SizedBox(height: 16),
          _buildInputField('地区', _regionController, '请输入地区'),
        ],
      ),
    );
  }

  // 输入框
  Widget _buildInputField(
    String label,
    TextEditingController? controller,
    String hint, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType ?? TextInputType.text,
            enableInteractiveSelection: true,
            enableIMEPersonalizedLearning: true,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4A90E2)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 性别选择器
  Widget _buildGenderSelector() {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text(
            '性别',
            style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('男'),
                  value: '男',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('女'),
                  value: '女',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
