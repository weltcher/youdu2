import '../utils/timezone_helper.dart';

/// 群组模型
class GroupModel {
  final int id;
  final String name;
  final String? announcement;
  final String? remark;
  final String? nickname;
  final String? avatar;
  final int ownerId;
  final bool allMuted;
  final bool adminOnlyEditName; // 是否仅群主/管理员可修改群名称
  final bool memberViewPermission; // 群成员查看权限（true表示普通成员可以查看其他成员信息，false表示不可以）
  final bool inviteConfirmation; // 群聊邀请确认（true表示普通成员添加新成员需要群主/管理员审核）
  final bool doNotDisturb; // 消息免打扰（true表示只显示红点，false表示显示未读数量）
  final List<int> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.announcement,
    this.remark,
    this.nickname,
    this.avatar,
    required this.ownerId,
    this.allMuted = false,
    this.adminOnlyEditName = false,
    this.memberViewPermission = true,
    this.inviteConfirmation = false,
    this.doNotDisturb = false,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建模型
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      announcement: json['announcement'] as String?,
      remark: json['remark'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      ownerId: json['owner_id'] as int,
      allMuted: json['all_muted'] as bool? ?? false,
      adminOnlyEditName: json['admin_only_edit_name'] as bool? ?? false,
      memberViewPermission: json['member_view_permission'] as bool? ?? true,
      inviteConfirmation: json['invite_confirmation'] as bool? ?? false,
      doNotDisturb: json['do_not_disturb'] as bool? ?? false,
      memberIds:
          (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: TimezoneHelper.parseToShanghaiTime(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? TimezoneHelper.parseToShanghaiTime(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'announcement': announcement,
      'remark': remark,
      'nickname': nickname,
      'avatar': avatar,
      'owner_id': ownerId,
      'all_muted': allMuted,
      'admin_only_edit_name': adminOnlyEditName,
      'member_view_permission': memberViewPermission,
      'invite_confirmation': inviteConfirmation,
      'do_not_disturb': doNotDisturb,
      'member_ids': memberIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 创建一个新的实例，可以修改某些字段
  GroupModel copyWith({
    int? id,
    String? name,
    String? announcement,
    String? remark,
    String? nickname,
    String? avatar,
    int? ownerId,
    bool? allMuted,
    bool? adminOnlyEditName,
    bool? memberViewPermission,
    bool? inviteConfirmation,
    bool? doNotDisturb,
    List<int>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      announcement: announcement ?? this.announcement,
      remark: remark ?? this.remark,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      ownerId: ownerId ?? this.ownerId,
      allMuted: allMuted ?? this.allMuted,
      adminOnlyEditName: adminOnlyEditName ?? this.adminOnlyEditName,
      memberViewPermission: memberViewPermission ?? this.memberViewPermission,
      inviteConfirmation: inviteConfirmation ?? this.inviteConfirmation,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取群组成员数量
  int get memberCount => memberIds.length;

  /// 获取头像占位文本（名字最后两个字符）
  String get avatarText {
    if (name.isNotEmpty && name.length >= 2) {
      return name.substring(name.length - 2);
    }
    return name.isNotEmpty ? name : '群';
  }
}
