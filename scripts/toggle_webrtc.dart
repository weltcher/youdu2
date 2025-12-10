/// WebRTC 功能开关切换脚本
///
/// 使用方法：
///   dart scripts/toggle_webrtc.dart on   # 启用 WebRTC
///   dart scripts/toggle_webrtc.dart off  # 禁用 WebRTC
///
/// 此脚本会自动修改相关文件来启用或禁用 WebRTC 功能
library;

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || (args[0] != 'on' && args[0] != 'off')) {
    print('❌ 用法: dart scripts/toggle_webrtc.dart [on|off]');
    print('   on  - 启用 WebRTC 功能');
    print('   off - 禁用 WebRTC 功能');
    exit(1);
  }

  final bool enable = args[0] == 'on';
  print('${enable ? '✅ 启用' : '⛔ 禁用'} WebRTC 功能...\n');

  try {
    // 1. 修改 webrtc_service_impl.dart
    _updateServiceImpl(enable);

    // 2. 修改 voice_call_page_impl.dart
    _updatePageImpl(enable);

    // 3. 修改 permission_helper_impl.dart
    _updatePermissionHelper(enable);

    // 4. 修改 pubspec.yaml
    _updatePubspec(enable);

    // 5. 修改 feature_config.dart 的默认值
    _updateFeatureConfig(enable);

    print('\n✅ 配置更新完成！');
    print('\n📋 下一步操作：');
    print('   1. 运行: flutter pub get');
    print('   2. 运行: flutter clean');
    print('   3. 重新编译项目');
    if (enable) {
      print('\n提示：启用 WebRTC 后，项目会依赖 flutter_webrtc 和 permission_handler');
    } else {
      print('\n提示：禁用 WebRTC 后，项目体积会减小，编译速度会加快');
    }
  } catch (e) {
    exit(1);
  }
}

void _updateServiceImpl(bool enable) {
  final file = File('lib/services/webrtc_service_impl.dart');
  final content = enable
      ? '''/// WebRTC 服务的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出真实的 WebRTC 实现
export 'webrtc_service.dart';
'''
      : '''/// WebRTC 服务的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出存根实现（空实现）
export 'webrtc_service_stub.dart';
''';

  file.writeAsStringSync(content);
  print('✓ 已更新 lib/services/webrtc_service_impl.dart');
}

void _updatePageImpl(bool enable) {
  final file = File('lib/pages/voice_call_page_impl.dart');
  final content = enable
      ? '''/// 通话页面的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出真实的通话页面
export 'voice_call_page.dart';
'''
      : '''/// 通话页面的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出存根实现（空页面）
export 'voice_call_page_stub.dart';
''';

  file.writeAsStringSync(content);
  print('✓ 已更新 lib/pages/voice_call_page_impl.dart');
}

void _updatePermissionHelper(bool enable) {
  final file = File('lib/utils/permission_helper_impl.dart');
  final content = enable
      ? '''/// 权限助手的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出真实的权限助手（使用 permission_handler 包）
export 'permission_helper_real.dart';
'''
      : '''/// 权限助手的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现

import '../config/feature_config.dart';

// 导出存根实现（当 WebRTC 禁用时）
export 'permission_helper_stub.dart';
''';

  file.writeAsStringSync(content);
  print('✓ 已更新 lib/utils/permission_helper_impl.dart');
}

void _updatePubspec(bool enable) {
  final file = File('pubspec.yaml');
  var content = file.readAsStringSync();

  if (enable) {
    // 取消注释 WebRTC 依赖
    content = content
        .replaceAll('# flutter_webrtc:', 'flutter_webrtc:')
        .replaceAll('# permission_handler:', 'permission_handler:');
  } else {
    // 注释掉 WebRTC 依赖
    content = content
        .replaceAll(
          RegExp(r'^  flutter_webrtc:', multiLine: true),
          '  # flutter_webrtc:',
        )
        .replaceAll(
          RegExp(r'^  permission_handler:', multiLine: true),
          '  # permission_handler:',
        );
  }

  file.writeAsStringSync(content);
  print('✓ 已更新 pubspec.yaml');
}

void _updateFeatureConfig(bool enable) {
  final file = File('lib/config/feature_config.dart');
  var content = file.readAsStringSync();

  final newDefaultValue = enable ? 'true' : 'false';
  content = content.replaceAll(
    RegExp(r'defaultValue:\s*(true|false)'),
    'defaultValue: $newDefaultValue',
  );

  file.writeAsStringSync(content);
  print(
    '✓ 已更新 lib/config/feature_config.dart (defaultValue: $newDefaultValue)',
  );
}
