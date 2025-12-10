import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';
import '../utils/logger.dart';

enum CallState {
  idle, // 空闲
  calling, // 正在呼叫
  ringing, // 对方来电响铃中
  connected, // 已连接
  ended, // 已结束
}

enum CallType {
  voice, // 语音通话
  video, // 视频通话
}

class WebRTCService {
  // 单例模式
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // WebRTC 相关
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 通话状态
  CallState _callState = CallState.idle;
  CallType _callType = CallType.voice;
  int? _currentCallUserId; // 当前通话的对方用户ID

  // WebSocket 服务
  final WebSocketService _wsService = WebSocketService();

  // 回调函数
  Function(CallState)? onCallStateChanged;
  Function(MediaStream)? onRemoteStreamAdded;
  Function(MediaStream)? onLocalStreamAdded;
  Function(String)? onError;
  Function(int userId, String displayName, CallType callType)? onIncomingCall;

  // STUN/TURN 服务器配置
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        // Google 公共 STUN 服务器
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      {
        // 您的 TURN 服务器（请替换为实际的服务器地址和凭证）
        'urls': [
          'turn:31.57.65.81:3478?transport=udp',
          'turn:31.57.65.81:3478?transport=tcp',
        ],
        'username': 'youdu-turn',
        'credential': "D@S&#D>!c3dqd",
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Offer/Answer 约束
  final Map<String, dynamic> _offerSdpConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': [],
  };

  // 初始化
  Future<void> initialize(int currentUserId) async {
    _setupWebSocketListeners();
    logger.debug('📞 WebRTC 服务初始化完成，用户ID: $currentUserId');
  }

  // 设置 WebSocket 监听器
  void _setupWebSocketListeners() {
    _wsService.onWebRTCSignal = (data) async {
      logger.debug('📞 收到 WebRTC 信令: ${data['type']}');

      try {
        switch (data['type']) {
          case 'offer':
            await _handleOffer(data);
            break;
          case 'answer':
            await _handleAnswer(data);
            break;
          case 'ice-candidate':
            await _handleIceCandidate(data);
            break;
          case 'call-request':
            _handleIncomingCall(data);
            break;
          case 'call-accepted':
            await _handleCallAccepted(data);
            break;
          case 'call-rejected':
            _handleCallRejected(data);
            break;
          case 'call-ended':
            await endCall();
            break;
        }
      } catch (e) {
        logger.debug('❌ 处理 WebRTC 信令失败: $e');
        onError?.call('信令处理失败: $e');
      }
    };
  }

  // 发起语音通话
  Future<void> startVoiceCall(
    int targetUserId,
    String targetDisplayName,
  ) async {
    await _startCall(targetUserId, targetDisplayName, CallType.voice);
  }

  // 发起视频通话
  Future<void> startVideoCall(
    int targetUserId,
    String targetDisplayName,
  ) async {
    await _startCall(targetUserId, targetDisplayName, CallType.video);
  }

  // 发起通话
  Future<void> _startCall(
    int targetUserId,
    String targetDisplayName,
    CallType callType,
  ) async {
    if (_callState != CallState.idle) {
      onError?.call('当前正在通话中');
      return;
    }

    try {
      logger.debug(
        '📞 发起${callType == CallType.voice ? '语音' : '视频'}通话，目标用户: $targetUserId',
      );

      _currentCallUserId = targetUserId;
      _callType = callType;
      _updateCallState(CallState.calling);

      // 创建本地媒体流
      await _createLocalStream(callType);

      // 创建 PeerConnection
      await _createPeerConnection();

      // 发送通话请求
      _wsService.sendWebRTCSignal({
        'type': 'call-request',
        'targetUserId': targetUserId,
        'callType': callType == CallType.voice ? 'voice' : 'video',
        'callerName': targetDisplayName,
      });

      logger.debug('📞 通话请求已发送');
    } catch (e) {
      logger.debug('❌ 发起通话失败: $e');
      onError?.call('发起通话失败: $e');
      await endCall();
    }
  }

