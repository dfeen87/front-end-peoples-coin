// lib/recaptcha_helper.dart
import 'dart:async';
import 'dart:js' as js; // Make sure to import 'dart:js'
import 'package:flutter/foundation.dart'; // For debugPrint

// Completer to signal when reCAPTCHA is loaded and ready
// This is crucial for handling the async loading of grecaptcha.
final Completer<void> _recaptchaLoadedCompleter = Completer<void>();

/// Initializes the reCAPTCHA v3 JavaScript API.
/// This should be called once, e.g., on app startup or before using reCAPTCHA.
/// This function defines a global JavaScript callback 'recaptchaOnLoad'
/// which is triggered when the reCAPTCHA script from Google has fully loaded.
void initializeRecaptchaV3() {
  if (kIsWeb) {
    // Check if grecaptcha is already defined, means script already loaded
    if (js.context.hasProperty('grecaptcha')) {
      if (!_recaptchaLoadedCompleter.isCompleted) {
        _recaptchaLoadedCompleter.complete();
      }
      return;
    }

    // Define a global callback function that reCAPTCHA API calls once loaded.
    // This 'recaptchaOnLoad' function must be specified in your index.html script tag's 'onload' attribute.
    js.context['recaptchaOnLoad'] = () {
      if (!_recaptchaLoadedCompleter.isCompleted) {
        _recaptchaLoadedCompleter.complete();
        debugPrint('reCAPTCHA v3 API loaded and ready.');
      }
    };
  } else {
    // For non-web platforms, immediately complete the completer
    // as reCAPTCHA v3 is only for web.
    if (!_recaptchaLoadedCompleter.isCompleted) {
      _recaptchaLoadedCompleter.complete();
    }
  }
}

/// Gets a reCAPTCHA v3 token for a given action.
/// Waits until the reCAPTCHA API is loaded before executing.
/// This is the primary function to call from your Flutter widgets.
Future<String> getRecaptchaToken(String siteKey, String action) async {
  if (kIsWeb) {
    // Ensure reCAPTCHA API is loaded before trying to execute
    if (!_recaptchaLoadedCompleter.isCompleted) {
      debugPrint('Waiting for reCAPTCHA v3 API to load before getting token...');
      await _recaptchaLoadedCompleter.future; // Wait until grecaptcha is ready
    }

    // Capture the result of the grecaptcha.execute call
    final Completer<String> completer = Completer<String>();

    // Define a unique JS callback function to receive the token.
    // This avoids conflicts if multiple token requests are made quickly.
    String callbackName = 'recaptchaExecuteCallback_${DateTime.now().microsecondsSinceEpoch}';
    js.context[callbackName] = (String token) {
      if (!completer.isCompleted) {
        completer.complete(token);
        // Clean up the global callback to avoid memory leaks
        js.context.deleteProperty(callbackName);
      }
    };

    try {
      // Execute reCAPTCHA v3.
      // The grecaptcha.execute function returns a Promise in JS,
      // but we handle it via a callback for Dart interop.
      js.context.callMethod('grecaptcha', [
        'execute',
        siteKey,
        js.JsObject.jsify({'action': action, 'callback': callbackName}) // Pass callback
      ]);

      // Return the token via the completer's future
      return completer.future;

    } catch (e) {
      debugPrint('Error executing reCAPTCHA: $e');
      throw Exception('reCAPTCHA token generation failed: $e'); // Re-throw a more specific exception
    }
  }
  // For non-web platforms, return an empty string or null, or throw an error
  // depending on how you want to handle it.
  return '';
}
