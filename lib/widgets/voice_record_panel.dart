import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_record_service.dart';

/// 语音录制面板
class VoiceRecordPanel extends StatefulWidget {
  final Function(String filePath, int duration) onRecordComplete;

  const VoiceRecordPanel({
    super.key,
    required this.onRecordComplete,
  });

  @override
  State<VoiceRecordPanel> createState() => _VoiceRecordPanelState();
}

class _VoiceRecordPanelState extends State<VoiceRecordPanel> {
  final VoiceRecordService _recordService = VoiceRecordService();
  bool _isCancelling = false;
  double _startY = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 初始化录音服务
    _recordService.init().catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音器初始化失败: $e')),
        );
      }
    });

    // 设置回调
    _recordService.onMaxDurationReached = () {
      if (mounted) {
        _stopAndSend();
      }
    };

    // 设置时长更新回调
    _recordService.onDurationUpdate = (duration) {
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _stopAndSend() async {
    final result = await _recordService.stopRecording();
    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        widget.onRecordComplete(
          result['path'] as String,
          result['duration'] as int,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            '语音消息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最长60秒',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
          // 录音状态提示
          if (_recordService.isRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(_recordService.currentDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordService.currentDuration % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 48),
          // 录音按钮
          GestureDetector(
            onLongPressStart: (details) async {
              _startY = details.globalPosition.dy;
              final success = await _recordService.startRecording();
              if (success && mounted) {
                setState(() {});
              }
            },
            onLongPressMoveUpdate: (details) {
              final deltaY = _startY - details.globalPosition.dy;
              setState(() {
                _isCancelling = deltaY > 50;
              });
            },
            onLongPressEnd: (details) async {
              if (_isCancelling) {
                await _recordService.cancelRecording();
                if (mounted) {
                  Navigator.pop(context);
                }
              } else {
                await _stopAndSend();
              }
              if (mounted) {
                setState(() {
                  _isCancelling = false;
                });
              }
            },
            onLongPressCancel: () async {
              await _recordService.cancelRecording();
              if (mounted) {
                setState(() {
                  _isCancelling = false;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _recordService.isRecording ? 80 : 60,
              height: _recordService.isRecording ? 80 : 60,
              decoration: BoxDecoration(
                color: _isCancelling ? Colors.red : const Color(0xFF4A90E2),
                shape: BoxShape.circle,
                boxShadow: _recordService.isRecording
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
                size: _recordService.isRecording ? 36 : 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _recordService.isRecording
                ? (_isCancelling ? '松开取消' : '上滑取消')
                : '长按录音',
            style: TextStyle(
              fontSize: 12,
              color: _isCancelling ? Colors.red : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
