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
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:172.86.92.130.sslip.io:3478'},
      {
        'urls': 'turn:172.86.92.130.sslip.io:3478?transport=udp',
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

  /// Initializes the peer connection
  Future<void> initPeerConnection({
    required Function(RTCIceCandidate) onIceCandidate,
    required Function(MediaStream stream) onAddRemoteStream,
  }) async {
    _onIceCandidateCallback = onIceCandidate;
    _onAddRemoteStreamCallback = onAddRemoteStream;

    _peerConnection = await createPeerConnection(_iceServers, _constraints);
    print('✅ PeerConnection created: $_peerConnection');

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _onIceCandidateCallback?.call(candidate);
      }
    };

    _peerConnection?.onAddStream = (stream) {
      _remoteStream = stream;
      _onAddRemoteStreamCallback?.call(stream);
    };
  }

  /// Attach microphone audio to peer
  Future<void> attachLocalAudio() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    if (_peerConnection != null && _localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!); // ✅ FIXED
      }
    }
  }

  /// Create and set local SDP offer
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection?.createOffer({
      'offerToReceiveAudio': 1,
    });
    await _peerConnection?.setLocalDescription(offer!);
    return offer!;
  }

  /// Create and set local SDP answer
  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection?.createAnswer({
      'offerToReceiveAudio': 1,
    });
    await _peerConnection?.setLocalDescription(answer!);
    return answer!;
  }

  /// Set the remote peer's SDP
  Future<void> setRemoteDescription(String? sdp, String? type) async {
    if (sdp == null ||
        sdp.trim().isEmpty ||
        type == null ||
        type.trim().isEmpty) {
      print('❌ setRemoteDescription: SDP or type is null/empty.');
      MyPrint.printOnConsole(
        '❌ Cannot apply remote description – invalid sdp or type',
      );
      MyPrint.printOnConsole('SDP: $sdp');
      MyPrint.printOnConsole('Type: $type');
      return;
    }

    try {
      final description = RTCSessionDescription(sdp, type);
      MyPrint.printOnConsole(
        '🎯 Applying remote SDP:\nType: $type\nSDP:\n$sdp',
      );
      await _peerConnection?.setRemoteDescription(description);
      MyPrint.printOnConsole('✅ setRemoteDescription applied successfully.');
    } catch (e, stack) {
      MyPrint.printOnConsole(
        '❌ setRemoteDescription failed with error: $e\n$stack',
      );
      rethrow; // optional: remove if you want to fail silently
    }
  }

  /// Add an incoming ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
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

    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _onIceCandidateCallback = null;
    _onAddRemoteStreamCallback = null;
  }

  /// Optional getters if UI or logs need them
  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;

  RTCPeerConnection? get peerConnection => _peerConnection;
}
