import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youdu/services/api_service.dart';
import '../constants/upload_limits.dart';
import '../utils/logger.dart';

// 全局变量：跟踪文件选择器状态（供 HomePage 访问）
bool isFilePickerOpen = false;
DateTime? filePickerOpenTime;

// Getter 函数：获取文件选择器状态
bool getFilePickerOpen() => isFilePickerOpen;
DateTime? getFilePickerOpenTime() => filePickerOpenTime;

/// 编辑个人资料弹窗
class EditProfileDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String token; // 添加token参数，避免从Storage读取被其他窗口覆盖的token
  final String? fullName;
  final String? gender;
  final String? phone;
  final String? landline;
  final String? shortNumber;
  final String? email;
  final String? department;
  final String? position;
  final String? region;
  final String? avatar;
  final String? inviteCode; // 用户邀请码
  final Function(Map<String, dynamic>)? onSave;

  const EditProfileDialog({
    super.key,
    required this.username,
    required this.userId,
    required this.token, // token必须传入
    this.fullName,
    this.gender,
    this.phone,
    this.landline,
    this.shortNumber,
    this.email,
    this.department,
    this.position,
    this.region,
    this.avatar,
    this.inviteCode, // 用户邀请码
    this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();

  /// 显示编辑个人资料弹窗
  static void show(
    BuildContext context, {
    required String username,
    required String userId,
    required String token, // token必须传入
    String? fullName,
    String? gender,
    String? phone,
    String? landline,
    String? shortNumber,
    String? email,
    String? department,
    String? position,
    String? region,
    String? avatar,
    String? inviteCode, // 用户邀请码
    Function(Map<String, dynamic>)? onSave,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 防止点击外部区域关闭弹窗
      useRootNavigator: false, // 使用当前navigator，避免文件选择器影响
      builder: (context) => EditProfileDialog(
        username: username,
        userId: userId,
        token: token, // 传递token
        fullName: fullName,
        gender: gender,
        phone: phone,
        landline: landline,
        shortNumber: shortNumber,
        email: email,
        department: department,
        position: position,
        region: region,
        avatar: avatar,
        inviteCode: inviteCode, // 传递邀请码
        onSave: onSave,
      ),
    );
  }
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _landlineController;
  late TextEditingController _shortNumberController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _regionController;

  String _selectedGender = 'male';
  String? _avatarUrl;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phone);
    _landlineController = TextEditingController(text: widget.landline);
    _shortNumberController = TextEditingController(text: widget.shortNumber);
    _emailController = TextEditingController(text: widget.email);
    _departmentController = TextEditingController(text: widget.department);
    _positionController = TextEditingController(text: widget.position);
    _regionController = TextEditingController(text: widget.region);
    _selectedGender = widget.gender ?? 'male';
    _avatarUrl = widget.avatar;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _landlineController.dispose();
    _shortNumberController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            _buildHeader(),
            const SizedBox(height: 24),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧头像区域
                    _buildAvatarSection(),
                    const SizedBox(width: 32),
                    // 右侧表单区域
                    Expanded(child: _buildFormSection()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 底部按钮
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // 标题
  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '编辑个人资料',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF666666)),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // 头像区域
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _avatarUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            ),
                          )
                        : _buildDefaultAvatar()),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isUploading
              ? null
              : () {
                  logger.debug('📸 [头像更换] 点击"更改头像"按钮');
                  logger.debug('📸 [头像更换] 点击时 mounted 状态: $mounted');
                  _pickAndUploadImage();
                },
          child: Text(
            _isUploading ? '上传中...' : '更改头像',
            style: TextStyle(
              fontSize: 12,
              color: _isUploading ? Colors.grey : const Color(0xFF4A90E2),
            ),
          ),
        ),
      ],
    );
  }

  // 默认头像
  Widget _buildDefaultAvatar() {
    return Text(
      widget.username.length >= 2
          ? widget.username.substring(0, 2)
          : widget.username,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // 选择并上传图片
  Future<void> _pickAndUploadImage() async {
    try {
      logger.debug('📸 [头像更换] 开始选择图片...');
      logger.debug('📸 [头像更换] 当前 mounted 状态: $mounted');
      logger.debug('📸 [头像更换] 当前 context: $context');

      // 保存当前context，防止文件选择器影响Dialog
      final dialogContext = context;
      logger.debug('📸 [头像更换] 保存的 dialogContext: $dialogContext');

      // 检查Dialog是否仍然存在（在打开文件选择器前）
      if (!mounted) {
        logger.debug('❌ [头像更换] Dialog已关闭（打开文件选择器前），取消上传');
        return;
      }

      logger.debug('📸 [头像更换] 准备打开文件选择器...');

      // 设置全局变量：文件选择器正在打开
      isFilePickerOpen = true;
      filePickerOpenTime = null; // 打开时清除关闭时间
      logger.debug('📸 [头像更换] 已设置全局变量：文件选择器打开');

      // 选择图片文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false, // 禁用自动压缩，避免权限问题
        allowCompression: false, // 禁用压缩
      );

      logger.debug('📸 [头像更换] 文件选择器返回');

      // 设置全局变量：文件选择器已关闭
      isFilePickerOpen = false;
      filePickerOpenTime = DateTime.now(); // 关闭时记录时间
      logger.debug('📸 [头像更换] 已设置全局变量：文件选择器关闭');
      logger.debug('📸 [头像更换] 文件选择器返回后 mounted 状态: $mounted');
      logger.debug('📸 [头像更换] 文件选择器返回后 context: $context');
      logger.debug('📸 [头像更换] 文件选择器返回后 dialogContext: $dialogContext');

      // 检查Dialog是否仍然存在
      if (!mounted) {
        logger.debug('❌ [头像更换] Dialog已关闭（文件选择器返回后），取消上传');
        logger.debug('❌ [头像更换] 可能原因：文件选择器关闭了Dialog');
        return;
      }

      if (result == null || result.files.isEmpty) {
        logger.debug('�?用户取消选择图片');
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        logger.debug('�?文件路径为空');
        return;
      }

      logger.debug('📸 [头像更换] 已选择图片: $filePath');
      logger.debug('📸 [头像更换] 准备调用 setState，当前 mounted 状态: $mounted');

      if (!mounted) {
        logger.debug('❌ [头像更换] 在 setState 前 Dialog 已关闭');
        return;
      }

      setState(() {
        logger.debug('📸 [头像更换] setState 内部执行');
        _selectedImage = File(filePath);
        _isUploading = true;
      });

      logger.debug('📸 [头像更换] setState 执行完成，当前 mounted 状态: $mounted');

      // 使用widget中的token，避免从Storage读取被其他窗口覆盖的token
      final token = widget.token;
      if (token.isEmpty) {
        logger.debug('❌ [头像更换] Token为空，请先登录');
        logger.debug('❌ [头像更换] Token为空时 mounted 状态: $mounted');
        if (mounted) {
          ScaffoldMessenger.of(
            dialogContext,
          ).showSnackBar(const SnackBar(content: Text('请先登录')));
        }
        setState(() {
          _isUploading = false;
          _selectedImage = null;
        });
        return;
      }

      logger.debug('🚀 [头像更换] 开始上传头像到OSS...');
      logger.debug('🚀 [头像更换] 上传前 mounted 状态: $mounted');
      // 上传头像到OSS
      final fileSize = await File(filePath).length();
      if (fileSize > kMaxImageUploadBytes) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('头像大小不能超过32MB')),
          );
        }
        setState(() {
          _isUploading = false;
          _selectedImage = null;
        });
        return;
      }

      final response = await ApiService.uploadAvatar(
        token: token,
        filePath: filePath,
      );

      logger.debug('📦 [头像更换] 上传响应: $response');
      logger.debug('📦 [头像更换] 上传完成后 mounted 状态: $mounted');

      if (response['code'] == 0) {
        final uploadedUrl = response['data']['url'];
        logger.debug('✅ [头像更换] 图片上传成功');
        logger.debug('✅ [头像更换] URL: $uploadedUrl');
        logger.debug('✅ [头像更换] 上传成功后 mounted 状态: $mounted');

        if (!mounted) {
          logger.debug('❌ [头像更换] 上传成功后 Dialog 已关闭');
          return;
        }

        // 立即保存头像到服务器
        logger.debug('💾 [头像更换] 开始保存头像到服务器...');
        logger.debug('💾 [头像更换] 保存前 mounted 状态: $mounted');
        try {
          final saveResponse = await ApiService.updateUserProfile(
            token: token,
            avatar: uploadedUrl,
          );

          logger.debug('📦 [头像更换] 保存头像响应: $saveResponse');
          logger.debug('📦 [头像更换] 保存响应后 mounted 状态: $mounted');

          if (saveResponse['code'] == 0) {
            logger.debug('✅ [头像更换] 头像保存成功');
            logger.debug('✅ [头像更换] 保存成功后准备调用 setState，mounted 状态: $mounted');

            if (!mounted) {
              logger.debug('❌ [头像更换] 保存成功后 Dialog 已关闭，无法更新UI');
              return;
            }

            setState(() {
              logger.debug('✅ [头像更换] setState 内部执行（保存成功后）');
              _avatarUrl = uploadedUrl;
              _isUploading = false;
              _selectedImage = null; // 清除本地图片，使用网络图片
            });

            logger.debug('✅ [头像更换] setState 执行完成（保存成功后），mounted 状态: $mounted');

            // 通知主页面更新头像
            logger.debug('📸 [头像更换] 准备调用 onSave 回调');
            logger.debug('📸 [头像更换] 调用 onSave 前 mounted 状态: $mounted');

            try {
              widget.onSave?.call({'avatar': uploadedUrl});
              logger.debug('📸 [头像更换] onSave 回调调用完成');
            } catch (e, stackTrace) {
              logger.debug('❌ [头像更换] onSave 回调调用异常: $e');
              logger.debug('❌ [头像更换] 异常堆栈: $stackTrace');
            }

            logger.debug('📸 [头像更换] onSave 回调后 mounted 状态: $mounted');

            if (!mounted) {
              logger.debug('❌ [头像更换] onSave 回调后 Dialog 已关闭');
              return;
            }

            if (mounted) {
              logger.debug('📸 [头像更换] 准备显示成功提示');
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('头像更换成功！'),
                  duration: Duration(seconds: 2),
                ),
              );
              logger.debug('📸 [头像更换] 成功提示已显示');
            }
          } else {
            logger.debug('保存头像失败: ${saveResponse['message']}');
            setState(() {
              _avatarUrl = uploadedUrl;
              _isUploading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(saveResponse['message'] ?? '头像保存失败')),
              );
            }
          }
        } catch (e) {
          logger.debug('保存头像异常: $e');
          setState(() {
            _avatarUrl = uploadedUrl;
            _isUploading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(
              dialogContext,
            ).showSnackBar(SnackBar(content: Text('头像保存失败: $e')));
          }
        }
      } else {
        logger.debug('上传失败: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '上传失败')),
          );
        }
        setState(() {
          _isUploading = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
      logger.debug('上传异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
      }
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    }
  }

  // 表单区域
  Widget _buildFormSection() {
    return Column(
      children: [
        _buildInputField('姓名', _fullNameController, '请输入姓名'),
        const SizedBox(height: 16),
        _buildGenderField(),
        const SizedBox(height: 16),
        _buildInputField('账号', null, widget.username, enabled: false),
        const SizedBox(height: 16),
        _buildInputField('手机', _phoneController, '请输入入手机'),
        const SizedBox(height: 16),
        _buildInputField('座机', _landlineController, '请输入入座机'),
        const SizedBox(height: 16),
        _buildInputField('短号', _shortNumberController, '请输入入短号'),
        const SizedBox(height: 16),
        _buildInputField('邮箱', _emailController, '请输入入邮箱'),
        const SizedBox(height: 16),
        _buildInputField('部门', _departmentController, ''),
        const SizedBox(height: 16),
        _buildInputField('职务', _positionController, ''),
        const SizedBox(height: 16),
        _buildInputField('地区', _regionController, '请输入地区'),
      ],
    );
  }

  // 输入框字段
  Widget _buildInputField(
    String label,
    TextEditingController? controller,
    String hintOrValue, {
    bool enabled = true,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: enabled
                ? TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hintOrValue,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFCCCCCC),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      hintOrValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // 性别选择字段
  Widget _buildGenderField() {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text(
            '性别',
            style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Radio<String>(
                value: 'male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                activeColor: const Color(0xFF4A90E2),
              ),
              const Text('男', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 24),
              Radio<String>(
                value: 'female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                activeColor: const Color(0xFF4A90E2),
              ),
              const Text('女', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // 底部按钮
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF666666),
            side: const BorderSide(color: Color(0xFFCCCCCC)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            minimumSize: const Size(100, 40),
          ),
          child: const Text('取消', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            minimumSize: const Size(100, 40),
          ),
          child: const Text('确定', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  // 保存处理
  Future<void> _handleSave() async {
    logger.debug('💾 准备保存用户资料...');
    logger.debug('   当前头像URL: $_avatarUrl');
    logger.debug('   原始头像URL: ${widget.avatar}');

    final email = _emailController.text.trim();
    
    // 如果邮箱有变化且不为空，检查邮箱是否已被其他用户绑定
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

    final data = {
      'full_name': _fullNameController.text.trim(),
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'landline': _landlineController.text.trim(),
      'short_number': _shortNumberController.text.trim(),
      'email': email,
      'department': _departmentController.text.trim(),
      'position': _positionController.text.trim(),
      'region': _regionController.text.trim(),
    };

    // 优先使用新上传的头像URL，如果没有则使用原来
    final avatarToSave = _avatarUrl ?? widget.avatar;
    if (avatarToSave != null && avatarToSave.isNotEmpty) {
      data['avatar'] = avatarToSave;
      logger.debug('已添加头像到保存数据: ${data['avatar']}');
    } else {
      logger.debug('⚠️ 头像URL为空');
    }

    logger.debug('📤 保存的数据: $data');
    Navigator.pop(context);
    widget.onSave?.call(data);
  }
}
