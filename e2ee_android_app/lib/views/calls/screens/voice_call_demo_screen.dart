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
  final TextEditingController _idController = TextEditingController();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();

    _controller = context.read<CallProvider>().callController;
    _controller.onCallConnected = () {
      final stream = _controller.webrtcService.remoteStream;
      if (stream != null) _remoteRenderer.srcObject = stream;
    };
  }

  @override
  void dispose() {
    context.read<CallProvider>().callController.onCallConnected = null;
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final controller = callProvider.callController;

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
                  Text('State: ${callProvider.callState.get().toString()}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            controller.startCall(_idController.text),
                        child: const Text('Start'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.acceptCall,
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.endCall,
                        child: const Text('End'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () =>
                        controller.mute(!callProvider.isMuted.get()),
                    child: Text(callProvider.isMuted.get() ? 'Unmute' : 'Mute'),
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
