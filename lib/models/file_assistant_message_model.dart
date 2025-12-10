import '../utils/timezone_helper.dart';

/// 文件传输助手消息模型
class FileAssistantMessageModel {
  final int id;
  final int userId;
  final String content;
  final String messageType; // text, image, file, quoted
  final String? fileName;
  final int? quotedMessageId;
  final String? quotedMessageContent;
  final String status; // normal, recalled
  final DateTime createdAt;

  FileAssistantMessageModel({
    required this.id,
    required this.userId,
    required this.content,
    this.messageType = 'text',
    this.fileName,
    this.quotedMessageId,
    this.quotedMessageContent,
    this.status = 'normal',
    required this.createdAt,
  });

  /// 从 JSON 创建模型
  factory FileAssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return FileAssistantMessageModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      fileName: json['file_name'] as String?,
      quotedMessageId: json['quoted_message_id'] as int?,
      quotedMessageContent: json['quoted_message_content'] as String?,
      status: json['status'] as String? ?? 'normal',
      createdAt: TimezoneHelper.parseToShanghaiTime(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'message_type': messageType,
      if (fileName != null) 'file_name': fileName,
      if (quotedMessageId != null) 'quoted_message_id': quotedMessageId,
      if (quotedMessageContent != null)
        'quoted_message_content': quotedMessageContent,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 转换为MessageModel（用于在聊天界面显示）
  /// 注意：文件助手消息需要特殊处理，发送者和接收者都是当前用户
  /// 但为了区分发送方向，我们使用特殊的ID标记
  MessageModel toMessageModel({
    required int currentUserId,
    required String currentUsername,
  }) {
    // 文件助手消息都由用户发送给自己
    // 因此 senderId 和 receiverId 都是当前用户ID
    return MessageModel(
      id: id,
      senderId: currentUserId,
      receiverId: currentUserId,
      senderName: currentUsername,
      receiverName: '文件传输助手',
      content: content,
      messageType: messageType,
      fileName: fileName,
      quotedMessageId: quotedMessageId,
      quotedMessageContent: quotedMessageContent,
      status: status,
      isRead: true, // 文件助手消息都标记为已读
      createdAt: createdAt,
    );
  }
}

/// MessageModel - 用于与现有聊天界面兼容
/// 注意：这个类应该已经在项目中存在，这里仅作为引用
class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String senderName;
  final String receiverName;
  final String content;
  final String messageType;
  final String? fileName;
  final int? quotedMessageId;
  final String? quotedMessageContent;
  final String status;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.content,
    this.messageType = 'text',
    this.fileName,
    this.quotedMessageId,
    this.quotedMessageContent,
    this.status = 'normal',
    this.isRead = false,
    required this.createdAt,
  });
}
