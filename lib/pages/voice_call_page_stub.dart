/// 语音/视频通话页面的存根实现
/// 当 WebRTC 功能被禁用时使用此文件
library;
import 'package:flutter/material.dart';
import '../services/webrtc_service_stub.dart';

class VoiceCallPage extends StatelessWidget {
  final int targetUserId;
  final String targetDisplayName;
  final bool isIncoming;
  final CallType callType;

  const VoiceCallPage({
    super.key,
    required this.targetUserId,
    required this.targetDisplayName,
    required this.isIncoming,
    required this.callType,
  });

  @override
  Widget build(BuildContext context) {
    // 立即返回并显示提示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WebRTC 功能未启用')));
    });

    return const Scaffold(body: Center(child: Text('WebRTC 功能未启用')));
  }
}
