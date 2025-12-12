import '../utils/timezone_helper.dart';

/// 同步状态枚举
enum SyncStatus {
  synced,    // 已同步
  pending,   // 待同步（新增）
  deleted,   // 待删除
}

/// 收藏模型
class FavoriteModel {
  final int id;           // 本地ID
  final int? serverId;    // 服务器ID（用于同步）
  final int userId;
  final int? messageId;
  final String content;
  final String messageType;
  final String? fileName;
  final int senderId;
  final String senderName;
  final DateTime createdAt;
  final SyncStatus syncStatus;  // 同步状态

  FavoriteModel({
    required this.id,
    this.serverId,
    required this.userId,
    this.messageId,
    required this.content,
    required this.messageType,
    this.fileName,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: (json['id'] as int?) ?? 0,
      serverId: json['server_id'] as int?,
      userId: (json['user_id'] as int?) ?? 0,
      messageId: json['message_id'] as int?,
      content: (json['content'] as String?) ?? '',
      messageType: (json['message_type'] as String?) ?? 'text',
      fileName: json['file_name'] as String?,
      senderId: (json['sender_id'] as int?) ?? 0,
      senderName: (json['sender_name'] as String?) ?? '',
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? TimezoneHelper.parseToShanghaiTime(json['created_at'] as String)
          : DateTime.now(),
      syncStatus: _parseSyncStatus(json['sync_status']),
    );
  }

  /// 从服务器响应创建模型（服务器返回的id作为serverId）
  factory FavoriteModel.fromServerJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: 0,  // 本地ID稍后分配
      serverId: (json['id'] as int?) ?? 0,
      userId: (json['user_id'] as int?) ?? 0,
      messageId: json['message_id'] as int?,
      content: (json['content'] as String?) ?? '',
      messageType: (json['message_type'] as String?) ?? 'text',
      fileName: json['file_name'] as String?,
      senderId: (json['sender_id'] as int?) ?? 0,
      senderName: (json['sender_name'] as String?) ?? '',
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? TimezoneHelper.parseToShanghaiTime(json['created_at'] as String)
          : DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }

  static SyncStatus _parseSyncStatus(dynamic value) {
    if (value == null) return SyncStatus.synced;
    if (value is String) {
      switch (value) {
        case 'pending':
          return SyncStatus.pending;
        case 'deleted':
          return SyncStatus.deleted;
        default:
          return SyncStatus.synced;
      }
    }
    return SyncStatus.synced;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (serverId != null) 'server_id': serverId,
      'user_id': userId,
      if (messageId != null) 'message_id': messageId,
      'content': content,
      'message_type': messageType,
      if (fileName != null) 'file_name': fileName,
      'sender_id': senderId,
      'sender_name': senderName,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  /// 转换为本地数据库存储格式
  Map<String, dynamic> toLocalDbMap() {
    return {
      if (id > 0) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'user_id': userId,
      if (messageId != null) 'message_id': messageId,
      'content': content,
      'message_type': messageType,
      if (fileName != null) 'file_name': fileName,
      'sender_id': senderId,
      'sender_name': senderName,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  /// 创建副本并更新部分字段
  FavoriteModel copyWith({
    int? id,
    int? serverId,
    int? userId,
    int? messageId,
    String? content,
    String? messageType,
    String? fileName,
    int? senderId,
    String? senderName,
    DateTime? createdAt,
    SyncStatus? syncStatus,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileName: fileName ?? this.fileName,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
