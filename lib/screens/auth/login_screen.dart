import 'dart:convert';
import 'dart:async';
import 'dart:html' as html; // Importa para usar el DOM en Flutter Web
import 'dart:js' as js; // Importa dart:js para usar context.callMethod
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seminari_flutter/components/my_textfield.dart';
import 'package:seminari_flutter/components/my_button.dart';
import 'package:seminari_flutter/components/google_sign_in_button.dart';

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
    final credential = response['credential'];
    if (credential != null) {
      print('ID Token recibido: $credential');
      _sendIdTokenToBackend(credential);
    } else {
      print('Error: No se recibió el ID token.');
    }
  }

  Future<void> _sendIdTokenToBackend(String idToken) async {
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);
        if (mounted) {
          context.go('/');
        }
      } else {
        setState(() {
          _errorMessage = "Error en el backend: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error al enviar el ID token al backend: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showError('Email and password cannot be empty.');
    return;
  }

  final body = jsonEncode({
    'email': email,
    'password': password,
  });

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await http.post(
      Uri.parse('http://localhost:4000/api/auth/login'), // Cambia la URL si es necesario
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final userData = data['user'];

      // Guarda los tokens en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);

      // Actualiza el estado del usuario (si usas un Provider o similar)
      // final userProvider = Provider.of<UserProvider>(context, listen: false);
      // userProvider.setCurrentUser(User.fromJson(userData));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );

      if (mounted) {
        context.go('/'); // Redirige al usuario a la pantalla principal
      }
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Invalid credentials.';
      _showError(error);
    }
  } catch (e) {
    _showError('Connection error');
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