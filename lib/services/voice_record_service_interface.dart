// 语音录制服务接口定义
// 所有平台实现都需要遵循此接口

/// OSS上传信息
class OssUploadInfo {
  final String uploadUrl;
  final String fileUrl;
  final String contentType;

  OssUploadInfo({
    required this.uploadUrl,
    required this.fileUrl,
    required this.contentType,
  });

  factory OssUploadInfo.fromJson(Map<String, dynamic> json) {
    return OssUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      fileUrl: json['fileUrl'] as String,
      contentType: json['contentType'] as String? ?? 'audio/ogg',
    );
  }
}