  // 接听来电
  Future<void> acceptCall() async {
    if (_callState != CallState.ringing) {
      logger.debug('❌ 当前没有来电');
      return;
    }

    try {
      logger.debug('📞 接听来电');

      // 创建本地媒体流
      await _createLocalStream(_callType);

      // 创建 PeerConnection
      await _createPeerConnection();

      // 启用扬声器（语音通话必须）
      try {
        await Helper.setSpeakerphoneOn(true);
        logger.debug('📞 扬声器已启用');
      } catch (e) {
        logger.debug('⚠️ 启用扬声器失败: $e');
      }

      // 通知对方已接受通话
      _wsService.sendWebRTCSignal({
        'type': 'call-accepted',
        'targetUserId': _currentCallUserId,
      });

      _updateCallState(CallState.connected);
    } catch (e) {
      logger.debug('❌ 接听来电失败: $e');
      onError?.call('接听来电失败: $e');
      await endCall();
    }
  }

  // 拒绝来电
  Future<void> rejectCall() async {
    if (_callState != CallState.ringing) {
      logger.debug('❌ 当前没有来电');
      return;
    }

    logger.debug('📞 拒绝来电');

    _wsService.sendWebRTCSignal({
      'type': 'call-rejected',
      'targetUserId': _currentCallUserId,
    });

    await endCall();
  }

  // 结束通话
  Future<void> endCall() async {
    // 防止重复调用
    if (_callState == CallState.idle || _callState == CallState.ended) {
      logger.debug('📞 通话已结束，跳过重复调用');
      return;
    }

    logger.debug('📞 结束通话');

    // 通知对方挂断（只在主动挂断时发送）
    if (_currentCallUserId != null && _callState != CallState.idle) {
      try {
        _wsService.sendWebRTCSignal({
          'type': 'call-ended',
          'targetUserId': _currentCallUserId,
        });
      } catch (e) {
        logger.debug('⚠️ 发送挂断信令失败: $e');
      }
    }

    // 先关闭 PeerConnection（这会自动停止track）
    if (_peerConnection != null) {
      try {
        await _peerConnection!.close();
        logger.debug('📞 PeerConnection 已关闭');
      } catch (e) {
        logger.debug('⚠️ 关闭 PeerConnection 失败: $e');
      }
      _peerConnection = null;
    }

    // 停止并释放本地流
    if (_localStream != null) {
      try {
        // 先停止所有track
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        // 再dispose流
        await _localStream!.dispose();
        logger.debug('📞 本地流已释放');
      } catch (e) {
        logger.debug('⚠️ 释放本地流失败: $e');
      }
      _localStream = null;
    }

    // 停止并释放远程流
    if (_remoteStream != null) {
      try {
        // 先停止所有track
        _remoteStream!.getTracks().forEach((track) {
          track.stop();
        });
        // 再dispose流
        await _remoteStream!.dispose();
        logger.debug('📞 远程流已释放');
      } catch (e) {
        logger.debug('⚠️ 释放远程流失败: $e');
      }
      _remoteStream = null;
    }

    _currentCallUserId = null;
    _updateCallState(CallState.ended);

    // 延迟重置为idle状态
    await Future.delayed(const Duration(milliseconds: 500));
    _updateCallState(CallState.idle);
  }

