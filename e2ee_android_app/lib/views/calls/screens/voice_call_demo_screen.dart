import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../../backend/webrtc/call_controller.dart';
import '../../../backend/webrtc/call_provider.dart';

class VoiceCallDemoScreen extends StatefulWidget {
  static const String routeName = "/VoiceCallDemoScreen";

  const VoiceCallDemoScreen({super.key});

  @override
  State<VoiceCallDemoScreen> createState() => _VoiceCallDemoScreenState();
}

class _VoiceCallDemoScreenState extends State<VoiceCallDemoScreen> {
  late CallController _controller;
  late CallProvider _callProvider;
  final TextEditingController _idController = TextEditingController();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();

    _callProvider = context.read<CallProvider>();
    _controller = _callProvider.callController;

    _controller.onIncomingCall = _showIncomingCallDialog;

    _callProvider.addListener(_handleProviderChange);

    _controller.onCallConnected = () {
      final stream = _controller.webrtcService.remoteStream;
      if (stream != null) {
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      }
    };
  }

  @override
  void dispose() {
    _controller.onIncomingCall = null;
    _callProvider.removeListener(_handleProviderChange);
    _remoteRenderer.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _handleProviderChange() {
    final state = _callProvider.callState.get();
    if (state == CallState.ended && _isDialogShowing) {
      _dismissCallDialog();
    }
    // We can also call setState here if parts of the UI that are not
    // wrapped in a Consumer need to update.
    if (mounted) {
      setState(() {});
    }
  }

  // Method to show the incoming call dialog
  void _showIncomingCallDialog(String callerId) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Incoming Call 📞'),
          content: Text('Call from: $callerId'),
          actions: <Widget>[
            TextButton(
              child: const Text('Decline'),
              onPressed: () {
                _controller.endCall();
                _dismissCallDialog();
              },
            ),
            TextButton(
              child: const Text('Accept'),
              onPressed: () {
                _controller.acceptCall();
                _dismissCallDialog();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to dismiss the dialog if it's showing
  void _dismissCallDialog() {
    if (_isDialogShowing) {
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can use Consumer or context.watch. Here we use the direct provider instance
    // since we are listening manually and calling setState in _handleProviderChange.
    final callState = _callProvider.callState.get();
    final isMuted = _callProvider.isMuted.get();

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Call Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (callState == CallState.idle || callState == CallState.ended)
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Receiver ID',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'State: ${callState.toString().split('.').last.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildCallButtons(_controller, callState),
            const SizedBox(height: 16),
            if (callState == CallState.connected)
              TextButton.icon(
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                onPressed: () => _controller.mute(!isMuted),
                label: Text(isMuted ? 'Unmute' : 'Mute'),
              ),
            // Hidden video renderer for audio stream
            SizedBox(
              width: 1,
              height: 1,
              child: RTCVideoView(_remoteRenderer, mirror: false),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build action buttons based on state
  Widget _buildCallButtons(CallController controller, CallState state) {
    if (state == CallState.idle || state == CallState.ended) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.call),
        onPressed: () {
          if (_idController.text.isNotEmpty) {
            controller.startCall(_idController.text);
          }
        },
        label: const Text('Start Call'),
      );
    }

    if (state == CallState.connected ||
        state == CallState.calling ||
        state == CallState.ringing) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.call_end),
        onPressed: controller.endCall,
        label: const Text('End Call'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      );
    }
    return const SizedBox.shrink();
  }
}
