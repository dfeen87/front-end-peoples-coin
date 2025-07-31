// lib/config.dart

/// Your reCAPTCHA site key, loaded from build-time environment variable.
/// If not defined at build time, defaults to your provided key.
const String recaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY_PROD',
  defaultValue: '6LeE0pQrAAAAAML8x8JqtfryKhZ9bpvLRacQzH1F',
);