  // 创建本地媒体流
  Future<void> _createLocalStream(CallType callType) async {
    logger.debug('📞 创建本地媒体流: ${callType == CallType.voice ? '仅音频' : '音视频'}');

    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'mandatory': {
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
        },
        'optional': [],
      },
      'video': callType == CallType.video
          ? {
              'mandatory': {
                'minWidth': 640,
                'minHeight': 480,
                'minFrameRate': 30,
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      // 打印并确保音频轨道已启用
      final audioTracks = _localStream!.getAudioTracks();
      logger.debug('🔊 本地音频轨道数量: ${audioTracks.length}');
      for (var track in audioTracks) {
        track.enabled = true;
        logger.debug(
          '🔊 本地音频轨道 ${track.id}: enabled=${track.enabled}, kind=${track.kind}, muted=${track.muted}',
        );
      }

      // 打印视频轨道信息
      if (callType == CallType.video) {
        final videoTracks = _localStream!.getVideoTracks();
        logger.debug('📹 视频轨道数量: ${videoTracks.length}');
        if (videoTracks.isNotEmpty) {
          logger.debug('📹 视频轨道ID: ${videoTracks[0].id}');
          logger.debug('📹 视频轨道启用: ${videoTracks[0].enabled}');
          logger.debug('📹 视频轨道种类: ${videoTracks[0].kind}');
        }
      }

      onLocalStreamAdded?.call(_localStream!);
      logger.debug('📞 本地媒体流创建成功');
    } catch (e) {
      logger.debug('❌ 创建本地媒体流失败: $e');
      throw Exception('无法访问麦克风/摄像头: $e');
    }
  }

