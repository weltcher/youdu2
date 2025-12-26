import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:youdu/config/api_config.dart';
import '../utils/logger.dart';

/// OSS分片直传服务
/// 
/// 实现流程：
/// 1. 文件切片（5MB、10MB等）
/// 2. 调用后端API获取签名URL
/// 3. 直接PUT上传到OSS
/// 4. 完成分片上传
class OSSMultipartService {
  // 默认分片大小：5MB（可根据需要调整）
  static const int defaultChunkSize = 5 * 1024 * 1024;
  
  // 默认最大并发上传数：8
  static const int defaultMaxConcurrency = 8;
  
  // 签名URL有效期（秒）
  static const int defaultExpireSeconds = 600; // 10分钟

  /// 分片上传文件到OSS
  /// 
  /// 参数:
  /// - token: 认证token
  /// - filePath: 文件路径
  /// - fileType: 文件类型 ("image", "video", "file")
  /// - chunkSize: 分片大小（字节），默认5MB。如果不传，使用默认值
  /// - maxConcurrency: 最大并发上传数，默认8。如果不传，使用默认值
  /// - onProgress: 进度回调 (已上传字节数, 总字节数)
  /// 
  /// 返回:
  /// - url: 文件URL
  /// - objectKey: OSS对象键
  /// - fileName: 文件名
  /// 
  /// 说明:
  /// - 分片大小和并发数都有默认值，如果不传参数，代码会自动使用默认值
  /// - 默认分片大小：5MB
  /// - 默认并发数：8
  static Future<Map<String, dynamic>> uploadFile({
    required String token,
    required String filePath,
    required String fileType, // "image", "video", "file"
    int? chunkSize, // 可选，默认5MB
    int? maxConcurrency, // 可选，默认8
    Function(int uploaded, int total)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final actualChunkSize = chunkSize ?? defaultChunkSize;
      final actualMaxConcurrency = maxConcurrency ?? defaultMaxConcurrency;

      logger.debug('📤 开始分片上传: $fileName, 大小: ${fileSize} bytes, 分片大小: ${actualChunkSize ~/ (1024 * 1024)}MB, 并发数: $actualMaxConcurrency');

      // 计算分片数量
      final totalChunks = (fileSize / actualChunkSize).ceil();
      logger.debug('📦 总分片数: $totalChunks');

      // 步骤1: 初始化分片上传，获取uploadId和objectKey
      final initResult = await _initiateMultipartUpload(
        token: token,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
      );

      final uploadId = initResult['upload_id'] as String;
      final objectKey = initResult['object_key'] as String;
      final contentType = initResult['content_type'] as String?;
      final predictedUrl = initResult['predicted_oss_url'] as String?;
      
      // 保存predictedUrl供完成上传时使用
      final String? finalPredictedUrl = predictedUrl;

      logger.debug('✅ 初始化成功: uploadId=$uploadId, objectKey=$objectKey');

      // 如果只有一个分片，直接使用第一个分片的签名URL上传
      if (totalChunks == 1) {
        final firstPartUrl = initResult['first_part_url'] as String;
        final etag = await _uploadPartToOSS(
          partUrl: firstPartUrl,
          file: file,
          start: 0,
          length: fileSize,
        );

        // 完成上传
        final finalUrl = await _completeMultipartUpload(
          token: token,
          uploadId: uploadId,
          objectKey: objectKey,
          parts: [
            {'partNumber': 1, 'etag': etag}
          ],
          predictedUrl: predictedUrl,
        );

        onProgress?.call(fileSize, fileSize);
        return {
          'url': finalUrl,
          'object_key': objectKey,
          'file_name': fileName,
        };
      }

      // 多分片上传
      // 使用信号量控制并发数
      final semaphore = List.generate(actualMaxConcurrency, (_) => true);
      final futures = <Future<Map<String, dynamic>>>[];
      final parts = <Map<String, dynamic>>[];
      int uploadedBytes = 0;
      int completedParts = 0;

      // 上传所有分片
      for (int partNumber = 1; partNumber <= totalChunks; partNumber++) {
        final start = (partNumber - 1) * actualChunkSize;
        final end = (start + actualChunkSize < fileSize) ? start + actualChunkSize : fileSize;
        final partLength = end - start;

        // 等待可用的并发槽
        while (semaphore.every((slot) => !slot)) {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // 找到可用的并发槽
        int slotIndex = semaphore.indexWhere((slot) => slot);
        semaphore[slotIndex] = false;

        final future = _uploadPart(
          token: token,
          uploadId: uploadId,
          objectKey: objectKey,
          partNumber: partNumber,
          file: file,
          start: start,
          length: partLength,
        ).then((result) {
          // 释放并发槽
          semaphore[slotIndex] = true;

          // 更新进度
          completedParts++;
          uploadedBytes += partLength;
          onProgress?.call(uploadedBytes, fileSize);

          logger.debug('✅ 分片 $partNumber/$totalChunks 上传完成');
          return result;
        }).catchError((error) {
          // 释放并发槽
          semaphore[slotIndex] = true;
          logger.debug('❌ 分片 $partNumber 上传失败: $error');
          throw error;
        });

        futures.add(future);
      }

      // 等待所有分片上传完成
      final results = await Future.wait(futures);

      // 收集所有分片的ETag（按partNumber排序）
      for (var result in results) {
        parts.add({
          'partNumber': result['part_number'] as int,
          'etag': result['etag'] as String,
        });
      }
      parts.sort((a, b) => (a['partNumber'] as int).compareTo(b['partNumber'] as int));

      logger.debug('✅ 所有分片上传完成，共 ${parts.length} 个分片');

      // 步骤4: 完成分片上传
      final finalUrl = await _completeMultipartUpload(
        token: token,
        uploadId: uploadId,
        objectKey: objectKey,
        parts: parts,
        predictedUrl: finalPredictedUrl,
      );

      logger.debug('✅ 分片上传完成: $finalUrl');

      return {
        'url': finalUrl,
        'object_key': objectKey,
        'file_name': fileName,
      };
    } catch (e) {
      logger.debug('❌ OSS分片上传失败: $e');
      rethrow;
    }
  }

  /// 初始化分片上传
  static Future<Map<String, dynamic>> _initiateMultipartUpload({
    required String token,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final url = ApiConfig.getApiUrl(ApiConfig.ossInitiateMultipart);
      final requestBody = {
        'file_name': fileName,
        'file_type': fileType,
        'file_size': fileSize,
        'expire_seconds': defaultExpireSeconds,
      };
      
      logger.debug('📤 初始化分片上传请求:');
      logger.debug('   URL: $url');
      logger.debug('   请求体: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      logger.debug('📥 初始化分片上传响应:');
      logger.debug('   状态码: ${response.statusCode}');
      logger.debug('   响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['code'] == 0 || data['code'] == 200) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? '初始化分片上传失败');
        }
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '初始化分片上传失败: ${response.statusCode}');
      }
    } catch (e) {
      logger.debug('❌ 初始化分片上传失败: $e');
      rethrow;
    }
  }

