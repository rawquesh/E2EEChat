import 'package:flutter/material.dart';

import '../utils/my_print.dart';
import 'navigation_operation_parameters.dart';
import 'navigation_type.dart';

class NavigationOperation {
  static Future<dynamic> navigate({required NavigationOperationParameters navigationOperationParameters}) async {
    if (navigationOperationParameters.navigationType == NavigationType.push) {
      if (navigationOperationParameters.route != null) {
        return Navigator.push(
          navigationOperationParameters.context,
          navigationOperationParameters.route!,
        );
      } else {
        MyPrint.printOnConsole("Could not perform Push Operation because route is null");
      }
    } else if (navigationOperationParameters.navigationType == NavigationType.pushNamed) {
      if (navigationOperationParameters.routeName?.isNotEmpty ?? false) {
        return Navigator.pushNamed(
          navigationOperationParameters.context,
          navigationOperationParameters.routeName!,
          arguments: navigationOperationParameters.arguments,
        );
      } else {
        MyPrint.printOnConsole("Could not perform PushNamed Operation because routeName is null or Empty");
      }
    } else if (navigationOperationParameters.navigationType == NavigationType.pushAndRemoveUntil) {
      if (navigationOperationParameters.route != null) {
        return Navigator.pushAndRemoveUntil(
          navigationOperationParameters.context,
          navigationOperationParameters.route!,
          navigationOperationParameters.predicate ?? (_) => false,
        );
      } else {
        MyPrint.printOnConsole("Could not perform PushAndRemoveUntil Operation because route is null");
      }
    } else if (navigationOperationParameters.navigationType == NavigationType.pushNamedAndRemoveUntil) {
      if (navigationOperationParameters.routeName?.isNotEmpty ?? false) {
        return Navigator.pushNamedAndRemoveUntil(
          navigationOperationParameters.context,
          navigationOperationParameters.routeName!,
          navigationOperationParameters.predicate ?? (_) => false,
          arguments: navigationOperationParameters.arguments,
        );
      } else {
        MyPrint.printOnConsole("Could not perform PushNamedAndRemoveUntil Operation because routeName is null or Empty");
      }
    } else if (navigationOperationParameters.navigationType == NavigationType.popAndPushNamed) {
      if (navigationOperationParameters.routeName?.isNotEmpty ?? false) {
        return Navigator.popAndPushNamed(
          navigationOperationParameters.context,
          navigationOperationParameters.routeName!,
          result: navigationOperationParameters.result,
          arguments: navigationOperationParameters.arguments,
        );
      } else {
        MyPrint.printOnConsole("Could not perform PopAndPushNamed Operation because routeName is null or Empty");
      }
    } else if (navigationOperationParameters.navigationType == NavigationType.go) {
      if (navigationOperationParameters.routeName?.isNotEmpty ?? false) {
        return Navigator.popAndPushNamed(
          navigationOperationParameters.context,
          navigationOperationParameters.routeName!,
          result: navigationOperationParameters.result,
          arguments: navigationOperationParameters.arguments,
        );
      } else {
        MyPrint.printOnConsole("Could not perform PopAndPushNamed Operation because routeName is null or Empty");
      }
    }
  }
}
