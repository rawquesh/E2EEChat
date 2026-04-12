import 'dart:convert';

import 'package:e2ee_android_app/models/calling/web_rtc_signal_model.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_client_socket/pusher_client_socket.dart';

import '../authentication/auth_utils.dart';
import '../common/api_endpoints.dart';

class WebRTCSignalingRepository {
  PusherClient? _pusher;
  Channel? _channel;

  void initWebSocket({
    required String userId,
    required String token,
    required Function(WebRTCSignalModel signal) onSignalReceived,
  }) {
    final options = PusherOptions(
      key: ApiEndpoints.pusherKey,
      cluster: ApiEndpoints.pusherCluster,
      host: ApiEndpoints.pusherHost,
      wsPort: ApiEndpoints.pusherWsPort,
      wssPort: ApiEndpoints.pusherWssPort,
      encrypted: ApiEndpoints.pusherEncrypted,
      authOptions: PusherAuthOptions(
        ApiEndpoints.pusherBroadcastingAuthUrl,
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
    final url = Uri.parse(ApiEndpoints.urlWebrtcSignal);
    final body = jsonEncode(signal.toMap());

    MyPrint.printOnConsole('[WEBRTC REPO] Sending signal: ${signal.type}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      MyPrint.printOnConsole(
        '[WEBRTC REPO] Signal sent with status: ${response.statusCode}',
      );
      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
      }
      return response.statusCode == 200;
    } catch (e) {
      MyPrint.printOnConsole('[WEBRTC REPO] Error sending signal: $e');
      return false;
    }
  }
}
