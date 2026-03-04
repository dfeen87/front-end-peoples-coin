// lib/config.dart
//
// Required build-time --dart-define:
//   --dart-define=RECAPTCHA_SITE_KEY_PROD=<your-site-key>

/// Your reCAPTCHA site key, loaded from build-time environment variable.
/// An empty value will cause the app to fail fast at runtime.
const String recaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY_PROD',
  defaultValue: '',
);

