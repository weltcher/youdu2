/// 功能特性配置类
/// 用于控制项目中的功能模块是否编译
class FeatureConfig {
  /// WebRTC 功能开关（编译时常量）
  ///
  /// 使用方法：
  ///
  /// 方式1：直接修改此文件中的 defaultValue（默认：true）
  ///   static const bool enableWebRTC = bool.fromEnvironment('ENABLE_WEBRTC', defaultValue: true);
  ///
  /// 方式2：编译时通过命令行参数控制（推荐）
  ///   启用 WebRTC：flutter run
  ///   禁用 WebRTC：flutter run --dart-define=ENABLE_WEBRTC=false
  ///   编译 Release：flutter build windows --dart-define=ENABLE_WEBRTC=false
  ///
  /// 注意：
  /// 1. 如果设置为 false，需要在 pubspec.yaml 中注释掉以下依赖：
  ///    - flutter_webrtc
  ///    - permission_handler
  /// 2. 修改后运行：flutter pub get
  /// 3. 清理缓存：flutter clean
  /// 4. 重新编译项目
  static const bool enableWebRTC = bool.fromEnvironment(
    'ENABLE_WEBRTC',
    defaultValue: true, // 修改此处来改变默认值：true=启用，false=禁用
  );

  /// 其他功能开关可以在这里添加
  /// 例如：
  /// static const bool enableScreenShare = bool.fromEnvironment('ENABLE_SCREEN_SHARE', defaultValue: true);
  /// static const bool enableFileTransfer = bool.fromEnvironment('ENABLE_FILE_TRANSFER', defaultValue: true);
}
