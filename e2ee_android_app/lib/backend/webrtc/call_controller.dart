import 'dart:ui';

import 'package:e2ee_android_app/backend/webrtc/webRTC_service.dart';
import 'package:e2ee_android_app/backend/webrtc/webRTC_signaling_repository.dart';
import 'package:e2ee_models_app/models/calling/WebRTCSignalModel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_provider.dart';

class CallController {
  late CallProvider callProvider;
  late WebRTCSignalingRepository signalingRepository;
  late WebRTCService webrtcService;

  String? _selfId;
  String? _token;
  String? _remoteId;

  Function(String callerId)? onIncomingCall;
  VoidCallback? onCallConnected;
  VoidCallback? onCallEnded;

  CallController({
    CallProvider? provider,
    WebRTCSignalingRepository? repository,
    WebRTCService? service,
  }) {
    callProvider = provider ?? CallProvider();
    signalingRepository = repository ?? WebRTCSignalingRepository();
    webrtcService = service ?? WebRTCService();
  }

  void init({required String userId, required String token}) {
    _selfId = userId;
    _token = token;

    signalingRepository.initWebSocket(
      userId: userId,
      token: token,
      onSignalReceived: _handleSignal,
    );
  }

  Future<void> startCall(String receiverId) async {
    _remoteId = receiverId;
    callProvider.callState.set(value: CallState.calling);

    await webrtcService.initPeerConnection(
      onIceCandidate: _sendIceCandidate,
      onAddRemoteStream: (stream) {
        // you can update provider with remote stream here
      },
    );

    await webrtcService.attachLocalAudio();

    final offer = await webrtcService.createOffer();

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'offer',
        data: offer.toMap(),
        senderId: _selfId!,
        receiverId: receiverId,
      ),
    );
  }

  Future<void> acceptCall() async {
    if (_remoteId == null) return;

    callProvider.callState.set(value: CallState.connected);

    await webrtcService.initPeerConnection(
      onIceCandidate: _sendIceCandidate,
      onAddRemoteStream: (stream) {
        // Handle stream
      },
    );

    await webrtcService.attachLocalAudio();
  }

  Future<void> sendAnswer(Map<String, dynamic> offer) async {
    await webrtcService.setRemoteDescription(offer['sdp'], offer['type']);

    final answer = await webrtcService.createAnswer();

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'answer',
        data: answer.toMap(),
        senderId: _selfId!,
        receiverId: _remoteId!,
      ),
    );
  }

  Future<void> _handleSignal(WebRTCSignalModel signal) async {
    switch (signal.type) {
      case 'offer':
        _remoteId = signal.senderId;
        callProvider.callState.set(value: CallState.ringing);
        callProvider.currentCallerId.set(value: signal.senderId);
        onIncomingCall?.call(signal.senderId);
        break;

      case 'answer':
        await webrtcService.setRemoteDescription(
          signal.data?['sdp'],
          signal.data?['type'],
        );
        callProvider.callState.set(value: CallState.connected);
        onCallConnected?.call();
        break;

      case 'ice-candidate':
        final candidate = RTCIceCandidate(
          signal.data?['candidate'],
          signal.data?['sdpMid'],
          signal.data?['sdpMLineIndex'],
        );
        await webrtcService.addIceCandidate(candidate);
        break;

      case 'hangup':
        await endCall(sendSignal: false);
        break;
    }
  }

  Future<void> endCall({bool sendSignal = true}) async {
    if (sendSignal && _remoteId != null) {
      await signalingRepository.sendSignal(
        token: _token!,
        signal: WebRTCSignalModel(
          type: 'hangup',
          senderId: _selfId!,
          receiverId: _remoteId!,
        ),
      );
    }

    await webrtcService.dispose();

    callProvider.callState.set(value: CallState.ended);
    onCallEnded?.call();
  }

  void mute(bool value) {
    webrtcService.toggleMute(value);
    callProvider.isMuted.set(value: value);
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    if (_token == null || _remoteId == null) return;

    signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'ice-candidate',
        data: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        senderId: _selfId!,
        receiverId: _remoteId!,
      ),
    );
  }
}
