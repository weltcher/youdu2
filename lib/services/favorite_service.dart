import '../models/message_model.dart';
import 'local_database_service.dart';
import '../utils/storage.dart';
import '../utils/logger.dart';

/// 收藏服务
/// 管理收藏消息、常用联系人和常用群组
class FavoriteService {
  final _localDb = LocalDatabaseService();

  // ============ 收藏消息 ============

  /// 添加收藏消息
  Future<int> addFavorite({
    int? messageId,
    required String content,
    required String messageType,
    String? fileName,
    required int senderId,
    required String senderName,
  }) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) throw Exception('用户未登录');

      // 检查是否已收藏
      final existing = await _localDb.checkFavoriteExists(
        userId: userId,
        messageId: messageId,
        content: content,
        senderId: senderId,
      );

      if (existing != null) {
        logger.debug('消息已存在于收藏中');
        return existing['id'] as int;
      }

      final favorite = {
        'user_id': userId,
        'content': content,
        'message_type': messageType,
        'sender_id': senderId,
        'sender_name': senderName,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (messageId != null) favorite['message_id'] = messageId;
      if (fileName != null) favorite['file_name'] = fileName;

      final id = await _localDb.insertFavorite(favorite);
      logger.debug('添加收藏成功: ID=$id');
      return id;
    } catch (e) {
      logger.debug('添加收藏失败: $e');
      rethrow;
    }
  }

  /// 获取收藏列表
  Future<List<MessageModel>> getFavorites({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return [];

      final offset = (page - 1) * pageSize;
      final results = await _localDb.getFavorites(
        userId: userId,
        limit: pageSize,
        offset: offset,
      );

      return results.map<MessageModel>((data) {
        return MessageModel(
          id: (data['id'] as int?) ?? 0,
          senderId: (data['sender_id'] as int?) ?? 0,
          receiverId: userId,
          senderName: (data['sender_name'] as String?) ?? '',
          receiverName: '我',
          content: (data['content'] as String?) ?? '',
          messageType: (data['message_type'] as String?) ?? 'text',
          fileName: data['file_name'] as String?,
          status: 'normal',
          isRead: true,
          createdAt: DateTime.tryParse((data['created_at'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      logger.debug('获取收藏列表失败: $e');
      return [];
    }
  }

  /// 删除收藏
  Future<bool> deleteFavorite(int favoriteId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      await _localDb.deleteFavorite(favoriteId, userId);
      logger.debug('删除收藏成功: ID=$favoriteId');
      return true;
    } catch (e) {
      logger.debug('删除收藏失败: $e');
      return false;
    }
  }

  /// 检查消息是否已收藏
  Future<bool> isFavorited({
    int? messageId,
    String? content,
    int? senderId,
  }) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      final result = await _localDb.checkFavoriteExists(
        userId: userId,
        messageId: messageId,
        content: content,
        senderId: senderId,
      );

      return result != null;
    } catch (e) {
      logger.debug('检查收藏状态失败: $e');
      return false;
    }
  }

  // ============ 常用联系人 ============

  /// 添加常用联系人
  Future<bool> addFavoriteContact(int contactId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      await _localDb.addFavoriteContact(userId, contactId);
      logger.debug('添加常用联系人成功: ContactID=$contactId');
      return true;
    } catch (e) {
      logger.debug('添加常用联系人失败: $e');
      return false;
    }
  }

  /// 移除常用联系人
  Future<bool> removeFavoriteContact(int contactId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      await _localDb.removeFavoriteContact(userId, contactId);
      logger.debug('移除常用联系人成功: ContactID=$contactId');
      return true;
    } catch (e) {
      logger.debug('移除常用联系人失败: $e');
      return false;
    }
  }

  /// 获取常用联系人ID列表
  Future<List<int>> getFavoriteContactIds() async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return [];

      final results = await _localDb.getFavoriteContacts(userId);
      return results.map((data) => (data['contact_id'] as int?) ?? 0).where((id) => id != 0).toList();
    } catch (e) {
      logger.debug('获取常用联系人列表失败: $e');
      return [];
    }
  }

  /// 获取常用联系人详细信息列表
  Future<List<Map<String, dynamic>>> getFavoriteContactsWithDetails() async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return [];

      // 获取常用联系人ID列表
      final favoriteResults = await _localDb.getFavoriteContacts(userId);
      final contactIds = favoriteResults
          .map((data) => (data['contact_id'] as int?) ?? 0)
          .where((id) => id != 0)
          .toList();

      if (contactIds.isEmpty) return [];

      // 批量查询联系人详细信息
      final List<Map<String, dynamic>> contactDetails = [];
      for (final contactId in contactIds) {
        final contactInfo = await _localDb.getContactSnapshot(
          ownerId: userId,
          contactId: contactId,
          contactType: 'user',
        );
        if (contactInfo != null) {
          contactDetails.add({
            'contact_id': contactId,
            'user_id': contactId, // contact_id 就是用户ID
            'username': contactInfo['username'],
            'full_name': contactInfo['full_name'],
            'avatar': contactInfo['avatar'],
            'status': 'offline', // 默认为离线，稍后会通过状态同步更新
          });
        }
      }

      logger.debug('获取常用联系人详细信息成功: ${contactDetails.length}个');
      return contactDetails;
    } catch (e) {
      logger.debug('获取常用联系人详细信息失败: $e');
      return [];
    }
  }

  /// 检查是否为常用联系人
  Future<bool> isFavoriteContact(int contactId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      return await _localDb.isFavoriteContact(userId, contactId);
    } catch (e) {
      logger.debug('检查常用联系人失败: $e');
      return false;
    }
  }

  // ============ 常用群组 ============

  /// 添加常用群组
  Future<bool> addFavoriteGroup(int groupId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      await _localDb.addFavoriteGroup(userId, groupId);
      logger.debug('添加常用群组成功: GroupID=$groupId');
      return true;
    } catch (e) {
      logger.debug('添加常用群组失败: $e');
      return false;
    }
  }

  /// 移除常用群组
  Future<bool> removeFavoriteGroup(int groupId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      await _localDb.removeFavoriteGroup(userId, groupId);
      logger.debug('移除常用群组成功: GroupID=$groupId');
      return true;
    } catch (e) {
      logger.debug('移除常用群组失败: $e');
      return false;
    }
  }

  /// 获取常用群组ID列表
  Future<List<int>> getFavoriteGroupIds() async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return [];

      final results = await _localDb.getFavoriteGroups(userId);
      return results.map((data) => (data['group_id'] as int?) ?? 0).where((id) => id != 0).toList();
    } catch (e) {
      logger.debug('获取常用群组列表失败: $e');
      return [];
    }
  }

  /// 检查是否为常用群组
  Future<bool> isFavoriteGroup(int groupId) async {
    try {
      final userId = await Storage.getUserId();
      if (userId == null) return false;

      return await _localDb.isFavoriteGroup(userId, groupId);
    } catch (e) {
      logger.debug('检查常用群组失败: $e');
      return false;
    }
  }
}
