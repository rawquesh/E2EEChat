import 'dart:convert';
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

    final offerData = {
      'sdp': base64Encode(utf8.encode(offer.sdp!)),
      'type': offer.type,
    };

    print('📤 Sending offer: ${offer.sdp}, type: ${offer.type}');

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'offer',
        data: offerData, // Use the new encoded data
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
      onAddRemoteStream: (stream) {},
    );

    await Future.delayed(Duration(milliseconds: 100));
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

    try {
      await webrtcService.setRemoteDescription(sdp, type);
      print('✅ Remote offer SDP applied successfully by receiver.');
    } catch (e) {
      print('❌ Receiver failed to set remote description: $e');
      return;
    }

    final answer = await webrtcService.createAnswer();

    // ✅ ENCODE THE ANSWER'S SDP
    // This is the crucial fix on the receiver's side when answering.
    final answerData = {
      'sdp': base64Encode(utf8.encode(answer.sdp!)),
      'type': answer.type,
    };

    print('📤 Sending encoded answer...');
    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(
        type: 'answer',
        data: answerData, // Send the encoded data
        senderId: _selfId!,
        receiverId: _remoteId!,
      ),
    );
  }

  Future<void> _handleSignal(WebRTCSignalModel signal) async {
    switch (signal.type) {
      case 'offer':
        _remoteId = signal.senderId;
        _receivedOffer = signal.data;

        if (_receivedOffer != null) {
          try {
            // ✅ DECODE THE OFFER'S SDP
            final decodedSdp = utf8.decode(
              base64Decode(_receivedOffer!['sdp']),
            );
            _receivedOffer!['sdp'] = decodedSdp;

            if (!_receivedOffer!.containsKey('type')) {
              _receivedOffer!['type'] = 'offer';
            }

            callProvider.callState.set(value: CallState.ringing);
            callProvider.currentCallerId.set(value: signal.senderId);
            onIncomingCall?.call(signal.senderId);
          } catch (e) {
            print('❌ Error decoding OFFER SDP: $e');
          }
        } else {
          print('❌ Received offer with null data.');
        }
        break;

      case 'answer':
        if (signal.data == null) {
          print('❌ Received answer with null data.');
          return;
        }
        try {
          // ✅ DECODE THE ANSWER'S SDP
          // This is the crucial fix on the sender's side when receiving an answer.
          final sdp = utf8.decode(base64Decode(signal.data!['sdp']));
          final type = signal.data!['type'];

          print('✅ Received and decoded answer. Applying...');
          await webrtcService.setRemoteDescription(sdp, type);

          callProvider.callState.set(value: CallState.connected);
          Helper.setSpeakerphoneOn(
            true,
          ); // Enable speakerphone for audio output
          onCallConnected?.call();
        } catch (e) {
          print('❌ Error decoding ANSWER SDP: $e');
        }
        break;

      case 'ice-candidate':
        if (signal.data == null) return;
        final candidate = RTCIceCandidate(
          signal.data!['candidate'],
          signal.data!['sdpMid'],
          signal.data!['sdpMLineIndex'],
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
          data: {'sdp': '', 'type': ''},
        ),
      );
    }

    // The rest of the function remains the same
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
