// lib/service/recaptcha_service.dart

import 'dart:async';
import 'package:js/js.dart';
import 'dart:js_util';

// JS interop class for options
@JS()
@anonymous
class RecaptchaOptions {
  external String get action;
  external factory RecaptchaOptions({String action});
}

// JS function binding
@JS('grecaptcha.execute')
external Object _execute(String siteKey, RecaptchaOptions options);

class RecaptchaService {
  /// Generates a reCAPTCHA token for a given action.
  Future<String> executeRecaptcha(String siteKey, String action) async {
    if (siteKey.isEmpty) {
      throw Exception('reCAPTCHA Site Key is not set. Use --dart-define to provide it.');
    }

    final options = RecaptchaOptions(action: action);

    final Object promise = _execute(siteKey, options);

    try {
      final token = await promiseToFuture<String>(promise);
      return token;
    } catch (e) {
      print('Failed to execute reCAPTCHA. Error: $e');
      throw Exception('Could not retrieve reCAPTCHA token.');
    }
  }
}

