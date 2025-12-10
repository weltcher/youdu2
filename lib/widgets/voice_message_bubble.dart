import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import '../utils/logger.dart';

/// 语音消息气泡组件
/// 
/// 功能：
/// - 显示语音时长
/// - 点击播放/暂停
/// - 播放进度动画
/// - 支持OPUS格式
class VoiceMessageBubble extends StatefulWidget {
  final String url; // 语音文件URL
  final int duration; // 语音时长（秒）
  final bool isMe; // 是否是自己发送的消息

  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with SingleTickerProviderStateMixin {
  // 根据平台选择不同的播放器
  final bool _isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  
  // just_audio 播放器（移动端）
  just_audio.AudioPlayer? _justAudioPlayer;
  
  // audioplayers 播放器（桌面端）
  audioplayers.AudioPlayer? _audioPlayersPlayer;
  
  // 播放状态
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // 动画控制器
  late AnimationController _animationController;
  
  // 订阅（just_audio）
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  
  // 订阅（audioplayers）
  StreamSubscription<void>? _audioPlayersCompleteSubscription;
  StreamSubscription<Duration>? _audioPlayersPositionSubscription;
  StreamSubscription<Duration>? _audioPlayersDurationSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 根据平台初始化不同的播放器
    if (_isDesktop) {
      _audioPlayersPlayer = audioplayers.AudioPlayer();
      _setupAudioPlayersPlayer();
    } else {
      _justAudioPlayer = just_audio.AudioPlayer();
      _setupJustAudioPlayer();
    }
  }

  void _setupJustAudioPlayer() {
    if (_justAudioPlayer == null) return;
    
    // 监听播放状态
    _playerStateSubscription = _justAudioPlayer!.playerStateStream.listen((state) {
      if (!mounted) return;
      
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == just_audio.ProcessingState.loading ||
                     state.processingState == just_audio.ProcessingState.buffering;
      });
      
      if (state.playing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      
      // 播放完成后重置
      if (state.processingState == just_audio.ProcessingState.completed) {
        _justAudioPlayer!.seek(Duration.zero);
        _justAudioPlayer!.pause();
      }
    });
    
    // 监听播放位置
    _positionSubscription = _justAudioPlayer!.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });
    
    // 监听总时长
    _durationSubscription = _justAudioPlayer!.durationStream.listen((duration) {
      if (!mounted) return;
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }
  
  void _setupAudioPlayersPlayer() {
    if (_audioPlayersPlayer == null) return;
    
    // 监听播放完成
    _audioPlayersCompleteSubscription = _audioPlayersPlayer!.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      _animationController.reverse();
    });
    
    // 监听播放位置
    _audioPlayersPositionSubscription = _audioPlayersPlayer!.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });
    
    // 监听总时长
    _audioPlayersDurationSubscription = _audioPlayersPlayer!.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _totalDuration = duration;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    // just_audio 订阅
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    
    // audioplayers 订阅
    _audioPlayersCompleteSubscription?.cancel();
    _audioPlayersPositionSubscription?.cancel();
    _audioPlayersDurationSubscription?.cancel();
    
    _animationController.dispose();
    
    // 释放播放器
    _justAudioPlayer?.dispose();
    _audioPlayersPlayer?.dispose();
    
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isDesktop && _audioPlayersPlayer != null) {
        // 桌面端使用 audioplayers
        if (_isPlaying) {
          await _audioPlayersPlayer!.pause();
          setState(() {
            _isPlaying = false;
          });
          _animationController.reverse();
        } else {
          setState(() {
            _isLoading = true;
          });
          await _audioPlayersPlayer!.play(audioplayers.UrlSource(widget.url));
          setState(() {
            _isPlaying = true;
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else if (_justAudioPlayer != null) {
        // 移动端使用 just_audio
        if (_isPlaying) {
          await _justAudioPlayer!.pause();
        } else {
          // 如果还没加载，先加载
          if (_justAudioPlayer!.audioSource == null) {
            setState(() {
              _isLoading = true;
            });
            await _justAudioPlayer!.setUrl(widget.url);
          }
          await _justAudioPlayer!.play();
        }
      }
    } catch (e) {
      logger.error('播放语音失败', error: e);
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs"';
  }

  @override
  Widget build(BuildContext context) {
    // 计算气泡宽度（根据时长动态调整，最小100，最大200）
    final bubbleWidth = 100.0 + (widget.duration / 60.0 * 100.0).clamp(0.0, 100.0);
    
    // 计算播放进度
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: bubbleWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFFBDD7F3) : Colors.white,
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
            // 播放按钮/加载指示器
            SizedBox(
              width: 18,
              height: 18,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    )
                  : AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _animationController,
                      size: 18,
                      color: widget.isMe ? Colors.black87 : Colors.grey[700],
                    ),
            ),
            const SizedBox(width: 6),
            // 波形动画
            Expanded(
              child: _buildWaveform(progress),
            ),
            const SizedBox(width: 6),
            // 时长显示
            Text(
              _isPlaying
                  ? _formatDuration(_currentPosition.inSeconds)
                  : _formatDuration(widget.duration),
              style: TextStyle(
                fontSize: 11,
                color: widget.isMe ? Colors.black54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform(double progress) {
    return SizedBox(
      height: 18,
      child: CustomPaint(
        painter: _WaveformPainter(
          progress: progress,
          isMe: widget.isMe,
          isPlaying: _isPlaying,
        ),
        child: Container(),
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
      0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.7, 0.5, 0.8, 0.4,
      0.6, 0.9, 0.5, 0.7, 0.4, 0.8, 0.6, 0.5, 0.7, 0.3,
    ];

    const barWidth = 2.0;
    const barSpacing = 2.0;
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
