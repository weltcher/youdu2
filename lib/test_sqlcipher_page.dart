import 'dart:io';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

/// SQLCipher 加密测试页面
class TestSQLCipherPage extends StatefulWidget {
  TestSQLCipherPage({Key? key}) : super(key: key);

  @override
  State<TestSQLCipherPage> createState() => _TestSQLCipherPageState();
}

class _TestSQLCipherPageState extends State<TestSQLCipherPage> {
  final List<String> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSQLCipher();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.add('${isError ? "❌" : "✅"} $message');
    });
    print(message);
  }

  /// 初始化 SQLCipher
  void _initSQLCipher() {
    try {
      _addLog('开始配置 SQLCipher...');
      
      // 参照 drift encryption 案例的方式配置 SQLCipher
      // sqlcipher_flutter_libs 包会自动提供所需的 DLL 和 OpenSSL
      if (Platform.isWindows) {
        open.overrideFor(OperatingSystem.windows,
            () => DynamicLibrary.open('sqlcipher.dll'));
        _addLog('SQLCipher 配置成功 (Windows)');
        _addLog('使用 sqlcipher_flutter_libs 自动提供的 DLL');
      }
    } catch (e) {
      _addLog('SQLCipher 初始化失败: $e', isError: true);
    }
  }

  /// 开始测试
  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      final dbPath = p.join(Directory.current.path, 'test_encrypted.db');
      const testPassword = 'myTestPassword123';

      _addLog('========== 开始测试 ==========');
      _addLog('数据库路径: $dbPath');
      _addLog('测试密码: $testPassword');

      // 删除旧数据库
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
        _addLog('删除旧测试数据库');
      }

      // 测试1: 创建加密数据库
      _addLog('\n【测试1】创建加密数据库...');
      var db = sqlite3.open(dbPath);
      
      // 检查 SQLCipher 版本
      try {
        final versionResult = db.select('PRAGMA cipher_version');
        if (versionResult.isNotEmpty && versionResult.first['cipher_version'] != null) {
          _addLog('SQLCipher 版本: ${versionResult.first['cipher_version']}');
        } else {
          _addLog('警告：这可能不是 SQLCipher！', isError: true);
        }
      } catch (e) {
        _addLog('无法获取 cipher_version，这可能不是 SQLCipher！', isError: true);
      }

      // 设置加密密钥
      db.execute("PRAGMA key = '$testPassword';");
      _addLog('已设置加密密钥');

      // 创建表并插入数据
      db.execute('''
        CREATE TABLE test_users (
          id INTEGER PRIMARY KEY,
          name TEXT,
          email TEXT
        )
      ''');
      _addLog('创建数据表成功');

      db.execute("INSERT INTO test_users (name, email) VALUES ('张三', 'zhangsan@test.com')");
      db.execute("INSERT INTO test_users (name, email) VALUES ('李四', 'lisi@test.com')");
      _addLog('插入测试数据成功');

      db.dispose();
      _addLog('数据库已关闭');

      // 测试2: 不使用密码打开
      _addLog('\n【测试2】不使用密码尝试打开...');
      bool canOpenWithoutPassword = false;
      try {
        db = sqlite3.open(dbPath);
        final result = db.select('SELECT * FROM test_users');
        db.dispose();
        canOpenWithoutPassword = true;
        _addLog('错误：不使用密码也能打开！加密无效！', isError: true);
      } catch (e) {
        _addLog('正确：不使用密码无法访问');
      }

      // 测试3: 使用错误密码
      _addLog('\n【测试3】使用错误密码尝试打开...');
      bool canOpenWithWrongPassword = false;
      try {
        db = sqlite3.open(dbPath);
        db.execute("PRAGMA key = 'wrongPassword';");
        final result = db.select('SELECT * FROM test_users');
        db.dispose();
        canOpenWithWrongPassword = true;
        _addLog('错误：错误密码也能打开！加密无效！', isError: true);
      } catch (e) {
        _addLog('正确：错误密码无法访问');
      }

      // 测试4: 使用正确密码
      _addLog('\n【测试4】使用正确密码打开...');
      bool canOpenWithCorrectPassword = false;
      try {
        db = sqlite3.open(dbPath);
        db.execute("PRAGMA key = '$testPassword';");
        final result = db.select('SELECT * FROM test_users');
        canOpenWithCorrectPassword = true;
        _addLog('正确：正确密码可以访问');
        _addLog('查询到 ${result.length} 条记录');
        for (var row in result) {
          _addLog('  - ${row['name']}: ${row['email']}');
        }
        db.dispose();
      } catch (e) {
        _addLog('错误：正确密码无法访问！', isError: true);
      }

      // 总结
      _addLog('\n========== 测试总结 ==========');
      if (!canOpenWithoutPassword && !canOpenWithWrongPassword && canOpenWithCorrectPassword) {
        _addLog('✅✅✅ 加密功能完全正常！');
        _addLog('  ✓ 无密码 → 无法访问');
        _addLog('  ✓ 错误密码 → 无法访问');
        _addLog('  ✓ 正确密码 → 可以访问');
      } else {
        _addLog('❌❌❌ 加密功能异常！', isError: true);
        if (canOpenWithoutPassword) {
          _addLog('  ✗ 无密码也能访问', isError: true);
        }
        if (canOpenWithWrongPassword) {
          _addLog('  ✗ 错误密码也能访问', isError: true);
        }
        if (!canOpenWithCorrectPassword) {
          _addLog('  ✗ 正确密码无法访问', isError: true);
        }
      }

      if (dbFile.existsSync()) {
        dbFile.deleteSync();
        _addLog('\n测试数据库已删除');
      }

    } catch (e, stackTrace) {
      _addLog('测试过程出错: $e', isError: true);
      _addLog('堆栈跟踪: $stackTrace', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLCipher 加密测试'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 测试说明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('本测试用于验证 Windows 端 SQLCipher 加密功能是否正常工作'),
                Text('• 测试1: 创建加密数据库并插入数据'),
                Text('• 测试2: 验证无密码是否能访问'),
                Text('• 测试3: 验证错误密码是否能访问'),
                Text('• 测试4: 验证正确密码是否能访问'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('测试中...'),
                        ],
                      )
                    : Text('开始测试', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? Center(child: Text('点击"开始测试"按钮开始测试', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.startsWith('❌');
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 13,
                              color: isError ? Colors.red : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
