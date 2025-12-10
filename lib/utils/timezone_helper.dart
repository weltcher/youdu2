import '../utils/logger.dart';

/// 时区处理工具类
/// 用于统一处理服务器返回的无时区信息的时间戳
class TimezoneHelper {
  /// 解析时间字符串为本地时间（上海时区 UTC+8）
  /// 
  /// 参数：
  /// - [timeString]: ISO 8601 格式的时间字符串（如 "2025-12-07T16:45:28.439531Z"）
  /// - [isGroupMessage]: 是否是群组消息（默认false）
  /// 
  /// 返回：本地时间的 DateTime 对象（UTC+8）
  static DateTime parseToShanghaiTime(String timeString, {bool isGroupMessage = false}) {
    final logger = Logger();
    String s = timeString.trim();
    
    // 兼容错误数据：如果以多个Z结尾（例如 ...ZZ），压缩为单个Z
    if (RegExp(r'Z{2,}$').hasMatch(s)) {
      s = s.replaceFirst(RegExp(r'Z+$'), 'Z');
    }

    // 解析时间戳（带兜底）
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(s);
    } catch (e) {
      // 再次尝试：移除末尾所有Z后重试
      try {
        final s2 = s.replaceFirst(RegExp(r'Z+$'), '');
        parsedTime = DateTime.parse(s2);
      } catch (e2) {
        parsedTime = DateTime.now().toUtc();
      }
    }

    // 检查时间戳是否包含 Z 后缀
    bool hasZSuffix = s.endsWith('Z');
  
    if (hasZSuffix && parsedTime.isUtc) {
      if (isGroupMessage) {
        // 群组消息：服务器返回的带Z时间实际是本地时间（UTC+8），不需要转换
        parsedTime = DateTime(
          parsedTime.year,
          parsedTime.month,
          parsedTime.day,
          parsedTime.hour,
          parsedTime.minute,
          parsedTime.second,
          parsedTime.millisecond,
          parsedTime.microsecond,
        );
      } else {
        // 私聊消息：服务器返回的带Z时间是真正的UTC时间，需要加8小时
        parsedTime = parsedTime.add(const Duration(hours: 8));
      }
    }
    
    return parsedTime;
  }
  
  /// 将 DateTime 转换为上海时区的字符串表示
  /// 
  /// 参数：
  /// - [dateTime]: DateTime 对象
  /// 
  /// 返回：ISO 8601 格式的时间字符串（上海时区 UTC+8）
  static String toShanghaiTimeString(DateTime dateTime) {
    // 如果是本地时间，减去8小时转换为UTC，然后格式化
    final utcTime = dateTime.subtract(const Duration(hours: 8));
    return utcTime.toIso8601String();
  }
}
