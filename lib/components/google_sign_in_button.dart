import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:fastor_app_ui_widget/fastor_app_ui_widget.dart' if (dart.library.html) 'dart:ui' as ui;

class GoogleSignInButton extends StatefulWidget {
  final Function(String idToken) onSignInSuccess;
  final Function(String error) onSignInError;

  const GoogleSignInButton({
    Key? key,
    required this.onSignInSuccess,
    required this.onSignInError,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('dart.library.html', defaultValue: false)) {
      _initializeGoogleSignInButton();
    }
  }

  void _initializeGoogleSignInButton() {
    ui.platformViewRegistry.registerViewFactory(
      'google-signin-container',
      (int viewId) {
        final div = html.DivElement()
          ..id = 'google-signin-container'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none';

        final google = js.context['google'];
        if (google != null) {
          google['accounts']['id'].callMethod('initialize', [js.JsObject.jsify({
            'client_id': '517367796264-iet14ll00r610n659l2vonr6auk9sauu.apps.googleusercontent.com',
            'callback': js.allowInterop(_handleCredentialResponse),
          })]);

          google['accounts']['id'].callMethod('renderButton', [
            div,
            js.JsObject.jsify({
              'theme': 'outline',
              'size': 'large',
            }),
          ]);
        }
        return div;
      },
    );
  }

  void _handleCredentialResponse(dynamic response) {
    final credential = response['credential'];
    if (credential != null) {
      widget.onSignInSuccess(credential);
    } else {
      widget.onSignInError('No se recibió el ID token.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!const bool.fromEnvironment('dart.library.html', defaultValue: false)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 300,
      height: 60,
      child: HtmlElementView(viewType: 'google-signin-container'),
    );
  }
}