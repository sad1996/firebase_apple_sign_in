import 'dart:async';

import 'package:flutter/services.dart';

class AppleLogin {
  static const MethodChannel _channel =
      const MethodChannel('apple_login');

  static Future<dynamic> get initiateLogin async {
    return await _channel.invokeMethod('sign_in');
  }
}
