import '../utils/timezone_helper.dart';

/// 常用联系人详情模型
class FavoriteContactDetail {
  final int id;
  final int contactId;
  final String username;
  final String? fullName;
  final String avatar;
  final String? workSignature;
  final String status;
  final String? department;
  final String? position;
  final String? phone;
  final String? email;
  final DateTime createdAt;

  FavoriteContactDetail({
    required this.id,
    required this.contactId,
    required this.username,
    this.fullName,
    required this.avatar,
    this.workSignature,
    required this.status,
    this.department,
    this.position,
    this.phone,
    this.email,
    required this.createdAt,
  });

  /// 从 JSON 创建模型
  factory FavoriteContactDetail.fromJson(Map<String, dynamic> json) {
    return FavoriteContactDetail(
      id: json['id'] as int,
      contactId: json['contact_id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String? ?? '',
      workSignature: json['work_signature'] as String?,
      status: json['status'] as String? ?? 'offline',
      department: json['department'] as String?,
      position: json['position'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: TimezoneHelper.parseToShanghaiTime(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contactId,
      'username': username,
      'full_name': fullName,
      'avatar': avatar,
      'work_signature': workSignature,
      'status': status,
      'department': department,
      'position': position,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 获取显示名称
  String get displayName => fullName ?? username;

  /// 获取头像文本
  String get avatarText {
    final name = displayName;
    if (name.length >= 2) {
      return name.substring(name.length - 2);
    }
    return name;
  }

  /// 是否在线
  bool get isOnline => status == 'online';
}

/// 常用群组详情模型
class FavoriteGroupDetail {
  final int id;
  final int groupId;
  final String name;
  final String? announcement;
  final String? avatar;
  final int ownerId;
  final int memberCount;
  final DateTime createdAt;

  FavoriteGroupDetail({
    required this.id,
    required this.groupId,
    required this.name,
    this.announcement,
    this.avatar,
    required this.ownerId,
    required this.memberCount,
    required this.createdAt,
  });

  /// 从 JSON 创建模型
  factory FavoriteGroupDetail.fromJson(Map<String, dynamic> json) {
    return FavoriteGroupDetail(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      name: json['name'] as String,
      announcement: json['announcement'] as String?,
      avatar: json['avatar'] as String?,
      ownerId: json['owner_id'] as int,
      memberCount: json['member_count'] as int,
      createdAt: TimezoneHelper.parseToShanghaiTime(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'announcement': announcement,
      'avatar': avatar,
      'owner_id': ownerId,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 获取群组头像文本
  String get avatarText {
    if (name.length >= 2) {
      return name.substring(name.length - 2);
    }
    return name;
  }
}
