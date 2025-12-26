import '../utils/timezone_helper.dart';
import '../utils/logger.dart';

/// 联系人模型
class ContactModel {
  final int relationId;
  final int userId; // 发起方的用户ID
  final int friendId;
  final String username;
  final String? fullName;
  final String avatar;
  final String? workSignature;
  final String status;
  final String? phone;
  final String? email;
  final String? department;
  final String? position;
  final DateTime createdAt;
  final String
  approvalStatus; // 审核状态: pending(待审核), approved(已通过), rejected(已拒绝)
  final bool isBlocked; // 是否被拉黑（关系是否被拉黑）
  final int? blockedByUserId; // 拉黑操作人ID
  final bool isBlockedByMe; // 当前用户是否拉黑了对方
  final bool isDeleted; // 是否被删除
  final int? deletedByUserId; // 删除操作人ID

  ContactModel({
    required this.relationId,
    required this.userId,
    required this.friendId,
    required this.username,
    this.fullName,
    required this.avatar,
    this.workSignature,
    required this.status,
    this.phone,
    this.email,
    this.department,
    this.position,
    required this.createdAt,
    this.approvalStatus = 'approved', // 默认为已通过
    this.isBlocked = false, // 默认为未拉黑
    this.blockedByUserId, // 拉黑操作人ID
    this.isBlockedByMe = false, // 默认为未拉黑对方
    this.isDeleted = false, // 默认为未删除
    this.deletedByUserId, // 删除操作人ID
  });

  /// 从 JSON 创建模型
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    
    // 记录好友关系的原始数据（特别是已通过的好友请求）
    final approvalStatus = json['approval_status']?.toString() ?? 'approved';
    
    return ContactModel(
      relationId: json['relation_id'] is int
          ? json['relation_id'] as int
          : int.tryParse(json['relation_id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      friendId: json['friend_id'] is int
          ? json['friend_id'] as int
          : int.tryParse(json['friend_id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      avatar: json['avatar']?.toString() ?? '',
      workSignature: json['work_signature']?.toString(),
      status: json['status']?.toString() ?? 'offline',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      department: json['department']?.toString(),
      position: json['position']?.toString(),
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? TimezoneHelper.parseToShanghaiTime(json['created_at'].toString())
          : DateTime.now(),
      approvalStatus: approvalStatus,
      isBlocked: json['is_blocked'] == true || json['is_blocked']?.toString() == 'true',
      blockedByUserId: json['blocked_by_user_id'] is int 
          ? json['blocked_by_user_id'] as int
          : int.tryParse(json['blocked_by_user_id']?.toString() ?? ''),
      isBlockedByMe: json['is_blocked_by_me'] == true || json['is_blocked_by_me']?.toString() == 'true',
      isDeleted: json['is_deleted'] == true || json['is_deleted']?.toString() == 'true',
      deletedByUserId: json['deleted_by_user_id'] is int 
          ? json['deleted_by_user_id'] as int
          : int.tryParse(json['deleted_by_user_id']?.toString() ?? ''),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'relation_id': relationId,
      'user_id': userId,
      'friend_id': friendId,
      'username': username,
      'full_name': fullName,
      'avatar': avatar,
      'work_signature': workSignature,
      'status': status,
      'phone': phone,
      'email': email,
      'department': department,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'approval_status': approvalStatus,
      'is_blocked': isBlocked,
      'blocked_by_user_id': blockedByUserId,
      'is_blocked_by_me': isBlockedByMe,
      'is_deleted': isDeleted,
      'deleted_by_user_id': deletedByUserId,
    };
  }

  /// 获取显示名称（优先使用 fullName，否则使用 username）
  String get displayName => fullName ?? username;

  /// 获取头像文本（取名字的最后两个字符）
  String get avatarText {
    final name = displayName;
    if (name.length >= 2) {
      return name.substring(name.length - 2);
    }
    return name;
  }

  /// 是否在线
  bool get isOnline => status == 'online';

  /// 是否待审核（需要传入当前用户ID来判断是否可以审核）
  bool isPendingForUser(int currentUserId) {
    return approvalStatus == 'pending' && friendId == currentUserId;
  }
  
  /// 是否等待对方审核（发起方视角）
  bool isWaitingForApproval(int currentUserId) {
    return approvalStatus == 'pending' && userId == currentUserId;
  }
  
  /// 是否待审核（保持向后兼容，但建议使用isPendingForUser）
  @deprecated
  bool get isPending => approvalStatus == 'pending';

  /// 是否已通过
  bool get isApproved => approvalStatus == 'approved';

  /// 是否已拒绝
  bool get isRejected => approvalStatus == 'rejected';

  /// 创建一个新的实例，可以修改某些字段
  ContactModel copyWith({
    int? relationId,
    int? userId,
    int? friendId,
    String? username,
    String? fullName,
    String? avatar,
    String? workSignature,
    String? status,
    String? phone,
    String? email,
    String? department,
    String? position,
    DateTime? createdAt,
    String? approvalStatus,
    bool? isBlocked,
    int? blockedByUserId,
    bool? isBlockedByMe,
    bool? isDeleted,
    int? deletedByUserId,
  }) {
    return ContactModel(
      relationId: relationId ?? this.relationId,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      workSignature: workSignature ?? this.workSignature,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      department: department ?? this.department,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedByUserId: blockedByUserId ?? this.blockedByUserId,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedByUserId: deletedByUserId ?? this.deletedByUserId,
    );
  }
}
