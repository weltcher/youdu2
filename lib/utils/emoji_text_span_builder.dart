import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// 表情文本解析器 - 用于输入框
class EmojiTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    // 注意：flag 包含从文本开始到当前位置的所有字符，需要检查是否以 [ 结尾
    if (flag.endsWith('[')) {
      return EmojiText(textStyle, onTap, index);
    }
    return null;
  }
}

/// 表情文本处理类 - 用于输入框
class EmojiText extends SpecialText {
  EmojiText(
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    int start,
  ) : super('[', ']', textStyle, onTap: onTap);

  @override
  InlineSpan finishText() {
    final key = getContent(); // 获取 [emotion:xxx.png] 中的内容

    // 检查是否为表情标记格式 emotion:xxx.png
    if (key.startsWith('emotion:')) {
      final emotionFile = key.substring(8); // 去掉 "emotion:" 前缀
      if (emotionFile.isNotEmpty) {
        return ImageSpan(
          AssetImage('assets/消息/emotion/$emotionFile'),
          actualText: '[$key]', // 保存原始文本，用于发送和删除
          imageWidth: 18,
          imageHeight: 18,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          fit: BoxFit.contain,
        );
      }
    }

    // 如果不是表情格式，返回原始文本
    return TextSpan(text: '[$key]', style: textStyle);
  }
}

/// 消息气泡中的表情解析器
class MessageEmojiTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    // 注意：flag 包含从文本开始到当前位置的所有字符，需要检查是否以 [ 结尾
    if (flag.endsWith('[')) {
      return MessageEmojiText(textStyle, onTap, index);
    }
    return null;
  }
}

/// 消息气泡中的表情文本处理类
class MessageEmojiText extends SpecialText {
  MessageEmojiText(
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    int start,
  ) : super('[', ']', textStyle, onTap: onTap);

  @override
  InlineSpan finishText() {
    final key = getContent();

    // 检查是否为表情标记格式 emotion:xxx.png
    if (key.startsWith('emotion:')) {
      final emotionFile = key.substring(8);
      if (emotionFile.isNotEmpty) {
        return ImageSpan(
          AssetImage('assets/消息/emotion/$emotionFile'),
          actualText: '[$key]',
          imageWidth: 20,
          imageHeight: 20,
          margin: const EdgeInsets.symmetric(horizontal: 2),
        );
      }
    }

    // 如果不是表情格式，返回原始文本
    return TextSpan(text: '[$key]', style: textStyle);
  }
}
