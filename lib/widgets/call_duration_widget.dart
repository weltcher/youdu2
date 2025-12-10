import 'dart:async';
import 'package:flutter/material.dart';

/// 通话时长显示组件
/// 使用独立的 StatefulWidget 来避免整个页面重建
class CallDurationWidget extends StatefulWidget {
  final int initialDuration;
  final TextStyle? style;
  final bool isConnected;
  final String? overrideText; // 可选的覆盖文本，如"正在退出..."或"正在最小化..."

  const CallDurationWidget({
    Key? key,
    this.initialDuration = 0,
    this.style,
    required this.isConnected,
    this.overrideText,
  }) : super(key: key);

  @override
  State<CallDurationWidget> createState() => _CallDurationWidgetState();
}

class _CallDurationWidgetState extends State<CallDurationWidget> {
  late int _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;

    // 只有在已连接状态才开始计时
    if (widget.isConnected) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CallDurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听连接状态变化
    if (!oldWidget.isConnected && widget.isConnected) {
      // 从未连接变为已连接，开始计时
      _startTimer();
    } else if (oldWidget.isConnected && !widget.isConnected) {
      // 从已连接变为未连接，停止计时
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.overrideText ?? _formatDuration(_duration),
      style:
          widget.style ?? const TextStyle(fontSize: 18, color: Colors.white70),
    );
  }
}
