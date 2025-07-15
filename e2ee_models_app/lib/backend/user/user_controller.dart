import 'package:e2ee_models_app/backend/user/user_provider.dart';
import 'package:e2ee_models_app/backend/user/user_repository.dart';

class UserController {
  late UserRepository _userRepository;
  late UserProvider _userProvider;

  UserController({
    UserRepository? repository,
    UserProvider? provider,
  }) {
    _userRepository = repository ?? UserRepository();
    _userProvider = provider ?? UserProvider();
  }

  UserRepository get userRepository => _userRepository;

  UserProvider get userProvider => _userProvider;

}