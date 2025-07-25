import 'dart:ui';

import 'package:e2ee_android_app/backend/webrtc/webRTC_service.dart';
import 'package:e2ee_android_app/backend/webrtc/webRTC_signaling_repository.dart';
import 'package:e2ee_models_app/models/calling/WebRTCSignalModel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_provider.dart';

class CallController {
  Map<String, dynamic>? _receivedOffer;

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
      onAddRemoteStream: (stream) {},
    );

    await webrtcService.attachLocalAudio();

    final offer = await webrtcService.createOffer();

    print('📤 Sending offer: ${offer.sdp}, type: ${offer.type}');

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'offer',
        data: {'sdp': offer.sdp, 'type': offer.type},
        senderId: _selfId!,
        receiverId: receiverId,
      ),
    );

    print(
      '📦 Sent signal payload: ${WebRTCSignalModel(type: 'offer', data: {'sdp': offer.sdp, 'type': offer.type}, senderId: _selfId!, receiverId: receiverId).toMap()}',
    );
  }

  Future<void> acceptCall() async {
    if (_remoteId == null || _receivedOffer == null) {
      print('❌ Cannot accept call: No valid offer has been received.');
      return;
    }

    callProvider.callState.set(value: CallState.connected);

    await webrtcService.initPeerConnection(
      onIceCandidate: _sendIceCandidate,
      onAddRemoteStream: (stream) {
        // Handle stream if needed
      },
    );

    await webrtcService.attachLocalAudio();
    await sendAnswer(_receivedOffer!);
    _receivedOffer = null;
  }

  Future<void> sendAnswer(Map<String, dynamic> offer) async {
    final sdp = offer['sdp'];
    final type = offer['type'];

    if (sdp == null || type == null) {
      print('❌ sendAnswer: Missing sdp or type in offer');
      return;
    }

    await webrtcService.setRemoteDescription(sdp, type);

    final answer = await webrtcService.createAnswer();

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'answer',
        data: {'sdp': answer.sdp, 'type': answer.type},
        senderId: _selfId!,
        receiverId: _remoteId!,
      ),
    );
  }

  Future<void> _handleSignal(WebRTCSignalModel signal) async {
    switch (signal.type) {
      case 'offer':
        _remoteId = signal.senderId;

        // ✅ CORRECTED: The data is already a Map. No need for jsonDecode.
        _receivedOffer = signal.data;

        if (_receivedOffer != null) {
          callProvider.callState.set(value: CallState.ringing);
          callProvider.currentCallerId.set(value: signal.senderId);
          onIncomingCall?.call(signal.senderId);
        } else {
          print('❌ Received offer but its data is null.');
        }
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

  bool get _isReadyForSignaling =>
      _token != null && _selfId != null && _remoteId?.isNotEmpty == true;

  Future<void> endCall({bool sendSignal = true}) async {
    if (sendSignal && _isReadyForSignaling) {
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
