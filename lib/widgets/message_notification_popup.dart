import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

/// 新消息通知弹窗组件（类似微信的消息弹窗）
/// 在屏幕顶部显示新消息通知，包含头像、名称、消息内容
class MessageNotificationPopup extends StatefulWidget {
  final String title; // 发送者名称或群组名称
  final String message; // 消息内容（已格式化）
  final String? avatar; // 头像URL
  final String? senderName; // 发送者姓名（用于生成文字头像）
  final VoidCallback? onTap; // 点击回调
  final Duration displayDuration; // 显示时长
  final bool isGroup; // 是否为群聊消息

  const MessageNotificationPopup({
    Key? key,
    required this.title,
    required this.message,
    this.avatar,
    this.senderName,
    this.onTap,
    this.displayDuration = const Duration(seconds: 3),
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<MessageNotificationPopup> createState() => _MessageNotificationPopupState();

  /// 在指定context中显示弹窗
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? avatar,
    String? senderName,
    VoidCallback? onTap,
    Duration displayDuration = const Duration(seconds: 3),
    bool isGroup = false,
  }) {
    try {
      // 如果已有弹窗，先移除
      dismiss();

      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => MessageNotificationPopup(
          title: title,
          message: message,
          avatar: avatar,
          senderName: senderName,
          onTap: onTap,
          displayDuration: displayDuration,
          isGroup: isGroup,
        ),
      );

      overlay.insert(overlayEntry);
      _currentOverlay = overlayEntry;

      logger.debug('🔔 显示消息弹窗: $title - $message');
    } catch (e) {
      logger.error('显示消息弹窗失败: $e');
    }
  }

  /// 关闭当前弹窗
  static void dismiss() {
    if (_currentOverlay != null) {
      try {
        _currentOverlay?.remove();
        _currentOverlay = null;
        logger.debug('🔔 关闭消息弹窗');
      } catch (e) {
        logger.error('关闭消息弹窗失败: $e');
        _currentOverlay = null;
      }
    }
  }
}

class _MessageNotificationPopupState extends State<MessageNotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 下滑进入动画
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 淡入淡出动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // 开始进入动画
    _animationController.forward();

    // 自动关闭
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 关闭弹窗（带动画）
  void _dismiss() async {
    try {
      await _animationController.reverse();
      MessageNotificationPopup.dismiss();
    } catch (e) {
      logger.error('关闭弹窗动画失败: $e');
      MessageNotificationPopup.dismiss();
    }
  }

  // 处理点击事件
  void _handleTap() {
    widget.onTap?.call();
    _dismiss();
  }

  // 处理向上滑动手势（关闭弹窗）
  void _handleDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _handleTap,
            onVerticalDragEnd: _handleDragEnd,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 头像
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    // 内容区域
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题（发送者名称或群组名称）
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // 消息内容
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 关闭按钮
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar() {
    Widget avatarWidget;

    if (widget.avatar != null && widget.avatar!.isNotEmpty) {
      // 使用网络头像
      avatarWidget = CachedNetworkImage(
        imageUrl: '${ApiConfig.baseUrl}${widget.avatar}',
        placeholder: (context, url) => _buildPlaceholderAvatar(),
        errorWidget: (context, url, error) => _buildPlaceholderAvatar(),
        fit: BoxFit.cover,
      );
    } else {
      // 使用默认头像
      avatarWidget = _buildPlaceholderAvatar();
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarWidget,
    );
  }

  // 构建占位头像（文字头像，与对话框保持一致）
  Widget _buildPlaceholderAvatar() {
    // 生成头像文字（取名字最后两个字）
    String avatarText = '';
    final displayName = widget.senderName ?? widget.title;
    if (displayName.isNotEmpty) {
      avatarText = displayName.length >= 2
          ? displayName.substring(displayName.length - 2)
          : displayName;
    }

    return Container(
      color: const Color(0xFF4A90E2), // 与对话框保持一致的蓝色
      child: Center(
        child: Text(
          avatarText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16, // 稍大一些，适配48x48的头像
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
