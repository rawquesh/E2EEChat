import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  Function(RTCIceCandidate)? _onIceCandidateCallback;
  Function(MediaStream)? _onAddRemoteStreamCallback;

  /// STUN/TURN servers
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': [
          'turn:172.86.92.130.sslip.io:3478?transport=udp',
          'turn:172.86.92.130.sslip.io:3478?transport=tcp',
          'turns:172.86.92.130.sslip.io:5349?transport=tcp',
        ],
        'username': 'webrtcuser',
        'credential': 'webrtccred',
      },
    ],
  };

  /// Optional peer connection constraints
  static const Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Function(RTCPeerConnectionState)? _onConnectionStateCallback;

  final List<RTCIceCandidate> _iceCandidateQueue = [];

  /// Initializes the peer connection
  Future<void> initPeerConnection({
    required Function(RTCIceCandidate) onIceCandidate,
    required Function(MediaStream stream) onAddRemoteStream,
    // ✨ ADD THIS NEW PARAMETER
    required Function(RTCPeerConnectionState state) onConnectionState,
  }) async {
    if (_peerConnection != null) {
      await dispose();
    }

    _onIceCandidateCallback = onIceCandidate;
    _onAddRemoteStreamCallback = onAddRemoteStream;
    // ✨ STORE THE NEW CALLBACK
    _onConnectionStateCallback = onConnectionState;

    _peerConnection = await createPeerConnection(_iceServers, _constraints);

    // ✨ LISTEN FOR THE CONNECTION STATE
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('♻️ Connection State Changed: $state');
      _onConnectionStateCallback?.call(state);
    };

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _onIceCandidateCallback?.call(candidate);
      }
    };

    // 💥 REPLACE onAddStream with onTrack
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      print('🛤️ Track received: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _onAddRemoteStreamCallback?.call(_remoteStream!);
      }
    };

    // 🗑️ REMOVE this old callback
    // _peerConnection?.onAddStream = (stream) {
    //   _remoteStream = stream;
    //   _onAddRemoteStreamCallback?.call(stream);
    // };
  }

  /// Attach microphone audio to peer
  Future<void> attachLocalAudio() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

    if (_peerConnection != null && _localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!); // ✅ FIXED
      }
    }
  }

  /// Create and set local SDP offer
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection?.createOffer({'offerToReceiveAudio': 1});
    await _peerConnection?.setLocalDescription(offer!);
    return offer!;
  }

  /// Create and set local SDP answer
  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection?.createAnswer({'offerToReceiveAudio': 1});
    await _peerConnection?.setLocalDescription(answer!);
    return answer!;
  }

  /// Set the remote peer's SDP
  Future<void> setRemoteDescription(String? sdp, String? type) async {
    if (sdp == null || sdp.trim().isEmpty || type == null || type.trim().isEmpty) {
      print('❌ setRemoteDescription: SDP or type is null/empty.');
      MyPrint.printOnConsole('❌ Cannot apply remote description – invalid sdp or type');
      MyPrint.printOnConsole('SDP: $sdp');
      MyPrint.printOnConsole('Type: $type');
      return;
    }

    try {
      // 💥 THE FIX: Ensure the SDP string is properly terminated.
      String formattedSdp = sdp;
      if (!formattedSdp.endsWith('\r\n')) {
        formattedSdp += '\r\n';
      }

      // Pass the correctly formatted SDP to the constructor.
      final description = RTCSessionDescription(formattedSdp, type);
      MyPrint.printOnConsole('🎯 Applying remote SDP:\nType: $type\nSDP:\n$sdp');
      await _peerConnection?.setRemoteDescription(description);
      MyPrint.printOnConsole('✅ setRemoteDescription applied successfully.');

      // ✨ 2. Drain the queue AFTER the remote description is set
      if (_iceCandidateQueue.isNotEmpty) {
        print('Applying ${_iceCandidateQueue.length} queued ICE candidates...');
        for (final candidate in _iceCandidateQueue) {
          await _peerConnection?.addCandidate(candidate);
        }
        _iceCandidateQueue.clear();
      }
    } catch (e, stack) {
      MyPrint.printOnConsole('❌ setRemoteDescription failed with error: $e\n$stack');
      rethrow; // optional: remove if you want to fail silently
    }
  }

  /// Add an incoming ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null || (await _peerConnection?.getRemoteDescription()) == null) {
      print('Peer not ready, queueing ICE candidate.');
      _iceCandidateQueue.add(candidate);
      return;
    }
    await _peerConnection?.addCandidate(candidate);
  }

  /// Toggle local mic mute
  void toggleMute(bool mute) {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !mute;
    }
  }

  /// Clean up peer connection and streams
  Future<void> dispose() async {
    await _peerConnection?.close();
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _iceCandidateQueue.clear(); // Clear the queue

    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _onIceCandidateCallback = null;
    _onAddRemoteStreamCallback = null;
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    // final mediaConstraints = <String, dynamic>{'mandatory': {}, 'optional': []};
    await Helper.setSpeakerphoneOn(enable);
  }

  Future<void> routeAudioToEarpiece() async {
    await setSpeakerphoneOn(false); // false to route to earpiece
  }

  Future<void> routeAudioToSpeaker() async {
    await setSpeakerphoneOn(true); // true to route to speaker
  }

  /// Optional getters if UI or logs need them
  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;

  RTCPeerConnection? get peerConnection => _peerConnection;
}
