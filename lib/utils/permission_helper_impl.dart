/// 权限助手的实际实现选择器
/// 此文件根据配置自动选择使用真实实现还是存根实现
library;

import '../config/feature_config.dart';

// 导出真实的权限助手（使用 permission_handler 包）
export 'permission_helper_real.dart';
