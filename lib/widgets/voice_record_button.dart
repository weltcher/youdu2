import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_record_service.dart';

/// 语音录制按钮组件
/// 
/// 功能：
/// - 长按开始录音
/// - 松开发送语音
/// - 上滑取消录音
/// - 显示录音时长
/// - 最长60秒自动停止
class VoiceRecordButton extends StatefulWidget {
  final Function(String filePath, int duration)? onRecordComplete;
  final Function()? onRecordCancel;
  final bool enabled;

  const VoiceRecordButton({
    super.key,
    this.onRecordComplete,
    this.onRecordCancel,
    this.enabled = true,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  final VoiceRecordService _recordService = VoiceRecordService();
  
  bool _isRecording = false;
  bool _isCancelling = false; // 是否处于取消状态（上滑）
  int _recordDuration = 0;
  double _startY = 0;
  
  // 动画控制器
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // 设置录音服务回调
    _recordService.onDurationUpdate = (seconds) {
      if (mounted) {
        setState(() {
          _recordDuration = seconds;
        });
      }
    };
    
    _recordService.onMaxDurationReached = () {
      // 达到最大时长，自动停止并发送
      _stopRecording(cancel: false);
    };
    
    _recordService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!widget.enabled) return;
    
    final success = await _recordService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _isCancelling = false;
      });
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_isRecording) return;
    
    _pulseController.stop();
    _pulseController.reset();
    
    if (cancel || _isCancelling) {
      await _recordService.cancelRecording();
      widget.onRecordCancel?.call();
    } else {
      final result = await _recordService.stopRecording();
      if (result != null) {
        widget.onRecordComplete?.call(
          result['path'] as String,
          result['duration'] as int,
        );
      }
    }
    
    setState(() {
      _isRecording = false;
      _isCancelling = false;
      _recordDuration = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    
    // 检测上滑距离
    final deltaY = _startY - details.globalPosition.dy;
    setState(() {
      _isCancelling = deltaY > 50; // 上滑超过50像素进入取消状态
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 录音状态提示
        if (_isRecording)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isCancelling ? Colors.red.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 录音指示器
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12 * _pulseAnimation.value,
                      height: 12 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        color: _isCancelling ? Colors.red : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // 时长显示
                Text(
                  _formatDuration(_recordDuration),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isCancelling ? Colors.red : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                // 提示文字
                Text(
                  _isCancelling ? '松开取消' : '上滑取消',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isCancelling ? Colors.red : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        
        // 录音按钮
        GestureDetector(
          onLongPressStart: (details) {
            _startY = details.globalPosition.dy;
            _startRecording();
          },
          onLongPressMoveUpdate: (details) {
            _onPanUpdate(DragUpdateDetails(
              globalPosition: details.globalPosition,
              localPosition: details.localPosition,
            ));
          },
          onLongPressEnd: (details) {
            _stopRecording();
          },
          onLongPressCancel: () {
            _stopRecording(cancel: true);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isRecording ? 80 : 50,
            height: _isRecording ? 80 : 50,
            decoration: BoxDecoration(
              color: _isCancelling
                  ? Colors.red
                  : (_isRecording
                      ? const Color(0xFF4A90E2).withOpacity(0.8)
                      : (widget.enabled
                          ? const Color(0xFF4A90E2)
                          : Colors.grey)),
              shape: BoxShape.circle,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: (_isCancelling ? Colors.red : const Color(0xFF4A90E2))
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isCancelling ? Icons.close : Icons.mic,
              color: Colors.white,
              size: _isRecording ? 36 : 24,
            ),
          ),
        ),
        
        // 提示文字
        if (!_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '长按录音',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
