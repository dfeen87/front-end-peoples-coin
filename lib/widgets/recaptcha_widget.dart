// lib/widgets/recaptcha_widget.dart
import 'dart:html';
import 'dart:ui_web' as ui; // CORRECTED IMPORT
import 'package:flutter/material.dart';

class RecaptchaV2Widget extends StatelessWidget {
  const RecaptchaV2Widget({super.key});

  @override
  Widget build(BuildContext context) {
    const String viewId = 'recaptcha-v2-view';

    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final div = DivElement()
        ..id = viewId.toString()
        ..className = 'g-recaptcha'
        ..dataset['sitekey'] = '6LcwyYUrAAAAAE2Bv6bXHjq23zTBE49ABYmi4ccs';
        
      return div;
    });

    return SizedBox(
      width: 304,
      height: 78,
      child: HtmlElementView(viewType: viewId),
    );
  }
}
