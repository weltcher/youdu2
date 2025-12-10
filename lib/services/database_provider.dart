/// 数据库操作抽象接口
/// 定义统一的数据库操作方法，由移动端和桌面端分别实现
abstract class DatabaseProvider {
  // ============ 基础操作 ============
  
  /// 插入数据
  /// 返回插入的行ID
  /// [orIgnore] 如果为true，使用 INSERT OR IGNORE（遇到UNIQUE约束冲突时跳过）
  int insert(String table, Map<String, dynamic> values, {bool orIgnore = false});
  
  /// 查询数据
  List<Map<String, dynamic>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  });
  
  /// 原始SQL查询
  List<Map<String, dynamic>> rawQuery(String sql, [List<Object?>? args]);
  
  /// 更新数据
  /// 返回受影响的行数
  int update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  });
  
  /// 删除数据
  /// 返回删除的行数
  int delete(String table, {String? where, List<Object?>? whereArgs});
  
  /// 原始SQL删除
  void rawDelete(String sql, [List<Object?>? args]);
  
  /// 执行SQL语句
  void execute(String sql, [List<Object?>? args]);
  
  /// 获取第一个整数值（用于COUNT等查询）
  int? firstIntValue(List<Map<String, dynamic>> results);
  
  // ============ 事务支持 ============
  
  /// 开始事务
  void beginTransaction();
  
  /// 提交事务
  void commit();
  
  /// 回滚事务
  void rollback();
  
  // ============ 批量操作 ============
  
  /// 批量插入
  void batchInsert(String table, List<Map<String, dynamic>> values);
  
  // ============ 资源管理 ============
  
  /// 关闭数据库连接
  void close();
}
