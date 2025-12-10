import 'package:lpinyin/lpinyin.dart';

/// 排序工具类
class SortHelper {
  /// 获取用于排序的 key：
  /// - 中文：转换为不带声调的全拼并转为大写
  /// - 英文：转为大写
  /// - 其他字符：原样返回（最终分组到 '#')
  static String getSortKey(String text) {
    if (text.isEmpty) return 'ZZZZ';

    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'ZZZZ';

    // 使用拼音库将中文转换为拼音；非中文字符会原样保留
    final pinyin = PinyinHelper.getPinyinE(
      trimmed,
      separator: '',
      format: PinyinFormat.WITHOUT_TONE,
    );

    if (pinyin.isEmpty) return 'ZZZZ';
    return pinyin.toUpperCase();
  }

  /// 获取字符串的首字母（用于分组/索引）
  /// - 中文：使用拼音的首字母
  /// - 英文：使用首字母（大写）
  /// - 其他：返回 '#'
  static String getFirstLetter(String text) {
    if (text.isEmpty) return '#';

    final key = getSortKey(text);
    if (key.isEmpty) return '#';

    final firstChar = key[0];
    final code = firstChar.codeUnitAt(0);

    // A-Z
    if (code >= 65 && code <= 90) {
      return firstChar;
    }

    return '#';
  }

  /// 按名称（拼音）正向排序，A-Z
  static int compareByName(String name1, String name2) {
    final n1 = name1.trim();
    final n2 = name2.trim();

    final empty1 = n1.isEmpty;
    final empty2 = n2.isEmpty;
    if (empty1 && empty2) return 0;
    if (empty1) return 1; // 空名称排在后面
    if (empty2) return -1;

    final key1 = getSortKey(n1);
    final key2 = getSortKey(n2);

    return key1.compareTo(key2);
  }

  /// 对联系人列表按名称排序
  static List<T> sortContactsByName<T>(List<T> contacts, String Function(T) getName) {
    final sorted = List<T>.from(contacts);
    sorted.sort((a, b) => compareByName(getName(a), getName(b)));
    return sorted;
  }

  /// 对群组列表按名称排序
  static List<T> sortGroupsByName<T>(List<T> groups, String Function(T) getName) {
    final sorted = List<T>.from(groups);
    sorted.sort((a, b) => compareByName(getName(a), getName(b)));
    return sorted;
  }
}