  // 创建 PeerConnection
  Future<void> _createPeerConnection() async {
    logger.debug('📞 创建 PeerConnection');

    _peerConnection = await createPeerConnection(_configuration);

    // 添加本地流到 PeerConnection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    // 监听远程流
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      logger.debug('📞 收到远程流轨道: ${event.track.kind}');
      logger.debug(
        '📞 轨道详情: id=${event.track.id}, enabled=${event.track.enabled}, muted=${event.track.muted}',
      );

      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        logger.debug('📞 远程流ID: ${_remoteStream!.id}');

        // 确保音频轨道已启用
        final audioTracks = _remoteStream!.getAudioTracks();
        logger.debug('📞 远程音频轨道数: ${audioTracks.length}');
        for (var track in audioTracks) {
          // 强制启用音频轨道
          track.enabled = true;
          logger.debug(
            '📞 远程音频轨道 ${track.id}: enabled=${track.enabled}, muted=${track.muted}',
          );
        }

        // 检查视频轨道（如果有）
        final videoTracks = _remoteStream!.getVideoTracks();
        logger.debug('📞 远程视频轨道数: ${videoTracks.length}');

        onRemoteStreamAdded?.call(_remoteStream!);
      } else {
        logger.debug('⚠️ 警告: 收到轨道但没有流');
      }
    };

    // 监听 ICE 候选
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      logger.debug('📞 发送 ICE 候选');
      _wsService.sendWebRTCSignal({
        'type': 'ice-candidate',
        'targetUserId': _currentCallUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    // 监听连接状态变化
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      logger.debug('📞 连接状态变化: $state');

      // 当连接成功时，再次确认音频轨道启用
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        logger.debug('✅ WebRTC 连接已建立');

        // 检查本地音频轨道
        if (_localStream != null) {
          final localAudioTracks = _localStream!.getAudioTracks();
          logger.debug('🔊 连接后本地音频轨道数: ${localAudioTracks.length}');
          for (var track in localAudioTracks) {
            logger.debug(
              '🔊 本地音频轨道 ${track.id}: enabled=${track.enabled}, muted=${track.muted}',
            );
          }
        }

        // 检查远程音频轨道
        if (_remoteStream != null) {
          final remoteAudioTracks = _remoteStream!.getAudioTracks();
          logger.debug('🔊 连接后远程音频轨道数: ${remoteAudioTracks.length}');
          for (var track in remoteAudioTracks) {
            logger.debug(
              '🔊 远程音频轨道 ${track.id}: enabled=${track.enabled}, muted=${track.muted}',
            );
          }
        }
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        endCall();
      }
    };

    logger.debug('📞 PeerConnection 创建成功');
  }

  // 处理来电
  void _handleIncomingCall(Map<String, dynamic> data) {
    logger.debug('📞 收到来电: $data');

    _currentCallUserId = data['fromUserId'];
    _callType = data['callType'] == 'video' ? CallType.video : CallType.voice;
    _updateCallState(CallState.ringing);

    onIncomingCall?.call(
      _currentCallUserId!,
      data['callerName'] ?? '未知用户',
      _callType,
    );
  }

  // 处理对方接受通话
  Future<void> _handleCallAccepted(Map<String, dynamic> data) async {
    logger.debug('📞 对方已接受通话');
    _updateCallState(CallState.connected);

    // 启用扬声器（语音通话必须）
    try {
      await Helper.setSpeakerphoneOn(true);
      logger.debug('📞 扬声器已启用');
    } catch (e) {
      logger.debug('⚠️ 启用扬声器失败: $e');
    }

    // 创建并发送 Offer
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer(
        _offerSdpConstraints,
      );
      await _peerConnection!.setLocalDescription(offer);

      _wsService.sendWebRTCSignal({
        'type': 'offer',
        'targetUserId': _currentCallUserId,
        'sdp': offer.sdp,
      });

      logger.debug('📞 Offer 已发送');
    } catch (e) {
      logger.debug('❌ 创建 Offer 失败: $e');
      onError?.call('建立连接失败: $e');
      await endCall();
    }
  }

  // 处理对方拒绝通话
  void _handleCallRejected(Map<String, dynamic> data) {
    logger.debug('📞 对方拒绝了通话');
    onError?.call('对方拒绝了通话');
    endCall();
  }

  // 处理 Offer
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    logger.debug('📞 收到 Offer');

    try {
      RTCSessionDescription description = RTCSessionDescription(
        data['sdp'],
        'offer',
      );

      await _peerConnection!.setRemoteDescription(description);

      // 创建并发送 Answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer(
        _offerSdpConstraints,
      );
      await _peerConnection!.setLocalDescription(answer);

      _wsService.sendWebRTCSignal({
        'type': 'answer',
        'targetUserId': _currentCallUserId,
        'sdp': answer.sdp,
      });

      logger.debug('📞 Answer 已发送');
    } catch (e) {
      logger.debug('❌ 处理 Offer 失败: $e');
      onError?.call('建立连接失败: $e');
      await endCall();
    }
  }

  // 处理 Answer
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    logger.debug('📞 收到 Answer');

    try {
      RTCSessionDescription description = RTCSessionDescription(
        data['sdp'],
        'answer',
      );

      await _peerConnection!.setRemoteDescription(description);
      logger.debug('📞 Answer 设置成功');
    } catch (e) {
      logger.debug('❌ 处理 Answer 失败: $e');
      onError?.call('建立连接失败: $e');
      await endCall();
    }
  }

  // 处理 ICE 候选
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    logger.debug('📞 收到 ICE 候选');

    try {
      final candidateData = data['candidate'];
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);
      logger.debug('📞 ICE 候选添加成功');
    } catch (e) {
      logger.debug('❌ 添加 ICE 候选失败: $e');
    }
  }

  // 更新通话状态
  void _updateCallState(CallState newState) {
    _callState = newState;
    onCallStateChanged?.call(newState);
    logger.debug('📞 通话状态变化: $newState');
  }

  // 切换静音
  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final bool enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
        logger.debug('📞 ${enabled ? '静音' : '取消静音'}');
      }
    }
  }

  // 切换扬声器
  Future<void> toggleSpeaker() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        // 这里可以添加扬声器切换逻辑
        await Helper.setSpeakerphoneOn(true);
        logger.debug('📞 扬声器已开启');
      }
    }
  }

  // 获取当前状态
  CallState get callState => _callState;
  CallType get callType => _callType;
  int? get currentCallUserId => _currentCallUserId;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // 清理资源
  Future<void> dispose() async {
    await endCall();
    _wsService.onWebRTCSignal = null;
  }
}
