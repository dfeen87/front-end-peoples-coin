import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' show promiseToFuture;
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';

@JS('grecaptcha.ready')
external void _grecaptchaReady(Function callback);

@JS('grecaptcha.execute')
external Object _grecaptchaExecute(String siteKey, Object options);

final Completer<void> _recaptchaLoadedCompleter = Completer<void>();

/// Call once at startup
void initializeRecaptchaV3() {
  if (!kIsWeb) {
    _recaptchaLoadedCompleter.complete();
    return;
  }

  // Ensure global JS callback exists for HTML script tag
  js.context['recaptchaOnLoad'] = () {
    print('✅ reCAPTCHA v3 API loaded and ready.');
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
    }
  };

  // If grecaptcha already exists, resolve immediately
  if (js.context.hasProperty('grecaptcha')) {
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
    }
  }
}

/// Get a token for a given action (e.g., "signup")
Future<String> getRecaptchaToken(String siteKey, String action) async {
  if (!kIsWeb) return '';

  // Wait for the script to load
  await _recaptchaLoadedCompleter.future;

  final completer = Completer<String>();

  try {
    _grecaptchaReady(allowInterop(() {
      final options = js.JsObject.jsify({'action': action});
      final Object promise = _grecaptchaExecute(siteKey, options);
      promiseToFuture<String>(promise)
          .then(completer.complete)
          .catchError((error) {
        print('❌ Error generating token: $error');
        completer.completeError(error);
      });
    }));
  } catch (e) {
    completer.completeError('reCAPTCHA token generation failed: $e');
  }

  return completer.future;
}

