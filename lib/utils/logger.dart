import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error }

/// 全局日志工具类
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  File? _logFile;
  IOSink? _logSink;
  bool _initialized = false;
  final _buffer = <String>[];
  Timer? _flushTimer;
  String? _currentUserId; // 当前用户ID

  /// 获取日志级别的图标和颜色
  static String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// 获取日志级别的文本
  static String _getLevelText(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO ';
      case LogLevel.warning:
        return 'WARN ';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  /// 初始化日志系统
  /// [userId] 用户ID，可选参数。如果提供，日志文件名将包含用户ID
  Future<void> init({String? userId}) async {
    // 如果已经初始化且用户ID相同，则不重复初始化
    if (_initialized && _currentUserId == userId) return;

    // 如果用户ID不同，先关闭旧的日志文件
    if (_initialized && _currentUserId != userId) {
      await _closeLogFile();
    }

    _currentUserId = userId;

    try {
      // 使用项目根目录下的 logs 文件夹（使用绝对路径）
      final currentDir = Directory.current;
      final logsDir = Directory('${currentDir.path}/logs');

      // 创建日志目录
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // 生成日志文件名（按用户ID和日期）
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final logFileName = userId != null
          ? 'youdu_${userId}_$dateStr.log'
          : 'youdu_$dateStr.log';
      _logFile = File('${logsDir.path}/$logFileName');

      // 检查日志文件是否存在异常（如大量空字符）
      if (await _logFile!.exists()) {
        try {
          final fileSize = await _logFile!.length();
          if (fileSize > 0) {
            // 读取文件开头的一小部分来检查是否有大量空字符
            final bytes = await _logFile!
                .openRead(0, min(1024, fileSize))
                .first;
            int nullCount = 0;
            for (var byte in bytes) {
              if (byte == 0) nullCount++;
            }
            // 如果超过50%是空字符，认为文件异常
            if (nullCount > bytes.length * 0.5) {
              print('⚠️ 检测到日志文件异常（包含大量空字符），将删除并重建');
              print('  文件大小: $fileSize 字节');
              print('  空字符数量: $nullCount / ${bytes.length}');

              // 备份异常文件以便调试
              final backupFile = File(
                '${_logFile!.path}.corrupted_${now.millisecondsSinceEpoch}',
              );
              await _logFile!.copy(backupFile.path);
              print('  已备份异常文件到: ${backupFile.path}');

              // 删除异常文件并创建新文件
              await _logFile!.delete();
              await _logFile!.create();
              print('  已重新创建日志文件');
            }
          }
        } catch (e) {
          print('❌ 检查日志文件时出错: $e');
          // 如果检查失败，尝试删除并重建
          try {
            await _logFile!.delete();
            await _logFile!.create();
          } catch (e2) {
            print('❌ 无法删除/创建日志文件: $e2');
          }
        }
      }

      // 打开日志文件用于追加写入
      _logSink = _logFile!.openWrite(mode: FileMode.append);

      // 写入启动标记
      final startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final separator = '=' * 80;
      _logSink!.writeln('\n$separator');
      _logSink!.writeln('应用启动时间: $startTime');
      _logSink!.writeln(separator);
      await _logSink!.flush();

      _initialized = true;

      // 启动定时刷新（每5秒刷新一次缓冲区）
      _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        await _flush();
      });

      // 记录初始化成功消息（直接写入，避免循环调用）
      _directLog('✅ 日志系统初始化成功');
      _directLog('📁 日志文件路径: ${_logFile!.path}');

      // 清理旧日志文件（保留最近7天）
      _cleanOldLogs(logsDir);
    } catch (e) {
      print('❌ 日志系统初始化失败: $e');
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs(Directory logsDir) async {
    try {
      final now = DateTime.now();
      final files = logsDir.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          // 删除7天前的日志
          if (age.inDays > 7) {
            await file.delete();
            _directLog('🗑️ 删除旧日志: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('⚠️ 清理旧日志失败: $e');
    }
  }

  /// 直接记录日志（用于logger内部，避免循环调用）
  void _directLog(String message) {
    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm:ss.SSS').format(now);
    final logMessage = '[$timestamp] ℹ️ [INFO ] $message';

    // 输出到控制台
    print(logMessage);

    // 写入文件（注意：初始化过程中可能还没有 _logSink）
    if (_logSink != null) {
      try {
        _logSink!.writeln(logMessage);
        _logSink!.flush();
      } catch (e) {
        print('⚠️ 写入日志失败: $e');
      }
    }
  }

  /// 清理字符串，移除控制字符
  String _cleanString(String input) {
    if (input.isEmpty) return input;
    
    // 移除null字节和其他控制字符，但保留换行符和制表符
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// 写入日志
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm:ss.SSS').format(now);
    final levelIcon = _getLevelIcon(level);
    final levelText = _getLevelText(level);

    // 清理输入消息，防止控制字符污染
    final cleanMessage = _cleanString(message);

    // 格式化日志消息
    final logMessage = '[$timestamp] $levelIcon [$levelText] $cleanMessage';

    // 输出到控制台（保持原有的打印方式）
    print(logMessage);

    // 如果有错误信息，也打印
    if (error != null) {
      final cleanError = _cleanString(error.toString());
      print('  错误详情: $cleanError');
    }
    if (stackTrace != null) {
      final cleanStackTrace = _cleanString(stackTrace.toString());
      print('  堆栈跟踪:\n$cleanStackTrace');
    }

    // 写入文件
    if (_initialized && _logSink != null) {
      try {
        _buffer.add(logMessage);
        if (error != null) {
          final cleanError = _cleanString(error.toString());
          _buffer.add('  错误详情: $cleanError');
        }
        if (stackTrace != null) {
          final cleanStackTrace = _cleanString(stackTrace.toString());
          _buffer.add('  堆栈跟踪:\n$cleanStackTrace');
        }

        // 如果缓冲区太大，立即刷新（不等待完成）
        if (_buffer.length > 100) {
          _flush().catchError((e) {
            print('⚠️ 异步刷新失败: $e');
          });
        }
      } catch (e) {
        print('⚠️ 写入日志文件失败: $e');
      }
    }
  }

  /// 刷新缓冲区到文件
  Future<void> _flush() async {
    if (_buffer.isEmpty || _logSink == null) return;

    try {
      for (var line in _buffer) {
        // 🔴 FIX: 过滤掉空字符串和仅包含空白字符的行，避免写入大量空白内容
        if (line.trim().isNotEmpty) {
          // 额外检查：确保行中不包含空字符和其他控制字符
          var cleanedLine = line.replaceAll('\x00', ''); // 移除null字节
          cleanedLine = cleanedLine.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ''); // 移除其他控制字符
          
          if (cleanedLine.trim().isNotEmpty) {
            _logSink!.writeln(cleanedLine);
          }
        }
      }
      await _logSink!.flush();
      _buffer.clear();
    } catch (e) {
      print('⚠️ 刷新日志缓冲区失败: $e');
      // 如果刷新失败，清空缓冲区避免累积
      _buffer.clear();
    }
  }

  /// 调试日志
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// 信息日志
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// 警告日志
  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// 错误日志
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  /// 关闭日志文件（内部方法，用于切换用户时关闭旧文件）
  Future<void> _closeLogFile() async {
    _flushTimer?.cancel();

    // 安全关闭 sink
    if (_logSink != null) {
      try {
        // 先写入剩余的缓冲区内容
        if (_buffer.isNotEmpty) {
          for (var line in _buffer) {
            _logSink!.writeln(line);
          }
          _buffer.clear();
        }
        // 关闭文件（close 会自动 flush）
        await _logSink!.close();
        _logSink = null;
      } catch (e) {
        print('! 关闭日志文件失败: $e');
      }
    }
  }

  /// 关闭日志系统
  Future<void> close() async {
    if (!_initialized) return; // 已经关闭，直接返回

    // 先标记为未初始化，避免后续写入
    _initialized = false;

    // 直接打印到控制台，不再写入文件
    print(
      '[${DateFormat('HH:mm:ss.SSS').format(DateTime.now())}] ℹ️ [INFO ] 📕 日志系统已关闭',
    );

    await _closeLogFile();
  }

  /// 获取日志文件路径
  String? get logFilePath => _logFile?.path;
}

/// 全局日志实例
final logger = Logger();
