import 'dart:ui';

import 'package:e2ee_android_app/backend/webrtc/webRTC_service.dart';
import 'package:e2ee_android_app/backend/webrtc/webRTC_signaling_repository.dart';
import 'package:e2ee_android_app/models/calling/web_rtc_signal_model.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:e2ee_android_app/utils/my_utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:e2ee_android_app/pages/calls/calls_screen.dart';
import 'call_provider.dart';

class CallController {
  Map<String, dynamic>? _receivedOffer;

  late CallProvider callProvider;
  late WebRTCSignalingRepository signalingRepository;
  late WebRTCService webrtcService;
  final CallHistoryRepository _callHistoryRepository = CallHistoryRepository();

  String? _selfId;
  String? _token;
  String? _remoteId;
  String? _remoteName;
  String? _remoteAvatar;

  Function(String callerId)? onIncomingCall;
  VoidCallback? onCallConnected;
  VoidCallback? onCallEnded;

  CallController({CallProvider? provider, WebRTCSignalingRepository? repository, WebRTCService? service}) {
    callProvider = provider ?? CallProvider();
    signalingRepository = repository ?? WebRTCSignalingRepository();
    webrtcService = service ?? WebRTCService();
  }

  void init({required String userId, required String token}) {
    _selfId = userId;
    _token = token;

    signalingRepository.initWebSocket(userId: userId, token: token, onSignalReceived: _handleSignal);
  }

  Future<void> startCall(String receiverId, {String? receiverName, String? receiverAvatar}) async {
    _remoteId = receiverId;
    _remoteName = receiverName;
    _remoteAvatar = receiverAvatar;
    callProvider.callState.set(value: CallState.calling);

    await webrtcService.initPeerConnection(
      onIceCandidate: _sendIceCandidate,
      onAddRemoteStream: (stream) {},
      onConnectionState: _handleConnectionStateChange,
    );
    await webrtcService.attachLocalAudio();

    final offer = await webrtcService.createOffer();

    // 💥 ADD THIS DEBUG PRINT
    MyPrint.printOnConsole("--- SENDER: CREATED OFFER ---");
    MyPrint.printOnConsole("SDP is null or empty: ${offer.sdp == null || offer.sdp!.isEmpty}");
    MyPrint.printOnConsole("SDP value: ${offer.sdp}");
    MyPrint.printOnConsole("-----------------------------");

    // This check will stop an invalid offer from being sent.
    if (offer.sdp == null || offer.sdp!.isEmpty) {
      MyPrint.printOnConsole("❌ ERROR: Created an empty SDP offer. Aborting call.");
      return;
    }

    final offerData = {'sdp': offer.sdp, 'type': offer.type};

    MyPrint.printOnConsole('📤 Sending offer: ${offer.sdp}, type: ${offer.type}');

    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(type: 'offer', data: offerData, senderId: _selfId!, receiverId: receiverId),
    );

    await _callHistoryRepository.addCall(
      CallRecord(
        id: MyUtils.getNewId(),
        contactName: _remoteName ?? 'Unknown',
        avatar: _remoteAvatar ?? 'U',
        callType: CallType.voice,
        callStatus: CallStatus.outgoing,
        timestamp: DateTime.now(),
        phoneNumber: _remoteId!,
        // Store remoteId as phoneNumber for redial
        duration: 0,
      ),
    );

