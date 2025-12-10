/// Agora 配置文件
/// 请在 https://console.agora.io/ 获取您的 App ID 和 Token
class AgoraConfig {
  /// Agora App ID
  /// 获取方式：
  /// 1. 访问 https://console.agora.io/
  /// 2. 创建项目或使用现有项目
  /// 3. 复制 App ID
  static const String appId = '0a6811ffcb48409884217b2de7010ece';

  ///  Token（可选）
  /// 生产环境建议使用 Token 进行身份验证
  /// 开发测试阶段可以设置为空字符串
  /// Token 生成方式：https://docs.agora.io/cn/Agora%20Platform/token
  static const String token = '';
}
