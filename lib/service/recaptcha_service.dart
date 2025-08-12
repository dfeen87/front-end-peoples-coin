import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:js' as js; // For web-only JS calls

class RecaptchaService {
  final BuildContext context;
  final String siteKey;
  final String verifyUrl;

  /// Use your Enterprise site key and backend verification endpoint here
  RecaptchaService(
    this.context, {
    required this.siteKey,
    required this.verifyUrl,
  });

  Future<String> execute({String action = 'submit'}) async {
    if (_isWeb()) {
      return _executeWeb(action);
    } else {
      return _executeMobile(action);
    }
  }

  bool _isWeb() {
    try {
      return js.context.hasProperty('window');
    } catch (_) {
      return false;
    }
  }

  /// Calls the JS function which uses grecaptcha.enterprise.execute internally
  Future<String> _executeWeb(String action) async {
    final completer = Completer<String>();

    try {
      // Clear old callback if any
      js.context['onRecaptchaSuccess'] = null;

      // Setup callback to complete the Dart Future when token arrives
      js.context['onRecaptchaSuccess'] = (String token) {
        if (!completer.isCompleted) completer.complete(token);
      };

      // Call the JS method from index.html
      js.context.callMethod('runRecaptcha', [action]);
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future;
  }

  /// On mobile/native platforms, call your backend to get the token (which calls the Enterprise API server-side)
  Future<String> _executeMobile(String action) async {
    try {
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] ?? '';
      } else {
        throw Exception('reCAPTCHA failed: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

