import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../utils/logger.dart';

/// 图片预加载服务
/// 
/// 核心原理：
/// 1. 使用 HTTP 下载图片的二进制数据（Uint8List）
/// 2. 将图片数据存储在内存 Map 中
/// 3. 聊天页面显示图片时，优先从内存缓存读取
/// 
/// 实现微信级图片加载体验：
/// 1. 首次登录后，预加载会话列表中每个会话前20条消息的图片数据
/// 2. 下拉加载历史消息时，预加载新加载的图片数据
/// 3. 收到新图片消息时，立即预加载图片数据
class ImagePreloadService {
  static final ImagePreloadService _instance = ImagePreloadService._internal();
  factory ImagePreloadService() => _instance;
  ImagePreloadService._internal();

  // 🔴 核心：图片数据缓存（URL -> 图片二进制数据）
  final Map<String, Uint8List> _imageDataCache = {};
  
  // 已预加载的图片URL集合（避免重复预加载）
  final Set<String> _preloadedUrls = {};
  
  // 正在预加载的URL集合（避免并发重复）
  final Set<String> _loadingUrls = {};

  /// 获取缓存的图片数据
  /// 返回 null 表示未缓存
  Uint8List? getImageData(String imageUrl) {
    return _imageDataCache[imageUrl];
  }

  /// 检查图片数据是否已缓存
  bool hasImageData(String imageUrl) {
    return _imageDataCache.containsKey(imageUrl);
  }

  /// 预加载单张图片到内存（下载二进制数据）
  /// 
  /// [imageUrl] 图片URL
  /// [delayMs] 延迟毫秒数（用于限流）
  /// [context] 可选的BuildContext，如果提供则同时使用precacheImage
  Future<void> preloadImage(
    BuildContext? context,
    String imageUrl, {
    int delayMs = 0,
  }) async {
    // 检查URL有效性
    if (imageUrl.isEmpty) return;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return;
    }
    
    // 检查是否已预加载或正在加载
    if (_preloadedUrls.contains(imageUrl) || _loadingUrls.contains(imageUrl)) {
      return;
    }
    
    _loadingUrls.add(imageUrl);
    
    try {
      // 延迟（用于限流）
      if (delayMs > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      
      // 🔴 核心：下载图片二进制数据
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // 存储图片数据到内存缓存
        _imageDataCache[imageUrl] = response.bodyBytes;
        _preloadedUrls.add(imageUrl);
        logger.debug('✅ [图片预加载] 已缓存图片数据到内存: $imageUrl (${_formatBytes(response.bodyBytes.length)})');
        
        // 如果提供了context，同时使用precacheImage缓存到Flutter的ImageCache
        if (context != null && context.mounted) {
          try {
            await precacheImage(
              MemoryImage(response.bodyBytes),
              context,
            );
          } catch (e) {
            // precacheImage失败不影响主流程
            logger.debug('⚠️ [图片预加载] precacheImage失败: $e');
          }
        }
      } else {
        logger.debug('❌ [图片预加载] HTTP错误: ${response.statusCode}, URL: $imageUrl');
      }
    } catch (e) {
      logger.debug('❌ [图片预加载] 失败: $imageUrl, 错误: $e');
    } finally {
      _loadingUrls.remove(imageUrl);
    }
  }

  /// 预加载消息列表中的图片（带限流）
  Future<void> preloadMessagesImages(
    BuildContext? context,
    List<MessageModel> messages, {
    int delayBetweenMs = 30,
  }) async {
    // 提取图片URL
    final imageUrls = _extractImageUrls(messages);
    
    if (imageUrls.isEmpty) {
      return;
    }
    
    logger.debug('📷 [图片预加载] 开始预加载 ${imageUrls.length} 张图片数据到内存');
    
    for (final url in imageUrls) {
      // 检查context是否仍然有效
      if (context != null && !context.mounted) {
        logger.debug('⚠️ [图片预加载] Context已失效，停止预加载');
        break;
      }
      
      await preloadImage(context, url, delayMs: delayBetweenMs);
    }
    
    logger.debug('✅ [图片预加载] 完成，共 ${imageUrls.length} 张图片数据已在内存中');
    logger.debug('📊 [图片预加载] 当前缓存: ${_imageDataCache.length} 张图片, 总大小: ${_formatBytes(_getTotalCacheSize())}');
  }

  /// 预加载单条新消息的图片（收到新消息时调用）
  Future<void> preloadNewMessageImage(
    BuildContext? context,
    MessageModel message,
  ) async {
    if (message.messageType != 'image') return;
    
    final imageUrl = message.content;
    if (imageUrl.isEmpty) return;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return;
    }
    
    logger.debug('📷 [图片预加载] 预加载新消息图片数据到内存');
    await preloadImage(context, imageUrl);
  }

  /// 预加载历史消息的图片（下拉加载更多时调用）
  Future<void> preloadHistoryImages(
    BuildContext? context,
    List<MessageModel> messages,
  ) async {
    await preloadMessagesImages(context, messages, delayBetweenMs: 50);
  }

  /// 从消息列表中提取图片URL
  List<String> _extractImageUrls(List<MessageModel> messages) {
    return messages
        .where((msg) =>
            msg.messageType == 'image' &&
            msg.status != 'uploading' &&
            msg.status != 'failed' &&
            msg.content.isNotEmpty &&
            !msg.content.startsWith('/') &&
            !msg.content.startsWith('C:') &&
            (msg.content.startsWith('http://') ||
                msg.content.startsWith('https://')))
        .map((msg) => msg.content)
        .where((url) => !_preloadedUrls.contains(url))
        .toList();
  }

  /// 清除所有缓存（登出时调用）
  void clearAll() {
    _imageDataCache.clear();
    _preloadedUrls.clear();
    _loadingUrls.clear();
    logger.debug('🗑️ [图片预加载] 已清除所有图片缓存');
  }

  /// 清除预加载记录（保留图片数据缓存）
  void clearPreloadedUrls() {
    _preloadedUrls.clear();
    _loadingUrls.clear();
    logger.debug('🗑️ [图片预加载] 已清除预加载记录');
  }

  /// 检查图片是否已预加载到内存
  bool isPreloaded(String imageUrl) {
    return _preloadedUrls.contains(imageUrl);
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'imageCount': _imageDataCache.length,
      'totalSize': _getTotalCacheSize(),
      'totalSizeFormatted': _formatBytes(_getTotalCacheSize()),
    };
  }

  /// 计算缓存总大小
  int _getTotalCacheSize() {
    int total = 0;
    for (final data in _imageDataCache.values) {
      total += data.length;
    }
    return total;
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
