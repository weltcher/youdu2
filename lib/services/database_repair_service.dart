import '../utils/logger.dart';
import '../utils/storage.dart';
import 'local_database_service.dart';
import 'api_service.dart';

/// 数据库修复服务 - 用于修复历史数据中缺失的用户昵称
class DatabaseRepairService {
  static final DatabaseRepairService _instance = DatabaseRepairService._internal();
  factory DatabaseRepairService() => _instance;
  DatabaseRepairService._internal();

  final _localDb = LocalDatabaseService();

  /// 修复数据库中缺失的用户昵称字段
  /// 这是一个一次性的修复操作，用于补全历史数据
  Future<void> repairMissingUserNames() async {
    try {
      final currentUserId = await Storage.getUserId();
      final token = await Storage.getToken();
      
      if (currentUserId == null || token == null) {
        logger.debug('⚠️ 用户未登录，跳过数据库修复');
        return;
      }

      logger.debug('🔧 开始修复数据库中缺失的用户昵称...');
      
      // 修复私聊消息
      await _repairPrivateMessages(currentUserId, token);
      
      // 修复群组消息
      await _repairGroupMessages(currentUserId, token);
      
      logger.debug('✅ 数据库用户昵称修复完成');
    } catch (e) {
      logger.debug('❌ 数据库修复失败: $e');
    }
  }

  /// 修复私聊消息中缺失的用户昵称
  Future<void> _repairPrivateMessages(int currentUserId, String token) async {
    try {
      // 查找缺失昵称的私聊消息
      final results = await _localDb.executeRawQuery(
        '''
        SELECT DISTINCT 
          sender_id, receiver_id,
          sender_name, receiver_name
        FROM messages 
        WHERE (sender_name IS NULL OR sender_name = '' OR sender_name GLOB '[0-9]*')
           OR (receiver_name IS NULL OR receiver_name = '' OR receiver_name GLOB '[0-9]*')
        LIMIT 100
        ''',
        [],
      );

      logger.debug('🔍 找到 ${results.length} 条需要修复昵称的私聊消息记录');

      if (results.isEmpty) return;

      // 收集需要查询的用户ID
      final Set<int> userIdsToQuery = {};
      for (final row in results) {
        final senderId = row['sender_id'] as int;
        final receiverId = row['receiver_id'] as int;
        final senderName = row['sender_name']?.toString();
        final receiverName = row['receiver_name']?.toString();

        if (_needsRepair(senderName)) {
          userIdsToQuery.add(senderId);
        }
        if (_needsRepair(receiverName)) {
          userIdsToQuery.add(receiverId);
        }
      }

      // 批量获取用户信息
      final Map<int, Map<String, dynamic>> userInfoCache = {};
      for (final userId in userIdsToQuery) {
        try {
          final userInfo = await ApiService.getUserInfo(userId, token: token);
          if (userInfo['code'] == 0 && userInfo['data'] != null) {
            userInfoCache[userId] = userInfo['data'];
            logger.debug('📥 获取用户信息: ID=$userId, 昵称=${userInfo['data']['full_name'] ?? userInfo['data']['username']}');
          }
        } catch (e) {
          logger.debug('⚠️ 获取用户 $userId 信息失败: $e');
        }
      }

      // 批量更新消息
      int updatedCount = 0;
      for (final row in results) {
        final senderId = row['sender_id'] as int;
        final receiverId = row['receiver_id'] as int;
        final senderName = row['sender_name']?.toString();
        final receiverName = row['receiver_name']?.toString();

        String? newSenderName;
        String? newReceiverName;

        if (_needsRepair(senderName) && userInfoCache.containsKey(senderId)) {
          final userData = userInfoCache[senderId]!;
          newSenderName = userData['full_name']?.toString()?.isNotEmpty == true
              ? userData['full_name'].toString()
              : userData['username']?.toString();
        }

        if (_needsRepair(receiverName) && userInfoCache.containsKey(receiverId)) {
          final userData = userInfoCache[receiverId]!;
          newReceiverName = userData['full_name']?.toString()?.isNotEmpty == true
              ? userData['full_name'].toString()
              : userData['username']?.toString();
        }

        if (newSenderName != null || newReceiverName != null) {
          await _updatePrivateMessageNames(senderId, receiverId, newSenderName, newReceiverName);
          updatedCount++;
        }
      }

      logger.debug('✅ 修复了 $updatedCount 条私聊消息的用户昵称');
    } catch (e) {
      logger.debug('❌ 修复私聊消息昵称失败: $e');
    }
  }

