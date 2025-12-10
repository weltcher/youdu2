import 'package:flutter/material.dart';
import 'package:youdu/services/api_service.dart';
import 'package:youdu/models/user_model.dart';
import 'user_profile_menu.dart';

/// 个人信息弹窗菜单（带API集成）
class UserProfileMenuWithAPI {
  /// 显示个人信息菜单并加载用户数据
  static void show(
    BuildContext context, {
    required String token, // 从调用方传入token，避免从Storage读取被其他窗口覆盖的token
    Offset? offset,
    Function(String)? onStatusChanged,
    VoidCallback? onProfileUpdated,
    VoidCallback? onFileAssistantTap,
  }) async {
    try {
      // 验证token
      if (token.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先登录')));
        return;
      }

      // 显示加载中的提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 调用API获取用户信息
      final response = await ApiService.getUserProfile(token: token);

      // 关闭加载提示
      if (context.mounted) Navigator.pop(context);

      if (response['code'] == 0 && response['data'] != null) {
        final userData = response['data']['user'];
        final user = UserModel.fromJson(userData);

        // 更新初始状态
        onStatusChanged?.call(user.status);

        // 打开个人信息菜单弹窗
        if (context.mounted) {
          UserProfileMenu.show(
            context,
            username: user.username,
            userId: user.id.toString(),
            organization: user.department ?? '智码科技',
            token: token, // 传递token，避免从Storage读取被其他窗口覆盖的token
            status: user.status,
            fullName: user.fullName,
            gender: user.gender,
            workSignature: user.workSignature,
            phone: user.phone,
            landline: user.landline,
            shortNumber: user.shortNumber,
            email: user.email,
            department: user.department,
            position: user.position,
            region: user.region,
            avatar: user.avatar,
            inviteCode: user.inviteCode, // 传递邀请码
            offset: offset,
            onStatusChanged: onStatusChanged,
            onProfileUpdated: onProfileUpdated,
            onFileAssistantTap: onFileAssistantTap,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '获取用户信息失败')),
          );
        }
      }
    } catch (e) {
      // 关闭加载提示
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取用户信息失败: $e')));
      }
    }
  }
}
