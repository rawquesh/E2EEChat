//To Store Some Important App related Variables
class AppController {
  static AppController? _instance;

  factory AppController() {
    _instance ??= AppController._();
    return _instance!;
  }

  AppController._();

  static String flavor = "";
  static String appType = "";
}
