import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../utils/logger.dart';

/// 桌面端 SQLCipher 数据库辅助类
/// 使用 sqlite3 包直接操作加密数据库
class DesktopDatabaseHelper {
  late Database _db;
  final String dbPath;
  final String password;

  DesktopDatabaseHelper({
    required this.dbPath,
    required this.password,
  });

  /// 打开加密数据库
  void open() {
    try {
      _db = sqlite3.open(dbPath);
      
      // 设置加密密钥
      _db.execute("PRAGMA key = '$password'");
      logger.debug('🔐 已设置数据库加密密钥');
      
      // 验证 SQLCipher
      try {
        final versionResult = _db.select('PRAGMA cipher_version');
        if (versionResult.isNotEmpty) {
          logger.debug('✅ SQLCipher 版本: ${versionResult.first['cipher_version']}');
        }
      } catch (e) {
        logger.debug('⚠️ 无法获取 cipher_version: $e');
      }
      
      // 验证密钥正确性
      try {
        _db.select('SELECT count(*) FROM sqlite_master');
        logger.debug('✅ 数据库解密成功');
      } catch (e) {
        logger.debug('❌ 数据库解密失败: $e');
        throw Exception('密钥不正确或数据库损坏');
      }
    } catch (e) {
      logger.debug('❌ 打开数据库失败: $e');
      rethrow;
    }
  }

  /// 关闭数据库
  void close() {
    try {
      _db.dispose();
      logger.debug('数据库已关闭');
    } catch (e) {
      logger.debug('关闭数据库失败: $e');
    }
  }

  /// 执行 SQL
  void execute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
  }

  /// 查询
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    return _db.select(sql, parameters);
  }

  /// 插入并返回 ID
  int insert(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
    final result = _db.select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  /// 批量执行
  void batch(void Function(Database db) fn) {
    fn(_db);
  }

  /// 事务
  void transaction(void Function(Database db) fn) {
    _db.execute('BEGIN TRANSACTION');
    try {
      fn(_db);
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}