  /// 修复群组消息中缺失的用户昵称
  Future<void> _repairGroupMessages(int currentUserId, String token) async {
    try {
      // 查找缺失昵称的群组消息
      final results = await _localDb.executeRawQuery(
        '''
        SELECT DISTINCT sender_id, sender_name
        FROM group_messages 
        WHERE sender_name IS NULL OR sender_name = '' OR sender_name GLOB '[0-9]*'
        LIMIT 100
        ''',
        [],
      );

      logger.debug('🔍 找到 ${results.length} 条需要修复昵称的群组消息记录');

      if (results.isEmpty) return;

      // 收集需要查询的用户ID
      final Set<int> userIdsToQuery = {};
      for (final row in results) {
        final senderId = row['sender_id'] as int;
        final senderName = row['sender_name']?.toString();

        if (_needsRepair(senderName)) {
          userIdsToQuery.add(senderId);
        }
      }

      // 批量获取用户信息
      final Map<int, String> userNameCache = {};
      for (final userId in userIdsToQuery) {
        try {
          final userInfo = await ApiService.getUserInfo(userId, token: token);
          if (userInfo['code'] == 0 && userInfo['data'] != null) {
            final userData = userInfo['data'];
            final userName = userData['full_name']?.toString()?.isNotEmpty == true
                ? userData['full_name'].toString()
                : userData['username']?.toString();
            if (userName != null) {
              userNameCache[userId] = userName;
              logger.debug('📥 获取用户信息: ID=$userId, 昵称=$userName');
            }
          }
        } catch (e) {
          logger.debug('⚠️ 获取用户 $userId 信息失败: $e');
        }
      }

      // 批量更新群组消息
      int updatedCount = 0;
      for (final entry in userNameCache.entries) {
        await _updateGroupMessageNames(entry.key, entry.value);
        updatedCount++;
      }

      logger.debug('✅ 修复了 $updatedCount 个用户的群组消息昵称');
    } catch (e) {
      logger.debug('❌ 修复群组消息昵称失败: $e');
    }
  }

  /// 判断昵称是否需要修复
  bool _needsRepair(String? name) {
    if (name == null || name.isEmpty) return true;
    // 检查是否是纯数字ID
    return int.tryParse(name) != null;
  }

  /// 更新私聊消息的用户昵称
  Future<void> _updatePrivateMessageNames(
    int senderId, 
    int receiverId, 
    String? newSenderName, 
    String? newReceiverName
  ) async {
    final updates = <String, dynamic>{};
    if (newSenderName != null) {
      updates['sender_name'] = newSenderName;
    }
    if (newReceiverName != null) {
      updates['receiver_name'] = newReceiverName;
    }

    if (updates.isNotEmpty) {
      await _localDb.executeUpdate(
        'messages',
        updates,
        where: 'sender_id = ? AND receiver_id = ?',
        whereArgs: [senderId, receiverId],
      );
      logger.debug('🔄 更新私聊消息昵称: sender=$senderId->$newSenderName, receiver=$receiverId->$newReceiverName');
    }
  }

  /// 更新群组消息的用户昵称
  Future<void> _updateGroupMessageNames(int senderId, String newSenderName) async {
    await _localDb.executeUpdate(
      'group_messages',
      {'sender_name': newSenderName},
      where: 'sender_id = ?',
      whereArgs: [senderId],
    );
    logger.debug('🔄 更新群组消息昵称: sender=$senderId->$newSenderName');
  }

  /// 检查是否需要进行数据库修复
  /// 返回需要修复的消息数量
  Future<int> checkRepairNeeded() async {
    try {
      // 检查私聊消息
      final privateResults = await _localDb.executeRawQuery(
        '''
        SELECT COUNT(*) as count
        FROM messages 
        WHERE (sender_name IS NULL OR sender_name = '' OR sender_name GLOB '[0-9]*')
           OR (receiver_name IS NULL OR receiver_name = '' OR receiver_name GLOB '[0-9]*')
        ''',
        [],
      );

      // 检查群组消息
      final groupResults = await _localDb.executeRawQuery(
        '''
        SELECT COUNT(*) as count
        FROM group_messages 
        WHERE sender_name IS NULL OR sender_name = '' OR sender_name GLOB '[0-9]*'
        ''',
        [],
      );

      final privateCount = privateResults.isNotEmpty ? (privateResults.first['count'] as int? ?? 0) : 0;
      final groupCount = groupResults.isNotEmpty ? (groupResults.first['count'] as int? ?? 0) : 0;
      final totalCount = privateCount + groupCount;

      logger.debug('📊 数据库修复检查: 私聊消息需修复 $privateCount 条, 群组消息需修复 $groupCount 条, 总计 $totalCount 条');
      return totalCount;
    } catch (e) {
      logger.debug('❌ 检查数据库修复需求失败: $e');
      return 0;
    }
  }
}
