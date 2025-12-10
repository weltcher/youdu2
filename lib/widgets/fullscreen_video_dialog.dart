import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora_service.dart';

/// 全屏视频展示弹窗
/// 用于在群组视频通话中全屏展示某个成员的摄像头画面
class FullscreenVideoDialog extends StatefulWidget {
  final String memberName;
  final int userId;
  final bool isLocalVideo;
  final String? channelId;
  final bool isMobile;

  const FullscreenVideoDialog({
    super.key,
    required this.memberName,
    required this.userId,
    this.isLocalVideo = false,
    this.channelId,
    this.isMobile = false,
  });

  @override
  State<FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();

  /// 显示全屏视频对话框
  static Future<void> show({
    required BuildContext context,
    required String memberName,
    required int userId,
    bool isLocalVideo = false,
    String? channelId,
    bool isMobile = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true, // 允许点击背景关闭
      barrierColor: Colors.black, // 黑色背景
      builder: (context) => FullscreenVideoDialog(
        memberName: memberName,
        userId: userId,
        isLocalVideo: isLocalVideo,
        channelId: channelId,
        isMobile: isMobile,
      ),
    );
  }
}

class _FullscreenVideoDialogState extends State<FullscreenVideoDialog> {
  AgoraVideoView? _fullscreenVideoView;

  @override
  void initState() {
    super.initState();
    _createFullscreenVideoView();
  }

  @override
  void dispose() {
    _disposeFullscreenVideoView();
    super.dispose();
  }

  /// 创建全屏视频视图
  void _createFullscreenVideoView() async {
    try {
      // 获取Agora引擎实例
      final engine = await _getAgoraEngine();
      if (engine == null) {
        debugPrint('❌ 无法获取Agora引擎实例');
        return;
      }

      if (widget.isLocalVideo) {
        // 本地视频：创建新的本地视频视图
        _fullscreenVideoView = AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        );
      } else {
        // 远程视频：创建新的远程视频视图
        _fullscreenVideoView = AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: engine,
            canvas: VideoCanvas(uid: widget.userId),
            connection: RtcConnection(channelId: widget.channelId),
          ),
        );
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ 创建全屏视频视图失败: $e');
    }
  }

  /// 获取Agora引擎实例
  Future<RtcEngine?> _getAgoraEngine() async {
    try {
      // 通过AgoraService获取引擎实例
      final agoraService = AgoraService();
      return agoraService.engine;
    } catch (e) {
      debugPrint('❌ 获取Agora引擎失败: $e');
      return null;
    }
  }

  /// 销毁全屏视频视图
  void _disposeFullscreenVideoView() {
    try {
      // 不需要手动销毁，让系统自动处理
      _fullscreenVideoView = null;
    } catch (e) {
      debugPrint('❌ 销毁全屏视频视图失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // 占满整个屏幕
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // 全屏视频内容 - 添加点击关闭功能（移动端）
          Positioned.fill(
            child: GestureDetector(
              // 移动端点击视频区域关闭弹窗
              onTap: widget.isMobile ? () {
                debugPrint('📱 [移动端全屏] 点击视频区域，关闭全屏弹窗');
                Navigator.of(context).pop();
              } : null,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: _fullscreenVideoView != null
                      ? widget.isMobile
                          ? // 移动端：占满整个屏幕
                            SizedBox.expand(
                              child: ClipRRect(
                                borderRadius: BorderRadius.zero, // 移动端无圆角
                                child: _fullscreenVideoView!,
                              ),
                            )
                          : // PC端：保持原有的16:9比例
                            AspectRatio(
                              aspectRatio: 16 / 9, // 标准视频比例
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _fullscreenVideoView!,
                              ),
                            )
                      : widget.isMobile
                          ? // 移动端：占满整个屏幕的占位符
                            SizedBox.expand(
                              child: Container(
                                color: Colors.grey[900],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.isLocalVideo ? Icons.videocam : Icons.person,
                                      size: 120, // 移动端图标更大
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      widget.isLocalVideo ? '本地视频' : '远程视频',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 24, // 移动端文字更大
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '正在连接视频...',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : // PC端：保持原有的圆形占位符
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isLocalVideo ? Icons.videocam : Icons.person,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.isLocalVideo ? '本地视频' : '远程视频',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ),
          ),

          // 顶部信息栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: widget.isMobile ? 50 : 40, // 移动端状态栏高度更高
                left: widget.isMobile ? 16 : 20,
                right: widget.isMobile ? 16 : 20,
                bottom: widget.isMobile ? 16 : 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // 成员信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.memberName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isLocalVideo ? '本地视频' : '远程视频',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 关闭按钮
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('📹 [全屏视频] 点击关闭按钮');
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(widget.isMobile ? 28 : 24),
                      child: Container(
                        width: widget.isMobile ? 56 : 48, // 移动端按钮更大
                        height: widget.isMobile ? 56 : 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(widget.isMobile ? 28 : 24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: widget.isMobile ? 2 : 1, // 移动端边框更粗
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: widget.isMobile ? 28 : 24, // 移动端图标更大
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部操作栏（可选，用于显示额外信息或操作）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: widget.isMobile ? 16 : 20,
                right: widget.isMobile ? 16 : 20,
                bottom: widget.isMobile ? 50 : 40, // 移动端底部安全区域更大
                top: widget.isMobile ? 16 : 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 移动端提示文字
                  if (widget.isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '点击屏幕任意位置关闭全屏',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  if (widget.isMobile) const SizedBox(height: 12),
                  
                  // 用户ID显示（调试用）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ID: ${widget.userId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
