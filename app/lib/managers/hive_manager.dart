import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/my_print.dart';

class HiveManager {
  static final HiveManager _instance = HiveManager._();

  factory HiveManager() => _instance;

  HiveManager._();

  final String _databaseName = 'mydatabase';
  String defaultBoxName = 'mybox';

  Box? _defaultBox;

  bool _isHiveDatabaseInitialized = false;

  Future<bool> initializeHiveDatabase() async {
    MyPrint.printOnConsole("initializeHiveDatabase called");

    if (!_isHiveDatabaseInitialized) {
      try {
        String? databasePath;
        if (!kIsWeb) {
          try {
            final appDocumentDir = await getApplicationDocumentsDirectory();
            databasePath = "${appDocumentDir.path}/$_databaseName";
          } catch (e, s) {
            MyPrint.printOnConsole(
                "Error in Getting Path in HiveManager.initializeHiveDatabase():$e");
            MyPrint.printOnConsole(s.toString());
          }
        }
        MyPrint.printOnConsole("databasePath : $databasePath");
        Hive.init(
          databasePath,
          backendPreference:
              kIsWeb ? HiveStorageBackendPreference.webWorker : HiveStorageBackendPreference.native,
        );
        _isHiveDatabaseInitialized = true;
      } catch (e, s) {
        MyPrint.printOnConsole("Error in HiveManager.initializeHiveDatabase():$e");
        MyPrint.printOnConsole(s.toString());
      }
    }

    return _isHiveDatabaseInitialized;
  }

  Future<Box<T>?> openBox<T>({required String boxName}) async {
    MyPrint.printOnConsole("openBox called with BoxName:'$boxName'");

    try {
      bool isHiveInitialized = await initializeHiveDatabase();
      MyPrint.printOnConsole("isHiveInitialized:$isHiveInitialized");

      if (isHiveInitialized) {
        Box<T> box = await Hive.openBox<T>(boxName);
        return box;
      }
    } catch (e, s) {
      MyPrint.printOnConsole("Error in HiveManager.openBox():$e");
      MyPrint.printOnConsole(s.toString());
    }

    return null;
  }

  Future<Box?> initializeDefaultBox() async {
    MyPrint.printOnConsole("initializeDefaultBox called");

    if (_defaultBox == null) {
      try {
        _defaultBox = await openBox(boxName: defaultBoxName);
      } catch (e, s) {
        MyPrint.printOnConsole("Error in HiveManager.initializeDefaultBox():$e");
        MyPrint.printOnConsole(s.toString());
      }
    }
    MyPrint.printOnConsole("_defaultBox:$_defaultBox");

    return _defaultBox;
  }

  Future<dynamic> get({required String key, dynamic defaultValue, Box? box}) async {
    Box? db = box ?? (await initializeDefaultBox());
    return db?.get(key, defaultValue: defaultValue);
  }

  Future<void> set({required String key, required dynamic value, Box? box}) async {
    Box? db = box ?? (await initializeDefaultBox());
    await db?.put(key, value);
  }

  Future<void> delete({required String key, Box? box}) async {
    Box? db = box ?? (await initializeDefaultBox());
    await db?.delete(key);
  }
}
