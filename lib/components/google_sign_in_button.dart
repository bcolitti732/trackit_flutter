import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInButton extends StatefulWidget {
  final Function(String idToken) onSignInSuccess;
  final Function(String error) onSignInError;

  const GoogleSignInButton({
    super.key,
    required this.onSignInSuccess,
    required this.onSignInError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
 final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: '517367796264-iet14ll00r610n659l2vonr6auk9sauu.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final idToken = auth.idToken;

        if (idToken != null) {
          widget.onSignInSuccess(idToken);
        } else {
          widget.onSignInError('No se recibió el ID token.');
        }
      } else {
        widget.onSignInError('Inicio de sesión cancelado.');
      }
    } catch (error) {
      widget.onSignInError('Error al iniciar sesión con Google: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: Image.asset(
        'lib/images/google.png',
        height: 24,
        width: 24,
      ),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}