import 'package:sqlite3/sqlite3.dart';
import '../utils/logger.dart';
import 'database_provider.dart';

/// 桌面端数据库提供者（Windows/macOS/Linux）
/// 使用 sqlite3 实现加密数据库（SQLCipher）
class DesktopDatabaseProvider implements DatabaseProvider {
  final Database _db;
  
  /// 构造函数
  DesktopDatabaseProvider(this._db);
  
  // ============ 基础操作 ============
  
  @override
  int insert(String table, Map<String, dynamic> values, {bool orIgnore = false}) {
    try {
      final columns = values.keys.join(', ');
      final placeholders = List.filled(values.length, '?').join(', ');
      final insertType = orIgnore ? 'INSERT OR IGNORE' : 'INSERT';
      final sql = '$insertType INTO $table ($columns) VALUES ($placeholders)';
      _db.execute(sql, values.values.toList());
      final id = _db.lastInsertRowId;
      if (id > 0) {
        logger.debug('[Desktop] 插入数据成功: $table, ID=$id');
      }
      return id;
    } catch (e) {
      logger.debug('[Desktop] 插入数据失败: $table, $e');
      rethrow;
    }
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
    try {
      final buffer = StringBuffer('SELECT * FROM $table');
      if (where != null) {
        buffer.write(' WHERE $where');
      }
      if (orderBy != null) {
        buffer.write(' ORDER BY $orderBy');
      }
      if (limit != null) {
        buffer.write(' LIMIT $limit');
      }
      if (offset != null) {
        buffer.write(' OFFSET $offset');
      }
      
      final result = _db.select(buffer.toString(), whereArgs ?? []);
      final list = result.map((row) => Map<String, dynamic>.from(row)).toList();
      return list;
    } catch (e) {
      logger.debug('[Desktop] 查询数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  List<Map<String, dynamic>> rawQuery(String sql, [List<Object?>? args]) {
    try {
      final result = _db.select(sql, args ?? []);
      final list = result.map((row) => Map<String, dynamic>.from(row)).toList();
      return list;
    } catch (e) {
      logger.debug('[Desktop] 原始查询失败: $e');
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
    try {
      final setClauses = values.keys.map((key) => '$key = ?').join(', ');
      final sql = 'UPDATE $table SET $setClauses${where != null ? ' WHERE $where' : ''}';
      _db.execute(sql, [...values.values, ...?whereArgs]);
      final count = _db.getUpdatedRows();
      return count;
    } catch (e) {
      logger.debug('[Desktop] 更新数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  int delete(String table, {String? where, List<Object?>? whereArgs}) {
    try {
      final sql = 'DELETE FROM $table${where != null ? ' WHERE $where' : ''}';
      _db.execute(sql, whereArgs ?? []);
      final count = _db.getUpdatedRows();
      logger.debug('[Desktop] 删除数据: $table, 影响行数=$count');
      return count;
    } catch (e) {
      logger.debug('[Desktop] 删除数据失败: $table, $e');
      rethrow;
    }
  }
  
  @override
  void rawDelete(String sql, [List<Object?>? args]) {
    try {
      _db.execute(sql, args ?? []);
      logger.debug('[Desktop] 原始删除执行成功');
    } catch (e) {
      logger.debug('[Desktop] 原始删除失败: $e');
      rethrow;
    }
  }
  
  @override
  void execute(String sql, [List<Object?>? args]) {
    try {
      _db.execute(sql, args ?? []);
      logger.debug('[Desktop] SQL执行成功');
    } catch (e) {
      logger.debug('[Desktop] SQL执行失败: $e');
      rethrow;
    }
  }
  
  @override
  int? firstIntValue(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return null;
    final firstRow = results.first;
    if (firstRow.isEmpty) return null;
    final firstValue = firstRow.values.first;
    if (firstValue is int) return firstValue;
    if (firstValue is String) return int.tryParse(firstValue);
    return null;
  }
  
  // ============ 事务支持 ============
  
  @override
  void beginTransaction() {
    try {
      _db.execute('BEGIN TRANSACTION');
      logger.debug('[Desktop] 开始事务');
    } catch (e) {
      logger.debug('[Desktop] 开始事务失败: $e');
      rethrow;
    }
  }
  
  @override
  void commit() {
    try {
      _db.execute('COMMIT');
      logger.debug('[Desktop] 提交事务');
    } catch (e) {
      logger.debug('[Desktop] 提交事务失败: $e');
      rethrow;
    }
  }
  
  @override
  void rollback() {
    try {
      _db.execute('ROLLBACK');
      logger.debug('[Desktop] 回滚事务');
    } catch (e) {
      logger.debug('[Desktop] 回滚事务失败: $e');
      rethrow;
    }
  }
  
  /// 执行事务
  T transaction<T>(T Function() action) {
    beginTransaction();
    try {
      final result = action();
      commit();
      return result;
    } catch (e) {
      rollback();
      rethrow;
    }
  }
  
  // ============ 批量操作 ============
  
  @override
  void batchInsert(String table, List<Map<String, dynamic>> values) {
    if (values.isEmpty) return;
    
    try {
      beginTransaction();
      try {
        for (var value in values) {
          insert(table, value);
        }
        commit();
        logger.debug('[Desktop] 批量插入成功: $table, 数量=${values.length}');
      } catch (e) {
        rollback();
        rethrow;
      }
    } catch (e) {
      logger.debug('[Desktop] 批量插入失败: $table, $e');
      rethrow;
    }
  }
  
  // ============ 资源管理 ============
  
  @override
  void close() {
    try {
      _db.dispose();
      logger.debug('[Desktop] 数据库已关闭');
    } catch (e) {
      logger.debug('[Desktop] 关闭数据库失败: $e');
      rethrow;
    }
  }
}
