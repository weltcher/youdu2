import '../utils/timezone_helper.dart';

/// 收藏模型
class FavoriteModel {
  final int id;
  final int userId;
  final int? messageId;
  final String content;
  final String messageType;
  final String? fileName;
  final int senderId;
  final String senderName;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    this.messageId,
    required this.content,
    required this.messageType,
    this.fileName,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: (json['id'] as int?) ?? 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (messageId != null) 'message_id': messageId,
      'content': content,
      'message_type': messageType,
      if (fileName != null) 'file_name': fileName,
      'sender_id': senderId,
      'sender_name': senderName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
