import '../utils/timezone_helper.dart';

/// 用户模型
class UserModel {
  final int id;
  final String username;
  final String? email;
  final String avatar;
  final String? authCode;
  final String? fullName;
  final String? gender;
  final String? workSignature;
  final String status;
  final String? landline;
  final String? shortNumber;
  final String? department;
  final String? position;
  final String? region;
  final String? inviteCode; // 用户邀请码
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.avatar,
    this.authCode,
    this.fullName,
    this.gender,
    this.workSignature,
    required this.status,
    this.landline,
    this.shortNumber,
    this.department,
    this.position,
    this.region,
    this.inviteCode, // 用户邀请码
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从JSON创建用户模型
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String? ?? '',
      authCode: json['auth_code'] as String?,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      workSignature: json['work_signature'] as String?,
      status: json['status'] as String? ?? 'online',
      landline: json['landline'] as String?,
      shortNumber: json['short_number'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      region: json['region'] as String?,
      inviteCode: json['invite_code'] as String?, // 从 JSON 中解析邀请码
      createdAt: TimezoneHelper.parseToShanghaiTime(json['created_at'] as String),
      updatedAt: TimezoneHelper.parseToShanghaiTime(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'auth_code': authCode,
      'full_name': fullName,
      'gender': gender,
      'work_signature': workSignature,
      'status': status,
      'landline': landline,
      'short_number': shortNumber,
      'department': department,
      'position': position,
      'region': region,
      'invite_code': inviteCode, // 转换为 JSON
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新字段
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? avatar,
    String? authCode,
    String? fullName,
    String? gender,
    String? workSignature,
    String? status,
    String? landline,
    String? shortNumber,
    String? department,
    String? position,
    String? region,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      authCode: authCode ?? this.authCode,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      workSignature: workSignature ?? this.workSignature,
      status: status ?? this.status,
      landline: landline ?? this.landline,
      shortNumber: shortNumber ?? this.shortNumber,
      department: department ?? this.department,
      position: position ?? this.position,
      region: region ?? this.region,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
