// lib/recaptcha_helper.dart
import 'dart:async';
import 'package:js/js.dart';

// --- For reCAPTCHA v3 (Invisible) ---

@JS('grecaptcha.execute')
external Future<String> _execute(String siteKey, ActionOptions options);

@JS()
@anonymous
class ActionOptions {
  external String get action;
  external factory ActionOptions({String action});
}

/// Requests a reCAPTCHA v3 token for the login screen.
Future<String> getRecaptchaV3Token(String siteKey, String action) {
  return _execute(siteKey, ActionOptions(action: action));
}


// --- For reCAPTCHA v2 (Checkbox) ---

@JS('grecaptcha.getResponse')
external String getV2RecaptchaToken();
