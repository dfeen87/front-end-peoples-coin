// lib/helpers/recaptcha_helper.dart

@JS()
library recaptcha_helper;

import 'dart:async';
import 'package:js/js.dart';

@JS('grecaptcha.execute')
external void _grecaptchaExecute(String siteKey, dynamic options, Function(String) callback);

/// Requests a reCAPTCHA v3 token for the given site key and action.
/// Returns the token as a Future<String>.
Future<String> getRecaptchaToken(String siteKey, String action) {
  final completer = Completer<String>();

  _grecaptchaExecute(siteKey, {'action': action}, allowInterop((token) {
    completer.complete(token);
  }));

  return completer.future;
}

