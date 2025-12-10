import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerPage({Key? key, required this.videoUrl, this.title})
    : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentPosition = 0.0;
  double _videoDuration = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _videoDuration = _controller.value.duration.inSeconds.toDouble();
      });

      // 添加监听器，监控播放状态和错误
      _controller.addListener(() {
        if (!mounted) return;

        // 检查是否有错误
        if (_controller.value.hasError) {
          setState(() {
            _hasError = true;
          });
          return;
        }

        setState(() {
          _currentPosition = _controller.value.position.inSeconds.toDouble();
          _isPlaying = _controller.value.isPlaying;
        });
      });

      // 自动播放
      await _controller.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  // 重试加载视频
  Future<void> _retryVideo() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    try {
      await _controller.dispose();
    } catch (e) {
      // 忽略释放错误
    }

    await _initializeVideo();
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (e) {
      // 忽略释放时的错误
    }
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // 在浏览器中打开视频
  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开浏览器'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开浏览器失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 构建错误提示界面
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 64),
          const SizedBox(height: 24),
          const Text(
            '视频播放失败',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '设备的视频解码器不支持此视频格式',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '这可能是设备硬件限制导致的',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // 在浏览器中打开按钮（首选方案）
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中打开'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 其他选项
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retryVideo,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('关闭'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频播放器或错误提示
          GestureDetector(
            onTap: () {
              if (!_hasError) {
                setState(() {
                  _showControls = !_showControls;
                });
              }
            },
            child: Center(
              child: _hasError
                  ? _buildErrorWidget()
                  : _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // 控制条
          if (_showControls) ...[
            // 顶部栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 底部控制栏
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度条
                    if (_isInitialized)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Slider(
                                value: _currentPosition,
                                min: 0,
                                max: _videoDuration,
                                activeColor: const Color(0xFF4A90E2),
                                inactiveColor: Colors.white24,
                                onChanged: (value) {
                                  setState(() {
                                    _currentPosition = value;
                                  });
                                  _controller.seekTo(
                                    Duration(seconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(_videoDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 播放控制按钮
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 后退10秒
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _isInitialized
                                ? () {
                                    final newPosition =
                                        _controller.value.position -
                                        const Duration(seconds: 10);
                                    _controller.seekTo(newPosition);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 20),

                          // 播放/暂停按钮
                          IconButton(
                            icon: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            onPressed: _isInitialized
                                ? () {
                                    if (_isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.play();
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(width: 20),

                          // 前进10秒
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _isInitialized
                                ? () {
                                    final newPosition =
                                        _controller.value.position +
                                        const Duration(seconds: 10);
                                    _controller.seekTo(newPosition);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 中央播放按钮（仅在视频暂停时显示）
          if (_isInitialized && !_isPlaying && _showControls)
            Center(
              child: IconButton(
                icon: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                onPressed: () {
                  _controller.play();
                },
              ),
            ),
        ],
      ),
    );
  }
}
