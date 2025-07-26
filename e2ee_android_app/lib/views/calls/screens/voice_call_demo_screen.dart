import 'dart:async';
import 'dart:ui';

import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../../backend/navigation/navigation_arguments.dart';
import '../../../backend/webrtc/call_controller.dart';
import '../../../backend/webrtc/call_provider.dart';

class VoiceCallScreen extends StatefulWidget {
  static const String routeName = "/VoiceCallScreen";
  final VoiceCallScreenNavigationArguments arguments;

  const VoiceCallScreen({super.key, required this.arguments});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late CallController _controller;
  late CallProvider _callProvider;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Timer? _callDurationTimer;
  int _callDurationInSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();

    _callProvider = context.read<CallProvider>();
    _controller = _callProvider.callController;

    _callProvider.addListener(_handleProviderChange);

    _controller.onCallConnected = () {
      final stream = _controller.webrtcService.remoteStream;
      if (stream != null && mounted) {
        setState(() => _remoteRenderer.srcObject = stream);
      }
    };

    // If we navigate here after starting a call, the state is already 'calling'
    if (_callProvider.callState.get() == CallState.calling) {
      // The UI will show "Calling..."
    }
  }

  @override
  void dispose() {
    _callProvider.removeListener(_handleProviderChange);
    _remoteRenderer.dispose();
    _callDurationTimer?.cancel();
    super.dispose();
  }

  void _handleProviderChange() {
    final state = _callProvider.callState.get();

    if (state == CallState.connected && _callDurationTimer == null) {
      _startCallTimer();
    }

    if (state == CallState.ended) {
      _stopCallTimer();
      if (mounted) Navigator.pop(context);
    }

    if (mounted) setState(() {});
  }

  void _startCallTimer() {
    _callDurationTimer?.cancel(); // Ensure no multiple timers
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDurationInSeconds++);
    });
  }

  void _stopCallTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _callDurationInSeconds = 0;
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final callState = _callProvider.callState.get();
    final isMuted = _callProvider.isMuted.get();
    final ChatUserModel user = widget.arguments.user;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2c3e50), Color(0xFF34495e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          // Hidden video renderer for audio stream
          SizedBox(
            width: 1,
            height: 1,
            child: RTCVideoView(_remoteRenderer, mirror: false),
          ),
          // UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contact Info
                  _buildContactInfo(user, callState),

                  // Call Controls
                  _buildCallControls(isMuted, callState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(ChatUserModel user, CallState state) {
    String statusText = '';
    switch (state) {
      case CallState.calling:
        statusText = 'Calling...';
        break;
      case CallState.ringing:
        statusText = 'Ringing...';
        break;
      case CallState.connected:
        statusText = _formatDuration(_callDurationInSeconds);
        break;
      case CallState.ended:
        statusText = 'Call Ended';
        break;
      default:
        statusText = 'Connecting...';
    }

    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              user.avatar,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCallControls(bool isMuted, CallState state) {
    if (state == CallState.ended) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: isMuted ? Icons.mic_off : Icons.mic,
          onTap: () => _controller.mute(!isMuted),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
        _buildControlButton(
          icon: Icons.call_end,
          onTap: () => _controller.endCall(),
          backgroundColor: Colors.red,
        ),
        _buildControlButton(
          icon: Icons.volume_up,
          onTap: () {
            // Implement speaker toggle
          },
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
