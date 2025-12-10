import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart' show ConflictAlgorithm;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite_cipher;
import '../utils/logger.dart';
import 'database_provider.dart';

/// 移动端数据库提供者（Android/iOS）
/// 使用 sqflite_sqlcipher 实现加密数据库
class MobileDatabaseProvider implements DatabaseProvider {
  late Database _db;
  
  /// 构造函数
  MobileDatabaseProvider(this._db);
  
  // ============ 基础操作 ============
  
  @override
  int insert(String table, Map<String, dynamic> values, {bool orIgnore = false}) {
    // sqflite的insert是异步的，这里需要同步包装
    // 注意：调用者需要使用异步方式
    throw UnsupportedError('请使用 insertAsync 方法');
  }
  
  /// 异步插入（移动端专用）
  Future<int> insertAsync(String table, Map<String, dynamic> values, {bool orIgnore = false}) async {
    try {
      // sqflite 不支持 bool 类型，需要转换为 int
      final convertedValues = _convertBoolToInt(values);
      
      final id = await _db.insert(
        table, 
        convertedValues,
        conflictAlgorithm: orIgnore ? ConflictAlgorithm.ignore : ConflictAlgorithm.abort,
      );
      if (id > 0) {
        logger.debug('[Mobile] 插入数据成功: $table, ID=$id');
      }
      return id;
    } catch (e) {
      logger.debug('[Mobile] 插入数据失败: $table, $e');
      rethrow;
    }
  }
  
  /// 将 Map 中的 bool 值转换为 int（sqflite 不支持 bool）
  Map<String, dynamic> _convertBoolToInt(Map<String, dynamic> values) {
    final result = <String, dynamic>{};
    values.forEach((key, value) {
      if (value is bool) {
        result[key] = value ? 1 : 0;
      } else {
        result[key] = value;
      }
    });
    return result;
  }
  
  @override
  List<Map<String, dynamic>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    throw UnsupportedError('请使用 queryAsync 方法');
  }
  
  /// 异步查询（移动端专用）
  Future<List<Map<String, dynamic>>> queryAsync(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final results = await _db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      return results;
    } catch (e) {
      logger.debug('[Mobile] 查询数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  List<Map<String, dynamic>> rawQuery(String sql, [List<Object?>? args]) {
    throw UnsupportedError('请使用 rawQueryAsync 方法');
  }
  
  /// 异步原始查询（移动端专用）
  Future<List<Map<String, dynamic>>> rawQueryAsync(String sql, [List<Object?>? args]) async {
    try {
      final results = await _db.rawQuery(sql, args);
      return results;
    } catch (e) {
      logger.debug('[Mobile] 原始查询失败: $e');
      rethrow;
    }
  }
  
  @override
  int update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    throw UnsupportedError('请使用 updateAsync 方法');
  }
  
  /// 异步更新（移动端专用）
  Future<int> updateAsync(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      // sqflite 不支持 bool 类型，需要转换为 int
      final convertedValues = _convertBoolToInt(values);
      
      final count = await _db.update(
        table,
        convertedValues,
        where: where,
        whereArgs: whereArgs,
      );
      return count;
    } catch (e) {
      logger.debug('[Mobile] 更新数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  int delete(String table, {String? where, List<Object?>? whereArgs}) {
    throw UnsupportedError('请使用 deleteAsync 方法');
  }
  
  /// 异步删除（移动端专用）
  Future<int> deleteAsync(String table, {String? where, List<Object?>? whereArgs}) async {
    try {
      final count = await _db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      logger.debug('[Mobile] 删除数据: $table, 影响行数=$count');
      return count;
    } catch (e) {
      logger.debug('[Mobile] 删除数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  void rawDelete(String sql, [List<Object?>? args]) {
    throw UnsupportedError('请使用 rawDeleteAsync 方法');
  }
  
  /// 异步原始删除（移动端专用）
  Future<int> rawDeleteAsync(String sql, [List<Object?>? args]) async {
    try {
      final count = await _db.rawDelete(sql, args);
      logger.debug('[Mobile] 原始删除执行成功，影响行数=$count');
      return count;
    } catch (e) {
      logger.debug('[Mobile] 原始删除失败: $e');
      rethrow;
    }
  }
  
  @override
  void execute(String sql, [List<Object?>? args]) {
    throw UnsupportedError('请使用 executeAsync 方法');
  }
  
  /// 异步执行SQL（移动端专用）
  Future<void> executeAsync(String sql, [List<Object?>? args]) async {
    try {
      await _db.execute(sql, args);
      logger.debug('[Mobile] SQL执行成功');
    } catch (e) {
      logger.debug('[Mobile] SQL执行失败: $e');
      rethrow;
    }
  }
  
  @override
  int? firstIntValue(List<Map<String, dynamic>> results) {
    return Sqflite.firstIntValue(results);
  }
  
  // ============ 事务支持 ============
  
  @override
  void beginTransaction() {
    throw UnsupportedError('移动端使用 transactionAsync 方法');
  }
  
  @override
  void commit() {
    throw UnsupportedError('移动端使用 transactionAsync 方法');
  }
  
  @override
  void rollback() {
    throw UnsupportedError('移动端使用 transactionAsync 方法');
  }
  
  /// 异步事务（移动端专用）
  Future<T> transactionAsync<T>(Future<T> Function(Transaction txn) action) async {
    try {
      return await _db.transaction(action);
    } catch (e) {
      logger.debug('[Mobile] 事务执行失败: $e');
      rethrow;
    }
  }
  
  // ============ 批量操作 ============
  
  @override
  void batchInsert(String table, List<Map<String, dynamic>> values) {
    throw UnsupportedError('请使用 batchInsertAsync 方法');
  }
  
  /// 异步批量插入（移动端专用）
  Future<void> batchInsertAsync(String table, List<Map<String, dynamic>> values) async {
    try {
      final batch = _db.batch();
      for (var value in values) {
        batch.insert(table, value);
      }
      await batch.commit(noResult: true);
      logger.debug('[Mobile] 批量插入成功: $table, 数量=${values.length}');
    } catch (e) {
      logger.debug('[Mobile] 批量插入失败: $table, $e');
      rethrow;
    }
  }
  
  // ============ 资源管理 ============
  
  @override
  void close() {
    throw UnsupportedError('请使用 closeAsync 方法');
  }
  
  /// 异步关闭（移动端专用）
  Future<void> closeAsync() async {
    try {
      await _db.close();
      logger.debug('[Mobile] 数据库已关闭');
    } catch (e) {
      logger.debug('[Mobile] 关闭数据库失败: $e');
      rethrow;
    }
  }
}
