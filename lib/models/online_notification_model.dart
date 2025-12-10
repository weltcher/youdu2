import '../utils/timezone_helper.dart';

/// 上线提醒模型
class OnlineNotificationModel {
  final int userId; // 上线用户的ID
  final String username; // 用户名
  final String? fullName; // 全名
  final String? avatar; // 头像URL
  final DateTime onlineTime; // 上线时间

  OnlineNotificationModel({
    required this.userId,
    required this.username,
    this.fullName,
    this.avatar,
    required this.onlineTime,
  });

  /// 从JSON创建
  factory OnlineNotificationModel.fromJson(Map<String, dynamic> json) {
    return OnlineNotificationModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String?,
      onlineTime: json['online_time'] is String
          ? TimezoneHelper.parseToShanghaiTime(json['online_time'] as String)
          : DateTime.fromMillisecondsSinceEpoch(
              (json['online_time'] as int) * 1000,
            ),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'avatar': avatar,
      'online_time': onlineTime.toIso8601String(),
    };
  }

  /// 获取显示名称
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return username;
  }

  /// 获取头像文字（取名字的前两个字符）
  String get avatarText {
    final name = displayName;
    if (name.length >= 2) {
      return name.substring(0, 2);
    }
    return name;
  }

  /// 格式化上线时间
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(onlineTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${onlineTime.month}-${onlineTime.day} ${onlineTime.hour.toString().padLeft(2, '0')}:${onlineTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
