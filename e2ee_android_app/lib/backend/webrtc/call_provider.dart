import 'package:e2ee_models_app/backend/common/common_provider.dart';

import 'call_controller.dart';

enum CallState { idle, calling, ringing, connected, ended }

class CallProvider extends CommonProvider {
  late final CallController callController;

  CallProvider() {
    callController = CallController(provider: this);

    callState = CommonProviderPrimitiveParameter<CallState>(
      value: CallState.idle,
      notify: notify,
    );
    isMuted = CommonProviderPrimitiveParameter<bool>(
      value: false,
      notify: notify,
    );
    isSpeakerOn = CommonProviderPrimitiveParameter<bool>(
      value: false,
      notify: notify,
    );
    currentCallerId = CommonProviderPrimitiveParameter<String?>(
      value: null,
      notify: notify,
    );
  }

  void initController({required String userId, required String token}) {
    callController.init(userId: userId, token: token);
  }

  late CommonProviderPrimitiveParameter<CallState> callState;
  late CommonProviderPrimitiveParameter<bool> isMuted;
  late CommonProviderPrimitiveParameter<bool> isSpeakerOn;
  late CommonProviderPrimitiveParameter<String?> currentCallerId;
}