  /// 获取分片签名URL并上传
  static Future<Map<String, dynamic>> _uploadPart({
    required String token,
    required String uploadId,
    required String objectKey,
    required int partNumber,
    required File file,
    required int start,
    required int length,
  }) async {
    try {
      // 获取分片签名URL
      final signResponse = await http.post(
        Uri.parse(ApiConfig.getApiUrl(ApiConfig.ossSignPart)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'upload_id': uploadId,
          'object_key': objectKey,
          'part_number': partNumber,
          'expire_seconds': defaultExpireSeconds,
        }),
      ).timeout(const Duration(seconds: 30));

      if (signResponse.statusCode != 200) {
        final errorData = json.decode(utf8.decode(signResponse.bodyBytes));
        throw Exception(errorData['message'] ?? '获取分片签名URL失败: ${signResponse.statusCode}');
      }

      final signData = json.decode(utf8.decode(signResponse.bodyBytes));
      if (signData['code'] != 0 && signData['code'] != 200) {
        throw Exception(signData['message'] ?? '获取分片签名URL失败');
      }

      final signedUrl = signData['data']['signed_url'] as String;

      // 读取分片数据
      final randomAccessFile = await file.open();
      await randomAccessFile.setPosition(start);
      final chunkData = await randomAccessFile.read(length);
      await randomAccessFile.close();

      // 直接PUT上传到OSS
      final etag = await _uploadPartToOSS(
        partUrl: signedUrl,
        chunkData: chunkData,
      );

      return {
        'part_number': partNumber,
        'etag': etag,
      };
    } catch (e) {
      logger.debug('❌ 分片 $partNumber 上传失败: $e');
      rethrow;
    }
  }

  /// 上传分片数据到OSS（使用签名URL）
  static Future<String> _uploadPartToOSS({
    String? partUrl,
    File? file,
    int? start,
    int? length,
    List<int>? chunkData,
  }) async {
    if (partUrl == null) {
      throw Exception('partUrl不能为空');
    }

    try {
      http.Request request;
      List<int> data;

      if (chunkData != null) {
        // 使用提供的数据
        data = chunkData;
      } else if (file != null && start != null && length != null) {
        // 从文件读取数据
        final randomAccessFile = await file.open();
        await randomAccessFile.setPosition(start);
        data = await randomAccessFile.read(length);
        await randomAccessFile.close();
      } else {
        throw Exception('必须提供chunkData或file+start+length');
      }

      request = http.Request('PUT', Uri.parse(partUrl));
      request.bodyBytes = data;
      request.headers['Content-Length'] = data.length.toString();

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 从响应头获取ETag
        final etag = response.headers['etag'] ?? response.headers['ETag'] ?? '';
        // 移除ETag的引号（如果有）
        return etag.replaceAll('"', '');
      } else {
        throw Exception('上传分片到OSS失败: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      logger.debug('❌ 上传分片到OSS失败: $e');
      rethrow;
    }
  }

  /// 完成分片上传
  static Future<String> _completeMultipartUpload({
    required String token,
    required String uploadId,
    required String objectKey,
    required List<Map<String, dynamic>> parts,
    String? predictedUrl,
  }) async {
    try {
      // 获取完成上传的签名URL
      final signResponse = await http.post(
        Uri.parse(ApiConfig.getApiUrl(ApiConfig.ossCompleteMultipart)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'upload_id': uploadId,
          'object_key': objectKey,
          'expire_seconds': defaultExpireSeconds,
        }),
      ).timeout(const Duration(seconds: 30));

      if (signResponse.statusCode != 200) {
        final errorData = json.decode(utf8.decode(signResponse.bodyBytes));
        throw Exception(errorData['message'] ?? '获取完成上传签名URL失败: ${signResponse.statusCode}');
      }

      final signData = json.decode(utf8.decode(signResponse.bodyBytes));
      if (signData['code'] != 0 && signData['code'] != 200) {
        throw Exception(signData['message'] ?? '获取完成上传签名URL失败');
      }

      final completeUrl = signData['data']['signed_url'] as String;

      // 构建CompleteMultipartUpload的XML body
      final xmlParts = parts.map((part) {
        return '<Part><PartNumber>${part['partNumber']}</PartNumber><ETag>${part['etag']}</ETag></Part>';
      }).join('');

      final xmlBody = '<?xml version="1.0" encoding="UTF-8"?><CompleteMultipartUpload>$xmlParts</CompleteMultipartUpload>';

      // POST到OSS完成上传
      // ⚠️ 注意：Content-Type必须与OSS签名时一致，包含charset=utf-8
      final completeResponse = await http.post(
        Uri.parse(completeUrl),
        headers: {
          'Content-Type': 'application/xml; charset=utf-8',
        },
        body: xmlBody,
      ).timeout(const Duration(seconds: 30));

      if (completeResponse.statusCode == 200) {
        // 优先使用predictedUrl（后端返回的）
        if (predictedUrl != null && predictedUrl.isNotEmpty) {
          return predictedUrl;
        }
        
        // 解析响应获取最终URL
        final xmlResponse = utf8.decode(completeResponse.bodyBytes);
        // 从XML中提取Location（文件URL）
        final locationMatch = RegExp(r'<Location>(.*?)</Location>').firstMatch(xmlResponse);
        if (locationMatch != null) {
          return locationMatch.group(1)!;
        }
        // 如果没有Location，尝试从Key构建URL
        final keyMatch = RegExp(r'<Key>(.*?)</Key>').firstMatch(xmlResponse);
        if (keyMatch != null) {
          final key = keyMatch.group(1)!;
          // 从completeUrl提取bucket和endpoint信息
          final uri = Uri.parse(completeUrl);
          return '${uri.scheme}://${uri.host}/$key';
        }
        throw Exception('无法从响应中提取文件URL');
      } else {
        throw Exception('完成分片上传失败: ${completeResponse.statusCode}, ${completeResponse.body}');
      }
    } catch (e) {
      logger.debug('❌ 完成分片上传失败: $e');
      rethrow;
    }
  }
}
