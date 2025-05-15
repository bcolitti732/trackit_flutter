import 'dart:convert';
import 'dart:async';
import 'dart:html' as html; // Importa para usar el DOM en Flutter Web
import 'dart:js' as js; // Importa dart:js para usar context.callMethod
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seminari_flutter/models/user.dart';
import 'package:provider/provider.dart';

import 'package:seminari_flutter/components/my_textfield.dart';
import 'package:seminari_flutter/components/my_button.dart';
import 'package:seminari_flutter/components/google_sign_in_button.dart';
import 'package:seminari_flutter/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeGoogleSignInButton();
    }
  }

  void _initializeGoogleSignInButton() {
    // Carga el script de Google si no está ya cargado
    if (html.document.getElementById('gsi-client') == null) {
      final script = html.ScriptElement()
        ..id = 'gsi-client'
        ..src = 'https://accounts.google.com/gsi/client'
        ..async = true
        ..defer = true;
      html.document.head?.append(script);

      script.onLoad.listen((event) {
        _renderGoogleButton();
      });
    } else {
      _renderGoogleButton();
    }
  }

  void _renderGoogleButton() {
    final google = js.context['google'];
    if (google != null) {
      google['accounts']['id'].callMethod('initialize', [js.JsObject.jsify({
        'client_id': '517367796264-iet14ll00r610n659l2vonr6auk9sauu.apps.googleusercontent.com',
        'callback': js.allowInterop(_handleCredentialResponse),
      })]);

      // Encuentra el contenedor donde se insertará el botón
      final buttonContainer = html.document.getElementById('google-signin-container');
      if (buttonContainer != null) {
        buttonContainer.children.clear(); // Limpia el contenedor antes de renderizar
        google['accounts']['id'].callMethod('renderButton', [
          buttonContainer,
          js.JsObject.jsify({
            'theme': 'outline',
            'size': 'large',
          }),
        ]);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 200), _renderGoogleButton);
    }
  }

  void _handleCredentialResponse(dynamic response) {
    if (!mounted) return; // Verifica si el widget está montado

    final credential = response['credential'];
    if (credential != null) {
      print('ID Token recibido: $credential');
      _sendIdTokenToBackend(credential);
    } else {
      print('Error: No se recibió el ID token.');
    }
  }

  Future<void> _sendIdTokenToBackend(String idToken) async {
    if (!mounted) return; // Verifica si el widget está montado

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/auth/google/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Usa AuthService para guardar los tokens
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.saveTokens(data['accessToken'], data['refreshToken']);

        final isProfileComplete = data['user']['isProfileComplete'] ?? false;

        if (mounted) {
          if (isProfileComplete) {
            print('Perfil completo. Redirigiendo a /');
            context.go('/'); // Redirige a la pantalla principal
          } else {
            print('Perfil incompleto. Redirigiendo a /complete-profile');
            context.go('/complete-profile'); // Redirige a completar perfil
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Error en el backend: ${response.body}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al enviar el ID token al backend: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email y contraseña no pueden estar vacíos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final result = await authService.login(email, password);

      if (result.containsKey('error')) {
        _showError(result['error']);
      } else {
        final isProfileComplete = result['isProfileComplete'] as bool;

        if (mounted) {
          if (isProfileComplete) {
            print('Perfil completo. Redirigiendo a /');
            context.go('/'); // Redirige a la pantalla principal
          } else {
            print('Perfil incompleto. Redirigiendo a /complete-profile');
            context.go('/complete-profile'); // Redirige a completar perfil
          }
        }
      }
    } catch (e) {
      _showError('Error de conexión');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('lib/images/image.png', height: 100),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome back, we missed you!',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please log in to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        MyTextfield(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                        ),
                        const SizedBox(height: 16),
                        MyTextfield(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot your password?',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        MyButton(
                          text: 'Login',
                          onTap: _handleLogin,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Not a member?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 4),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.go('/register'),
                                child: Text(
                                  'Register',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text('Or continue with'),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 16),
                        GoogleSignInButton(
                          onSignInSuccess: (idToken) => _sendIdTokenToBackend(idToken),
                          onSignInError: (error) {
                            setState(() {
                              _errorMessage = error;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}