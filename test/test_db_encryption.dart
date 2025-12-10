import 'dart:io';
import 'dart:ffi';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

/// PC端数据库加密功能测试脚本
/// 测试路径: C:\Users\WIN10\AppData\Local\ydapp
/// 
/// 使用方法：
/// dart run test/test_db_encryption.dart (从项目根目录)
/// 或
/// dart run test_db_encryption.dart (从test目录)

void main() async {
  await init_db();
}

void init_db() async {
  try {
    _initSQLCipher();

    // 2. 设置测试路径
    final dbPath = p.join(r'C:\Users\WIN10\AppData\Local\ydapp', 'test_encryption.db');
    const testPassword = 'youdu_secure_db_2024'; // 与实际代码中的固定密码一致
    
    final dbDir = Directory(p.dirname(dbPath));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
      print('✅ 创建测试目录\n');
    }
    final dbFile = File(dbPath);
    var db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = '$testPassword';");

    db.execute('''
      CREATE TABLE test_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    db.execute("INSERT INTO test_messages (sender_id, receiver_id, content) VALUES (1, 2, '测试消息1')");
    db.execute("INSERT INTO test_messages (sender_id, receiver_id, content) VALUES (2, 1, '测试消息2')");
    db.execute("INSERT INTO test_messages (sender_id, receiver_id, content) VALUES (1, 2, '测试消息3')");
    print('✅ 插入3条测试数据\n');
    db.dispose();

    // 6. 测试正确密码访问
    print('步骤7: 测试正确密码访问（应该成功）...');
    bool canOpenWithCorrectPassword = false;
    try {
      db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = '$testPassword';");
      final result = db.select('SELECT * FROM test_messages');
      canOpenWithCorrectPassword = true;
      print('✅ 正确：正确密码可以访问');
      print('   查询到 ${result.length} 条记录');
      for (var row in result) {
        print('   - ID: ${row['id']}, 内容: ${row['content']}');
      }
      print('');
      db.dispose();
    } catch (e) {
      print('❌ 错误：正确密码无法访问！');
      print('   错误信息: $e\n');
    }
  } catch (e, stackTrace) {
    print('\n❌ 测试过程出错: $e');
    print('堆栈跟踪: $stackTrace');
    exit(1);
  }
}

/// 初始化 SQLCipher
void _initSQLCipher() {
  try {
    if (Platform.isWindows) {
      // Windows: 使用完整路径加载 SQLCipher DLL
      // 支持从项目根目录或test子目录运行
      String projectRoot = Directory.current.path;
      if (projectRoot.endsWith('test')) {
        projectRoot = p.dirname(projectRoot);
      }
      
      final dllPath = p.join(
        projectRoot,
        'build',
        'windows',
        'x64',
        'runner',
        'Debug',
        'sqlcipher.dll',
      );
      
      if (!File(dllPath).existsSync()) {
        throw Exception('SQLCipher DLL 不存在: $dllPath\n请先运行: flutter build windows 或 flutter run -d windows');
      }
      
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open(dllPath),
      );
    } else if (Platform.isMacOS) {
      open.overrideFor(
        OperatingSystem.macOS,
        () => DynamicLibrary.open('libsqlcipher.dylib'),
      );
    } else if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlcipher.so'),
      );
    }
  } catch (e) {
    print('  ✗ 加载 SQLCipher 库失败: $e');
    print('  ⚠️  将使用默认 SQLite（不加密）');
    throw e;
  }
}
