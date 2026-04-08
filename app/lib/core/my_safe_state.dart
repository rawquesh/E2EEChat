import 'package:flutter/material.dart';

mixin MySafeState<T extends StatefulWidget> on State<T> {
  bool _pageMounted = false, _disposed = false;
  late ThemeData themeData;

  bool get pageMounted => _pageMounted;

  @protected
  void pageBuild() {
    _pageMounted = false;
    themeData = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageMounted = true;
    });
  }

  @protected
  void pageDispose() {
    _disposed = true;
    _pageMounted = false;
  }

  @override
  void dispose() {
    pageDispose();
    super.dispose();
  }

  @protected
  void mySetState() {
    try {
      if (_disposed || !mounted) {
        return;
      }
    } catch (e) {
      return;
    }

    if (_pageMounted) {
      setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_pageMounted) {
          setState(() {});
        }
      });
    }
  }
}
