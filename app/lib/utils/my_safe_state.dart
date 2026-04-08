import 'package:flutter/material.dart';

mixin MySafeState<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void mySetState([VoidCallback? fn]) {
    if (mounted) {
      if (fn != null) {
        super.setState(fn);
      } else {
        super.setState(() {});
      }
    }
  }

  late ThemeData themeData;
  late BuildContext buildContext;

  void pageBuild() {
    themeData = Theme.of(context);
    buildContext = context;
  }
}
