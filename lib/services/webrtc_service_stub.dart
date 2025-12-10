/// WebRTC 服务的存根实现
/// 当 WebRTC 功能被禁用时使用此文件
library;

import 'dart:async';
import '../utils/logger.dart';

enum CallState { idle, calling, ringing, connected, ended }

enum CallType { voice, video }

/// WebRTC 服务存根（空实现）
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  Function(CallState)? onCallStateChanged;
  Function(dynamic)? onRemoteStreamAdded;
  Function(dynamic)? onLocalStreamAdded;
  Function(String)? onError;
  Function(int userId, String displayName, CallType callType)? onIncomingCall;

  Future<void> initialize(int currentUserId) async {
    logger.debug('⚠️ WebRTC 功能已禁用（使用存根实现）');
  }

  Future<void> startVoiceCall(
    int targetUserId,
    String targetDisplayName,
  ) async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  Future<void> startVideoCall(
    int targetUserId,
    String targetDisplayName,
  ) async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  Future<void> acceptCall() async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  Future<void> rejectCall() async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  Future<void> endCall() async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  void toggleMute() {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  Future<void> toggleSpeaker() async {
    logger.debug('⚠️ WebRTC 功能已禁用');
  }

  CallState get callState => CallState.idle;
  CallType get callType => CallType.voice;
  int? get currentCallUserId => null;
  dynamic get localStream => null;
  dynamic get remoteStream => null;

  Future<void> dispose() async {}
}
