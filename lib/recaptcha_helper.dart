// lib/recaptcha_helper.dart

import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' show promiseToFuture;
import 'package:js/js.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

@JS('grecaptcha.execute')
external Object _jsExecute(String siteKey, js.JsObject options);

final Completer<void> _recaptchaLoadedCompleter = Completer<void>();

void initializeRecaptchaV3() {
  if (!kIsWeb) {
    // Complete immediately if not running on web
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
    }
    return;
  }

  // If grecaptcha already loaded, complete immediately
  if (js.context.hasProperty('grecaptcha')) {
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
    }
    return;
  }

  // Set the global callback to complete the completer once API loads
  js.context['recaptchaOnLoad'] = () {
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
      debugPrint('reCAPTCHA v3 API loaded and ready.');
    }
  };
}

Future<String> getRecaptchaToken(String siteKey, String action) async {
  if (!kIsWeb) return '';

  // Wait for grecaptcha to be ready
  if (!_recaptchaLoadedCompleter.isCompleted) {
    debugPrint('Waiting for reCAPTCHA v3 API to load before getting token...');
    await _recaptchaLoadedCompleter.future;
  }

  try {
    final js.JsObject options = js.JsObject.jsify({'action': action});
    final Object promise = _jsExecute(siteKey, options);
    final String token = await promiseToFuture<String>(promise);
    return token;
  } catch (e) {
    debugPrint('Error executing reCAPTCHA: $e');
    throw Exception('reCAPTCHA token generation failed: $e');
  }
}

