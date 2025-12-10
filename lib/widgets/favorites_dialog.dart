import 'dart:io';
import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youdu/models/favorite_model.dart';
import 'package:youdu/services/api_service.dart';
import 'package:youdu/utils/storage.dart';
import 'package:youdu/utils/emoji_text_span_builder.dart';
import 'package:youdu/utils/app_localizations.dart';
import '../utils/logger.dart';

/// 收藏列表对话
class FavoritesDialog extends StatefulWidget {
  const FavoritesDialog({super.key});

  @override
  State<FavoritesDialog> createState() => _FavoritesDialogState();

  /// 显示收藏列表对话
  static void show(BuildContext context) {
    logger.debug('📱 FavoritesDialog.show 被调用');
    try {
      showDialog(
        context: context,
        builder: (context) {
          logger.debug('📱 正在构建 FavoritesDialog widget');
          return const FavoritesDialog();
        },
      );
      logger.debug('📱 showDialog 调用成功');
    } catch (e) {
      logger.debug('   showDialog 失败: $e');
      rethrow;
    }
  }
}

class _FavoritesDialogState extends State<FavoritesDialog> {
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    logger.debug('📱 FavoritesDialog initState 被调用');
    _loadFavorites();
  }

  // 加载收藏列表
  Future<void> _loadFavorites({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = '未登录';
        });
        return;
      }

      final response = await ApiService.getFavorites(
        token: token,
        page: page,
        pageSize: _pageSize,
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        final favoritesData = data['favorites'] as List?;
        final favorites = (favoritesData ?? [])
            .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _favorites = favorites;
          _currentPage = data['page'] as int? ?? 1;
          _totalPages = data['total_pages'] as int? ?? 1;
          _total = data['total'] as int? ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response['message'] ?? '加载收藏失败';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载收藏失败: $e';
      });
    }
  }

  // 删除收藏
  Future<void> _deleteFavorite(int favoriteId) async {
    try {
      final token = await Storage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未登录')));
        }
        return;
      }

      final response = await ApiService.deleteFavorite(
        token: token,
        favoriteId: favoriteId,
      );

      if (mounted) {
        if (response['code'] == 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('删除成功')));
          // 重新加载当前页面
          _loadFavorites(page: _currentPage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '删除失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  // 显示合并消息的详细对话记录
  void _showMergedMessageDetail(FavoriteModel favorite) {
    showDialog(
      context: context,
      builder: (context) => _MergedMessageDetailDialog(favorite: favorite),
    );
  }

  // 获取文件图标
  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.translate('my_favorites')),
          if (_total > 0)
            Text(
              '$_total ${l10n.translate('favorites_count')}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadFavorites(page: _currentPage),
                      child: Text(l10n.translate('retry')),
                    ),
                  ],
                ),
              )
            : _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_border, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.translate('no_favorites'), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = _favorites[index];
                        return _buildFavoriteItem(favorite);
                      },
                    ),
                  ),
                  if (_totalPages > 1) _buildPagination(),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.translate('close')),
        ),
      ],
    );
  }

  // 显示收藏详情（根据类型展示不同内容）
  void _showFavoriteDetail(FavoriteModel favorite) {
    if (favorite.messageType == 'merged') {
      _showMergedMessageDetail(favorite);
    } else {
      _showGeneralFavoriteDetail(favorite);
    }
  }

  // 显示通用收藏详情弹窗（文本、图片、文件等）
  void _showGeneralFavoriteDetail(FavoriteModel favorite) {
    showDialog(
      context: context,
      builder: (context) => _GeneralFavoriteDetailDialog(favorite: favorite),
    );
  }

  // 构建收藏项
  Widget _buildFavoriteItem(FavoriteModel favorite) {
    // 判断是否为合并的消息
    final bool isMerged = favorite.messageType == 'merged';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        // 所有收藏项都可以点击查看详情
        onTap: () => _showFavoriteDetail(favorite),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMerged
                  ? const Color(0xFFFAAD14)
                  : const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Icon(
              isMerged ? Icons.chat_bubble_outline : Icons.star,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  favorite.senderName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (isMerged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAAD14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '聊天记录',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              favorite.messageType == 'image'
                  ? Row(
                      children: [
                        const Icon(
                          Icons.image,
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '[图片]',
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      ],
                    )
                  : favorite.messageType == 'file'
                  ? Row(
                      children: [
                        Icon(
                          _getFileIcon(favorite.fileName),
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '[文件] ${favorite.fileName ?? "未知文件"}',
                          style: const TextStyle(color: Color(0xFF999999)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : favorite.messageType == 'video'
                  ? Row(
                      children: const [
                        Icon(
                          Icons.videocam,
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '[视频]',
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      ],
                    )
                  : ExtendedText(
                      favorite.content,
                      specialTextSpanBuilder: MessageEmojiTextSpanBuilder(),
                      maxLines: isMerged ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatTime(favorite.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '点击查看详情',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Color(0xFF4A90E2),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // 确认删除
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除收藏'),
                  content: const Text('确定要删除这条收藏吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteFavorite(favorite.id);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 构建分页控件
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _loadFavorites(page: _currentPage - 1)
                : null,
          ),
          const SizedBox(width: 8),
          Text('$_currentPage / $_totalPages'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _loadFavorites(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // 格式化时�?
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟';
    } else {
      return '刚刚';
    }
  }
}

/// 合并消息详细对话记录
class _MergedMessageDetailDialog extends StatelessWidget {
  final FavoriteModel favorite;

  const _MergedMessageDetailDialog({required this.favorite});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 550,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAAD14).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFFAAD14),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '聊天记录详情',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        favorite.senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // 聊天记录内容
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: _buildChatContent()),
              ),
            ),
            const SizedBox(height: 16),
            // 底部时间信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '收藏${_formatFullTime(favorite.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建聊天内容
  Widget _buildChatContent() {
    // 解析聊天记录内容
    final lines = favorite.content.split('\n');
    final List<Widget> chatWidgets = [];
    final Set<String> senders = {};
    String? leftSender; // 左侧发送者

    // 第一次遍历：收集所有发送者
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final timePattern = RegExp(r'^(\d{2}:\d{2}:\d{2})\s+(.+):$');
      final match = timePattern.firstMatch(line);
      if (match != null) {
        final sender = match.group(2)!;
        leftSender ??= sender;
        senders.add(sender);
      }
    }

    // 第二次遍历：构建消息气泡
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 跳过标题行和分隔线
      if (line.contains('【聊天记录】') || line.contains('────')) {
        chatWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
        continue;
      }

      // 空行作为分隔
      if (line.trim().isEmpty) {
        continue;
      }

      // 检查是否为时间+发送者行（格式：HH:MM:SS 发送者名:）
      final timePattern = RegExp(r'^(\d{2}:\d{2}:\d{2})\s+(.+):$');
      final match = timePattern.firstMatch(line);

      if (match != null) {
        final time = match.group(1)!;
        final sender = match.group(2)!;

        // 获取下一行作为消息内容
        String content = '';
        if (i + 1 < lines.length) {
          content = lines[i + 1];
          i++; // 跳过下一行
        }

        // 判断是否为左侧发送者
        final bool isLeft = (sender == leftSender);

        chatWidgets.add(_buildMessageBubble(time, sender, content, isLeft));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: chatWidgets,
    );
  }

  // 构建消息气泡（支持左右布局）
  Widget _buildMessageBubble(
    String time,
    String sender,
    String content,
    bool isLeft,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧发送者：先显示头像
          if (isLeft) ...[
            _buildAvatar(sender, isLeft),
            const SizedBox(width: 12),
          ],
          // 消息内容区域
          Flexible(
            child: Column(
              crossAxisAlignment: isLeft
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                // 发送者和时间
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isLeft) ...[
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        sender,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isLeft
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFF52C41A),
                        ),
                      ),
                      if (isLeft) ...[
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // 消息气泡
                Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLeft ? Colors.white : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isLeft ? 4 : 12),
                      topRight: Radius.circular(isLeft ? 12 : 4),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isLeft
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFFC8E6C9),
                      width: 1,
                    ),
                  ),
                  child: ExtendedText(
                    content,
                    specialTextSpanBuilder: MessageEmojiTextSpanBuilder(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右侧发送者：后显示头像
          if (!isLeft) ...[
            const SizedBox(width: 12),
            _buildAvatar(sender, isLeft),
          ],
        ],
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar(String sender, bool isLeft) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isLeft ? const Color(0xFF4A90E2) : const Color(0xFF52C41A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        sender.isNotEmpty ? sender[0] : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 格式化完整时间
  String _formatFullTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 通用收藏详情弹窗（文本、图片、文件等）
class _GeneralFavoriteDetailDialog extends StatefulWidget {
  final FavoriteModel favorite;

  const _GeneralFavoriteDetailDialog({required this.favorite});

  @override
  State<_GeneralFavoriteDetailDialog> createState() =>
      _GeneralFavoriteDetailDialogState();
}

class _GeneralFavoriteDetailDialogState
    extends State<_GeneralFavoriteDetailDialog> {
  bool _isDownloading = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitializing = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    // 如果是视频类型，初始化视频播放器（仅移动端）
    if (widget.favorite.messageType == 'video' &&
        (Platform.isAndroid || Platform.isIOS)) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // 初始化视频播放器
  Future<void> _initializeVideoPlayer() async {
    setState(() {
      _isVideoInitializing = true;
      _videoError = null;
    });

    try {
      final videoUrl = widget.favorite.content;
      logger.debug('📹 开始初始化视频播放器');
      logger.debug('📹 视频URL: $videoUrl');
      logger.debug('📹 文件名: ${widget.favorite.fileName}');

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      logger.debug('📹 VideoPlayerController 创建成功，开始初始化...');
      await _videoController!.initialize();
      logger.debug('📹 视频初始化成功');
      logger.debug('📹 视频时长: ${_videoController!.value.duration}');
      logger.debug('📹 视频尺寸: ${_videoController!.value.size}');
      logger.debug('📹 视频宽高比: ${_videoController!.value.aspectRatio}');

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          logger.error('📹 Chewie播放器错误: $errorMessage');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '视频播放失败',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      logger.debug('📹 ChewieController 创建成功');

      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
          _videoError = null;
        });
      }
    } catch (e, stackTrace) {
      logger.error('❌ 初始化视频播放器失败: $e');
      logger.error('❌ 堆栈跟踪: $stackTrace');

      String errorMessage = '未知错误';
      if (e.toString().contains('403')) {
        errorMessage = '视频访问被拒绝(403)，可能已过期或无权限';
      } else if (e.toString().contains('404')) {
        errorMessage = '视频文件不存在(404)';
      } else if (e.toString().contains('network')) {
        errorMessage = '网络连接失败，请检查网络';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '连接超时，请重试';
      } else if (e.toString().contains('format')) {
        errorMessage = '视频格式不支持';
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
          _videoError = errorMessage;
        });
      }
    }
  }

  // 下载文件
  Future<void> _downloadFile() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // 获取文件URL
      final fileUrl = widget.favorite.content;

      // 获取默认文件名
      String defaultFileName = widget.favorite.fileName ?? 'download';
      if (!defaultFileName.contains('.')) {
        // 如果没有扩展名，从URL中提取
        final uri = Uri.parse(fileUrl);
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          defaultFileName = segments.last;
        }
      }

      // 让用户选择保存位置
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '另存为',
        fileName: defaultFileName,
      );

      if (outputPath == null) {
        // 用户取消
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      logger.debug('开始下载文件: $fileUrl');
      logger.debug('保存路径: $outputPath');

      // 下载文件
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        // 保存文件
        final file = File(outputPath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('下载成功')));
        }
        logger.debug('文件下载成功: $outputPath');
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      logger.debug('下载文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  // 获取文件图标
  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_library;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 550,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMessageIcon(),
                    color: const Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMessageTypeText(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.favorite.senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // 内容区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildContent(context),
              ),
            ),
            const SizedBox(height: 16),
            // 底部时间信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '收藏于 ${_formatFullTime(widget.favorite.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取消息类型图标
  IconData _getMessageIcon() {
    switch (widget.favorite.messageType) {
      case 'image':
        return Icons.image;
      case 'file':
        return _getFileIcon(widget.favorite.fileName);
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audio_file;
      default:
        return Icons.chat;
    }
  }

  // 获取消息类型文本
  String _getMessageTypeText() {
    switch (widget.favorite.messageType) {
      case 'image':
        return '收藏的图片';
      case 'file':
        return '收藏的文件';
      case 'video':
        return '收藏的视频';
      case 'audio':
        return '收藏的音频';
      default:
        return '收藏的消息';
    }
  }

  // 构建内容区域
  Widget _buildContent(BuildContext context) {
    switch (widget.favorite.messageType) {
      case 'image':
        return _buildImageContent();
      case 'file':
        return _buildFileContent(context);
      case 'video':
        return _buildVideoContent(context);
      default:
        return _buildTextContent();
    }
  }

  // 构建文本内容
  Widget _buildTextContent() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExtendedText(
          widget.favorite.content,
          specialTextSpanBuilder: MessageEmojiTextSpanBuilder(),
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF333333),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // 构建图片内容
  Widget _buildImageContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showImagePreview(widget.favorite.content),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.favorite.content,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('图片加载失败', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击图片可放大预览',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadFile,
            icon: _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isDownloading ? '下载中...' : '下载图片'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 显示图片预览对话框
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // 图片内容
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: const Color(0xFF333333),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 60,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '图片加载失败',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 300,
                        height: 300,
                        color: const Color(0xFF333333),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建文件内容
  Widget _buildFileContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  _getFileIcon(widget.favorite.fileName),
                  size: 80,
                  color: const Color(0xFF4A90E2),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.favorite.fileName ?? '未知文件',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadFile,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isDownloading ? '下载中...' : '下载文件'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建视频内容
  Widget _buildVideoContent(BuildContext context) {
    // 桌面端：显示预览图和操作按钮
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _buildDesktopVideoContent(context);
    }

    // 移动端：使用视频播放器
    return Column(
      children: [
        // 视频播放器区域
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _isVideoInitializing
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('视频加载中...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : _chewieController != null &&
                        _videoController != null &&
                        _videoController!.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Chewie(controller: _chewieController!),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '视频加载失败',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_videoError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _videoError!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _initializeVideoPlayer();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新加载'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 视频信息和下载按钮
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 视频文件名
              if (widget.favorite.fileName != null &&
                  widget.favorite.fileName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.video_library, color: Color(0xFF4A90E2)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.favorite.fileName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // 下载按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadFile,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isDownloading ? '下载中...' : '下载视频'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建桌面端视频内容（不使用播放器）
  Widget _buildDesktopVideoContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 视频图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                const SizedBox(height: 24),
                // 标题
                const Text(
                  '视频预览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                // 文件名
                if (widget.favorite.fileName != null &&
                    widget.favorite.fileName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.video_library,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.favorite.fileName!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // 提示信息
                Text(
                  '桌面端暂不支持在线播放',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // 操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 下载按钮
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadFile,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isDownloading ? '下载中...' : '下载视频'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 本地打开按钮
                    OutlinedButton.icon(
                      onPressed: () => _openVideoLocally(),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('本地打开'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A90E2),
                        side: const BorderSide(color: Color(0xFF4A90E2)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 本地打开视频
  Future<void> _openVideoLocally() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('正在下载视频...')));
      }

      // 下载视频到临时目录
      final url = widget.favorite.content;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

      // 获取临时目录
      final tempDir = Directory.systemTemp;

      // 生成临时文件名
      String fileName = widget.favorite.fileName ?? 'video.mp4';
      // 确保文件名安全（移除路径分隔符）
      fileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final tempFilePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
      final tempFile = File(tempFilePath);

      // 保存到临时文件
      await tempFile.writeAsBytes(response.bodyBytes);

      logger.debug('视频已保存到临时文件: $tempFilePath');

      // 使用系统默认程序打开（会弹出选择对话框）
      if (Platform.isWindows) {
        // 使用 rundll32 的 OpenAs_RunDLL 会弹出"打开方式"对话框
        await Process.run('rundll32.exe', [
          'shell32.dll,OpenAs_RunDLL',
          tempFilePath,
        ]);
      } else if (Platform.isMacOS) {
        // macOS 使用 open 命令
        await Process.run('open', [tempFilePath]);
      } else if (Platform.isLinux) {
        // Linux 使用 xdg-open
        await Process.run('xdg-open', [tempFilePath]);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已打开视频')));
      }
    } catch (e) {
      logger.error('打开视频失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开失败: $e')));
      }
    }
  }

  // 格式化完整时间
  String _formatFullTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
