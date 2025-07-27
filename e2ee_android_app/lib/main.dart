import 'configs/constants.dart';
import 'init.dart';

Future<void> main() async {
  await runErrorSafeApp(appFlavor: AppFlavors.development);
}