    MyPrint.printOnConsole(
      '📦 Sent signal payload: ${WebRTCSignalModel(type: 'offer', data: {'sdp': offer.sdp, 'type': offer.type}, senderId: _selfId!, receiverId: receiverId).toMap()}',
    );
  }

  // ✨ ADD A NEW HELPER FUNCTION
  void _handleConnectionStateChange(RTCPeerConnectionState state) {
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      // This is the true "connected" moment for both caller and receiver
      if (callProvider.callState.get() != CallState.connected) {
        MyPrint.printOnConsole('🎉 CALL IS FULLY CONNECTED! 🎉');
        callProvider.callState.set(value: CallState.connected);
        onCallConnected?.call();
      }
    }
  }

  Future<void> acceptCall() async {
    if (_remoteId == null || _receivedOffer == null) {
      MyPrint.printOnConsole('❌ Cannot accept call: No valid offer has been received.');
      return;
    }

    // callProvider.callState.set(value: CallState.connected);

    await webrtcService.initPeerConnection(
      onIceCandidate: _sendIceCandidate,
      onAddRemoteStream: (stream) {},
      onConnectionState: _handleConnectionStateChange,
    );

    await Future.delayed(Duration(milliseconds: 100));
    await webrtcService.attachLocalAudio();
    await sendAnswer(_receivedOffer!);
    _receivedOffer = null;

    await webrtcService.routeAudioToEarpiece(); // <-- default to earpiece here

    await _callHistoryRepository.addCall(
      CallRecord(
        id: MyUtils.getNewId(),
        contactName: _remoteName ?? 'Unknown',
        avatar: _remoteAvatar ?? 'U',
        callType: CallType.voice,
        callStatus: CallStatus.incoming,
        timestamp: DateTime.now(),
        phoneNumber: _remoteId!,
        // Store remoteId as phoneNumber for redial
        duration: 0,
      ),
    );
  }

  Future<void> sendAnswer(Map<String, dynamic> offer) async {
    // 'offer' is now the clean _receivedOffer map: {'sdp': '...', 'type': 'offer'}
    final sdp = offer['sdp']; // This is now a String, as expected
    final type = offer['type']; // This is now "offer", as expected

    if (sdp == null || type == null) {
      MyPrint.printOnConsole('❌ sendAnswer: Missing sdp or type in offer');
      return;
    }

    try {
      // This will now succeed
      await webrtcService.setRemoteDescription(sdp, type);
      MyPrint.printOnConsole('✅ Remote offer SDP applied successfully by receiver.');
    } catch (e) {
      MyPrint.printOnConsole('❌ Receiver failed to set remote description: $e');
      return;
    }
    final answer = await webrtcService.createAnswer();

    final answerData = {'sdp': answer.sdp, 'type': answer.type};

    MyPrint.printOnConsole('📤 Sending encoded answer...');
    await signalingRepository.sendSignal(
      token: _token!,
      signal: WebRTCSignalModel(type: 'answer', data: answerData, senderId: _selfId!, receiverId: _remoteId!),
    );
  }

  Future<void> _handleSignal(WebRTCSignalModel signal) async {
    switch (signal.type) {
      case 'offer':
        // 💥 ADD THIS DEBUG PRINT
        MyPrint.printOnConsole("--- RECEIVER: GOT OFFER SIGNAL ---");
        MyPrint.printOnConsole("Full data received: ${signal.data}");
        MyPrint.printOnConsole("----------------------------------");

        _remoteId = signal.senderId;

        if (signal.data != null && signal.data!['sdp'] != null) {
          try {
            // 1. 💥 Get the SDP STRING from the data payload.
            final String sdpString = signal.data!['sdp'] as String;

            // 2. 💥 Get the description TYPE from the signal type itself ("offer").
            final String sdpType = signal.type;

            // 3. Store a clean, correctly structured offer object.
            _receivedOffer = {'sdp': sdpString, 'type': sdpType};

            MyPrint.printOnConsole('✅ Parsed remote offer successfully.');

            callProvider.callState.set(value: CallState.ringing);
            callProvider.currentCallerId.set(value: signal.senderId);
            onIncomingCall?.call(signal.senderId);
          } catch (e) {
            MyPrint.printOnConsole('❌ Error processing OFFER payload: $e');
          }
        } else {
          MyPrint.printOnConsole('❌ Received offer with null or invalid data payload.');
        }
        break;

      case 'answer':
        if (signal.data == null) {
          MyPrint.printOnConsole('❌ Received answer with null data.');
          return;
        }
        try {
          // 💥 REMOVE decoding logic.
          final sdp = signal.data!['sdp'];
          final type = signal.data!['type'];

          MyPrint.printOnConsole('✅ Received answer. Applying...');
          await webrtcService.setRemoteDescription(sdp, type);

          // callProvider.callState.set(value: CallState.connected);
          await webrtcService.routeAudioToEarpiece();
          onCallConnected?.call();
        } catch (e) {
          MyPrint.printOnConsole('❌ Error applying ANSWER: $e');
        }
        break;

      case 'ice-candidate':
        if (signal.data == null) return;
        final candidate = RTCIceCandidate(signal.data!['candidate'], signal.data!['sdpMid'], signal.data!['sdpMLineIndex']);
        await webrtcService.addIceCandidate(candidate);
        break;

      case 'hangup':
        await endCall(sendSignal: false);
        break;
    }
  }

  bool get _isReadyForSignaling => _token != null && _selfId != null && _remoteId?.isNotEmpty == true;

  Future<void> endCall({bool sendSignal = true}) async {
    if (sendSignal && _isReadyForSignaling) {
      await signalingRepository.sendSignal(
        token: _token!,
        signal: WebRTCSignalModel(type: 'hangup', senderId: _selfId!, receiverId: _remoteId!, data: {'sdp': '', 'type': ''}),
      );
    }

    await webrtcService.dispose();
    callProvider.reset(); // This will notify listeners
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
        data: {'candidate': candidate.candidate, 'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex},
        senderId: _selfId!,
        receiverId: _remoteId!,
      ),
    );
  }
}
