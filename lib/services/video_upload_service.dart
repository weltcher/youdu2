import 'oss_multipart_service.dart';

/// 视频分片上传服务
/// 
/// ⚠️ 注意：此服务现在使用OSS直传，不再走后端中转
/// 内部调用 OSSMultipartService 实现分片直传OSS
class VideoUploadService {
  // 分片大小：5MB（与OSSMultipartService默认值一致）
  static const int chunkSize = 5 * 1024 * 1024;

  // 并发数：8（与OSSMultipartService默认值一致）
  static const int maxConcurrency = 8;

  /// 分片上传视频文件（使用OSS直传）
  ///
  /// 参数:
  /// - token: 认证token
  /// - filePath: 视频文件路径
  /// - onProgress: 进度回调 (已上传字节数, 总字节数)
  ///
  /// 返回:
  /// - url: 视频URL
  /// - fileName: 文件名
  /// 
  /// 说明:
  /// - 现在使用OSS直传，不再走后端中转，速度更快
  /// - 分片大小：5MB，并发数：8
  static Future<Map<String, dynamic>> uploadVideo({
    required String token,
    required String filePath,
    Function(int uploaded, int total)? onProgress,
  }) async {
    // 直接使用OSS直传服务
    return await OSSMultipartService.uploadFile(
      token: token,
      filePath: filePath,
      fileType: 'video',
      chunkSize: chunkSize,
      maxConcurrency: maxConcurrency,
      onProgress: onProgress,
    );
  }

}
