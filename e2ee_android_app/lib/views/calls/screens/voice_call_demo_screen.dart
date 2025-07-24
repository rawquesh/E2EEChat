import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../../backend/webrtc/call_controller.dart';
import '../../../backend/webrtc/call_provider.dart';

class VoiceCallDemoScreen extends StatefulWidget {
  const VoiceCallDemoScreen({super.key});

  @override
  State<VoiceCallDemoScreen> createState() => _VoiceCallDemoScreenState();
}

class _VoiceCallDemoScreenState extends State<VoiceCallDemoScreen> {
  late CallController _controller;
  final TextEditingController _idController = TextEditingController();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();

    final provider = CallProvider();
    _controller = CallController(provider: provider);
    _controller.init(userId: '1', token: '');
    _controller.onCallConnected = () {
      final stream = _controller.webrtcService.remoteStream;
      if (stream != null) _remoteRenderer.srcObject = stream;
    };
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller.callProvider,
      child: Consumer<CallProvider>(
        builder: (context, p, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Voice Call Demo')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'Receiver ID'),
                  ),
                  const SizedBox(height: 16),
                  Text('State: ${p.callState.get().toString()}'),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _controller.startCall(_idController.text),
                        child: const Text('Start Call'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _controller.acceptCall,
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _controller.endCall,
                        child: const Text('End'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _controller.mute(!p.isMuted.get()),
                        child: Text(p.isMuted.get() ? 'Unmute' : 'Mute'),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: RTCVideoView(
                      _remoteRenderer,
                      mirror: false,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
