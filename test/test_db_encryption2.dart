import 'dart:io';
import 'dart:ffi';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

/// 数据库加密功能测试脚本（支持桌面端和移动端）
/// 
/// ============================================================
/// 使用方法 1：测试 Windows 桌面端数据库
/// ============================================================
/// dart run test_db_encryption2.dart <UUID> --windows
/// 或
/// dart run test_db_encryption2.dart <UUID>  (默认 Windows)
/// 
/// 数据库路径：C:\Users\WIN10\AppData\Local\ydapp\youdu_messages.db
/// 盐值：fAu1ZbVr12jyHzRUekU5
/// 
/// ============================================================
/// 使用方法 2：测试移动端导出的数据库
/// ============================================================
/// 
/// 步骤1：从手机导出数据库到 SD 卡
/// adb shell
/// su
/// cp /data/data/com.example.youdu/databases/youdu_messages.db /sdcard/
/// exit
/// exit
/// 
/// 步骤2：从手机拉取数据库到项目根目录
/// adb pull /sdcard/youdu_messages.db .
/// 
/// 步骤3：运行测试（指定平台）
/// dart run test_db_encryption2.dart <UUID> --android
/// 或
/// dart run test_db_encryption2.dart <UUID> --ios
/// 
/// 数据库路径：项目根目录/youdu_messages.db
/// 盐值：Android: 40BUJEyUH5L37fpEngty, iOS: xkau40vbmKL1wJ3BzT6t
/// 
/// ============================================================
/// 使用方法 3：使用 PowerShell 脚本自动获取 UUID
/// ============================================================
/// .\scripts\get_db_password.ps1 -uuid <UUID>
/// 
/// 然后根据提示选择是否运行测试
/// ============================================================
void main(List<String> args) async {
  try {
    
    // 1. 检测平台类型
    String platform = 'windows'; // 默认 Windows
    if (args.contains('--android') || args.contains('-a')) {
      platform = 'android';
    } else if (args.contains('--ios') || args.contains('-i')) {
      platform = 'ios';
    } else if (args.contains('--windows') || args.contains('-w')) {
      platform = 'windows';
    }
    
    // 初始化 SQLCipher（仅Windows平台需要）
    // if (platform == 'windows') {
      _initSQLCipher();
    // } else {
    //   print('📱 测试移动端数据库，跳过 SQLCipher 初始化');
    //   print('');
    // }
    
    // 2. 根据平台设置数据库路径
    // 支持从项目根目录或test子目录运行
    String projectRoot = Directory.current.path;
    if (projectRoot.endsWith('test')) {
      projectRoot = p.dirname(projectRoot);
    }
    
    final String dbPath;
    if (platform == 'windows') {
      // Windows 桌面端：使用 AppData 目录
      dbPath = p.join(r'C:\Users\WIN10\AppData\Local\ydapp', 'youdu_messages.db');
      print('💻 测试平台: Windows 桌面端');
    } else {
      // Android/iOS 移动端：使用项目根目录下导出的数据库文件
      dbPath = p.join(projectRoot, 'youdu_messages.db');
      print('📱 测试平台: ${platform == 'android' ? 'Android' : 'iOS'} 移动端');
    }
    
    print('📂 数据库路径: $dbPath');
    print('');
    
    // 3. 获取 UUID（从命令行参数或手动输入）
    String? uuid;
    
    // 过滤掉所有平台参数
    final uuidArgs = args.where((arg) => 
      arg != '--android' && arg != '-a' &&
      arg != '--ios' && arg != '-i' &&
      arg != '--windows' && arg != '-w' &&
      arg != '--mobile' && arg != '-m'
    ).toList();
    
    if (uuidArgs.isNotEmpty) {
      // 从命令行参数获取 UUID
      uuid = uuidArgs[0];
      print('📱 从命令行参数读取 UUID');
      print('✅ UUID: $uuid');
    } else {
      // 手动输入 UUID
      print('📱 请输入 UUID');
      print('');
      print('💡 提示：可以使用以下命令获取 UUID:');
      print('   .\\scripts\\get_db_password.ps1');
      print('');
      stdout.write('UUID: ');
      uuid = stdin.readLineSync();
      
      if (uuid == null || uuid.isEmpty) {
        print('❌ 错误：未输入有效的 UUID');
        exit(1);
      }
      
      print('✅ UUID: $uuid');
    }
    
    // 4. 根据平台类型使用不同的盐值计算密码
    final String salt;
    switch (platform) {
      case 'android':
        salt = '40BUJEyUH5L37fpEngty';
        break;
      case 'ios':
        salt = 'xkau40vbmKL1wJ3BzT6t';
        break;
      case 'windows':
        salt = 'fAu1ZbVr12jyHzRUekU5';
        break;
      default:
        salt = 'fAu1ZbVr12jyHzRUekU5'; // 默认 Windows
    }
    
    final encryptionSource = uuid + salt;
    final md5Hash = md5.convert(utf8.encode(encryptionSource)).toString();
    final testPassword = md5Hash.substring(0, 8) + md5Hash.substring(md5Hash.length - 8);
    const keyAlgorithm = '前8位 + 后8位 = 16位密钥';
    
    print('🔐 平台盐值: $salt');
    print('🔐 MD5 哈希: $md5Hash');
    print('🔑 16位密钥: $testPassword');
    print('   算法: UUID + "$salt" → MD5 → $keyAlgorithm');
    print('');
    
    final dbFile = File(dbPath);
    
    if (!dbFile.existsSync()) {
      print('❌ 错误：数据库文件不存在: $dbPath');
      print('   请先运行应用程序创建数据库');
      exit(1);
    }
    
    print('📂 数据库文件: $dbPath');
    print('📊 文件大小: ${(dbFile.lengthSync() / 1024).toStringAsFixed(2)} KB');
    print('');
    print('========================================');
    print('开始测试数据库加密...');
    print('========================================');
    print('');
  
    // 测试1：正确密码应该能访问
    print('🔍 测试1: 使用正确密码访问数据库');
    bool canOpenWithCorrectPassword = false;
    try {
      var db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = '$testPassword';");
      final result = db.select('SELECT count(*) as count FROM messages;');
      final count = result.first['count'] as int;
      canOpenWithCorrectPassword = true;
      print('   ✅ 成功：正确密码可以访问');
      print('   📝 数据库包含 $count 条消息记录');
      
      // 显示前3条记录作为示例
      if (count > 0) {
        final messages = db.select('SELECT id, content, message_type, created_at FROM messages LIMIT 3;');
        print('   📋 前3条记录示例:');
        for (var row in messages) {
          final content = (row['content'] as String).length > 30 
              ? '${(row['content'] as String).substring(0, 30)}...' 
              : row['content'];
          print('      - ID: ${row['id']}, 类型: ${row['message_type']}, 内容: $content');
        }
      }
      db.dispose();
    } catch (e) {
      print('   ❌ 失败：正确密码无法访问！');
      print('   错误信息: $e');
    }
    print('');
    
    // 测试2：错误密码应该无法访问
    print('🔍 测试2: 使用错误密码访问数据库');
    bool cannotOpenWithWrongPassword = false;
    try {
      var db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = 'wrongpassword123';");
      final result = db.select('SELECT count(*) as count FROM messages;');
      print('   ❌ 失败：错误密码能够访问（数据库可能未加密）');
      db.dispose();
    } catch (e) {
      cannotOpenWithWrongPassword = true;
      print('   ✅ 成功：错误密码无法访问（符合预期）');
      print('   错误信息: ${e.toString().split('\n').first}');
    }
    print('');
    
    // 测试结果汇总
    print('========================================');
    print('测试结果汇总');
    print('========================================');
    print('');
    if (canOpenWithCorrectPassword && cannotOpenWithWrongPassword) {
      print('🎉 所有测试通过！数据库加密功能正常');
      print('   ✓ 正确密码可以访问');
      print('   ✓ 错误密码无法访问');
      print('');
      print('📋 测试信息:');
      final platformName = platform == 'android' ? 'Android 移动端' 
          : platform == 'ios' ? 'iOS 移动端' 
          : 'Windows 桌面端';
      print('   测试平台: $platformName');
      print('   数据库路径: $dbPath');
      print('');
      print('💡 使用的密钥生成算法:');
      print('   平台: $platform');
      print('   UUID: $uuid');
      print('   盐值: $salt');
      print('   MD5 哈希: $md5Hash');
      print('   密钥: $testPassword (前8位 + 后8位 = 16位)');
    } else {
      print('⚠️  测试未完全通过');
      if (!canOpenWithCorrectPassword) {
        print('   ✗ 正确密码无法访问数据库');
      }
      if (!cannotOpenWithWrongPassword) {
        print('   ✗ 错误密码能够访问数据库（可能未加密）');
      }
    }
    print('');
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
      print('  ✓ 配置 SQLCipher (Windows)');
      print('  ✓ DLL 路径: $dllPath');
    } else if (Platform.isMacOS) {
      open.overrideFor(
        OperatingSystem.macOS,
        () => DynamicLibrary.open('libsqlcipher.dylib'),
      );
      print('  ✓ 配置 SQLCipher (macOS)');
    } else if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlcipher.so'),
      );
      print('  ✓ 配置 SQLCipher (Linux)');
    }
  } catch (e) {
    print('  ✗ 加载 SQLCipher 库失败: $e');
    print('  ⚠️  将使用默认 SQLite（不加密）');
    throw e;
  }
}
