import 'dart:convert';

import 'package:e2ee_models_app/models/calling/WebRTCSignalModel.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_client_socket/pusher_client_socket.dart';

class WebRTCSignalingRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';

  PusherClient? _pusher;
  Channel? _channel;

  void initWebSocket({
    required String userId,
    required String token,
    required Function(WebRTCSignalModel signal) onSignalReceived,
  }) {
    final options = PusherOptions(
      key: 'sip6lkxyrl3d0um6vbv9',
      cluster: 'mt1',
      host: '172.86.92.130.sslip.io',
      wsPort: 8080,
      wssPort: 443,
      encrypted: false,
      authOptions: PusherAuthOptions(
        'https://172.86.92.130.sslip.io/broadcasting/auth',
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    _pusher = PusherClient(options: options);

    _pusher!.onConnectionEstablished((_) {
      MyPrint.printOnConsole('[WEBRTC REPO] Connection established');
    });
    _pusher!.onConnectionError(
      (err) => MyPrint.printOnConsole('[WEBRTC REPO] Connection error: $err'),
    );
    _pusher!.connect();

    final channelName = 'private-chat.$userId';
    _channel = _pusher!.channel(channelName);

    _channel!.bind('WebRTCSignal', (data) {
      if (data != null) {
        try {
          final map = data is String
              ? jsonDecode(data) as Map<String, dynamic>
              : Map<String, dynamic>.from(data);
          final signal = WebRTCSignalModel.fromMap(map);
          onSignalReceived(signal);
        } catch (e) {
          MyPrint.printOnConsole('[WEBRTC REPO] Error parsing signal: $e');
        }
      }
    });
  }

  void disposeWebSocket() {
    _channel?.unbind('WebRTCSignal');
    _pusher?.disconnect();
  }

  Future<bool> sendSignal({
    required String token,
    required WebRTCSignalModel signal,
  }) async {
    final url = Uri.parse('$baseUrl/webrtc-signal');
    final body = jsonEncode(signal.toMap());

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      MyPrint.printOnConsole('[WEBRTC REPO] Error sending signal: $e');
      return false;
    }
  }
}
