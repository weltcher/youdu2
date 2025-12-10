import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart'; // TODO: 需要添加 audioplayers 包

/// 语音消息播放器组件
class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final int duration; // 秒
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  // 播放状态
  bool _isPlaying = false;
  bool _isLoading = false;
  double _currentPosition = 0;

  // 动画控制器
  late AnimationController _animationController;
  Timer? _progressTimer;

  // TODO: 实际使用时需要 AudioPlayer
  // late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // TODO: 初始化音频播放器
    // _audioPlayer = AudioPlayer();
    // _setupAudioPlayer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    // TODO: 释放音频播放器
    // _audioPlayer.dispose();
    super.dispose();
  }

  // 模拟播放/暂停功能
  void _togglePlay() async {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    setState(() {
      _isPlaying = true;
      _isLoading = true;
    });
    _animationController.forward();

    // 模拟加载
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 模拟播放进度
        _startProgressTimer();
      }
    });

    // TODO: 实际播放音频
    // await _audioPlayer.play(UrlSource(widget.url));
  }

  void _pause() {
    setState(() {
      _isPlaying = false;
    });
    _animationController.reverse();
    _progressTimer?.cancel();

    // TODO: 实际暂停音频
    // await _audioPlayer.pause();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentPosition += 0.1;
        if (_currentPosition >= widget.duration) {
          _currentPosition = widget.duration.toDouble();
          _isPlaying = false;
          _animationController.reverse();
          timer.cancel();
        }
      });
    });
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration > 0
        ? _currentPosition / widget.duration
        : 0.0;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFFD6EFEC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 播放按钮
            Stack(
              alignment: Alignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  )
                else
                  AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _animationController,
                    size: 24,
                    color: widget.isMe ? Colors.black87 : Colors.grey[700],
                  ),
              ],
            ),
            const SizedBox(width: 8),
            // 波形和时长
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 波形图
                  SizedBox(
                    height: 30,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        progress: progress,
                        isMe: widget.isMe,
                        isPlaying: _isPlaying,
                      ),
                      child: Container(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 时长显示
                  Text(
                    _isPlaying || _currentPosition > 0
                        ? _formatDuration(_currentPosition)
                        : _formatDuration(widget.duration.toDouble()),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe ? Colors.black54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 语音图标
            Icon(
              Icons.mic,
              size: 16,
              color: widget.isMe ? Colors.black45 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// 波形图绘制器
class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isMe;
  final bool isPlaying;

  _WaveformPainter({
    required this.progress,
    required this.isMe,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 波形数据（模拟）
    final waveData = [
      0.3,
      0.5,
      0.8,
      0.4,
      0.9,
      0.6,
      0.7,
      0.5,
      0.8,
      0.4,
      0.6,
      0.9,
      0.5,
      0.7,
      0.4,
      0.8,
      0.6,
      0.5,
      0.7,
      0.3,
    ];

    final barWidth = 2.0;
    final barSpacing = 2.0;
    final totalBars = (size.width / (barWidth + barSpacing)).floor();

    for (int i = 0; i < totalBars && i < waveData.length; i++) {
      final x = i * (barWidth + barSpacing) + barWidth / 2;
      final barHeight = waveData[i % waveData.length] * size.height * 0.8;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      // 根据播放进度设置颜色
      if (progress > 0 && i / totalBars <= progress) {
        paint.color = isMe
            ? Colors.black.withOpacity(0.7)
            : const Color(0xFF4A90E2);
      } else {
        paint.color = isMe
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.4);
      }

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
