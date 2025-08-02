library recaptcha; // Must be the very first line (before imports)

import 'dart:async';
import 'package:js/js.dart';

@JS('grecaptcha.execute')
external void _execute(String siteKey, RecaptchaOptions options);

@JS()
@anonymous
class RecaptchaOptions {
  external String get action;
  external Function(String token) get callback;

  external factory RecaptchaOptions({
    String action,
    Function(String) callback,
  });
}

/// Executes Google reCAPTCHA v3 with the given [siteKey] and [action].
/// Returns the generated token as a [Future<String>].
Future<String> executeRecaptcha(String siteKey, String action) {
  final completer = Completer<String>();

  _execute(
    siteKey,
    RecaptchaOptions(
      action: action,
      callback: allowInterop((String token) {
        completer.complete(token);
      }),
    ),
  );

  return completer.future;
}

