import '../utils/logger.dart';
import '../utils/storage.dart';
import 'database_repair_service.dart';

/// 应用初始化服务
/// 负责应用启动时的各种初始化和修复工作
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final _repairService = DatabaseRepairService();

  /// 执行应用初始化
  Future<void> initialize() async {
    try {
      logger.debug('🚀 开始应用初始化...');
      
      // 检查用户是否已登录
      final isLoggedIn = await Storage.isLoggedIn();
      if (!isLoggedIn) {
        logger.debug('⚠️ 用户未登录，跳过数据库修复');
        return;
      }

      // 检查是否需要进行数据库修复
      await _checkAndRepairDatabase();
      
      logger.debug('✅ 应用初始化完成');
    } catch (e) {
      logger.debug('❌ 应用初始化失败: $e');
    }
  }

  /// 检查并修复数据库
  Future<void> _checkAndRepairDatabase() async {
    try {
      // 检查是否已经执行过修复
      final lastRepairTime = await Storage.getLastDatabaseRepairTime();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // 如果距离上次修复超过7天，或者从未修复过，则执行修复
      if (lastRepairTime == null || (currentTime - lastRepairTime) > 7 * 24 * 60 * 60 * 1000) {
        logger.debug('🔧 检查数据库修复需求...');
        
        final needRepairCount = await _repairService.checkRepairNeeded();
        if (needRepairCount > 0) {
          logger.debug('🔧 发现 $needRepairCount 条记录需要修复用户昵称，开始修复...');
          await _repairService.repairMissingUserNames();
          
          // 记录修复时间
          await Storage.saveLastDatabaseRepairTime(currentTime);
          logger.debug('✅ 数据库修复完成，已记录修复时间');
        } else {
          logger.debug('✅ 数据库无需修复');
          // 即使无需修复，也更新修复时间，避免频繁检查
          await Storage.saveLastDatabaseRepairTime(currentTime);
        }
      } else {
        logger.debug('⏭️ 距离上次数据库修复时间较短，跳过检查');
      }
    } catch (e) {
      logger.debug('❌ 数据库修复检查失败: $e');
    }
  }

  /// 手动触发数据库修复（用于调试或用户手动触发）
  Future<bool> manualRepairDatabase() async {
    try {
      logger.debug('🔧 手动触发数据库修复...');
      
      final needRepairCount = await _repairService.checkRepairNeeded();
      if (needRepairCount > 0) {
        logger.debug('🔧 发现 $needRepairCount 条记录需要修复，开始修复...');
        await _repairService.repairMissingUserNames();
        
        // 记录修复时间
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        await Storage.saveLastDatabaseRepairTime(currentTime);
        
        logger.debug('✅ 手动数据库修复完成');
        return true;
      } else {
        logger.debug('✅ 数据库无需修复');
        return false;
      }
    } catch (e) {
      logger.debug('❌ 手动数据库修复失败: $e');
      return false;
    }
  }
}
