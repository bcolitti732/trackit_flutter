import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:seminari_flutter/components/my_textfield.dart';
import 'package:seminari_flutter/components/my_button.dart';
import 'package:seminari_flutter/components/square_title.dart';
import 'package:seminari_flutter/services/auth_service.dart';
import 'package:seminari_flutter/provider/users_provider.dart';
import 'package:seminari_flutter/models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final String baseUrl = 'http://localhost:4000/api/auth/login';

  void signUserIn(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, localizations.emptyFields);
      return;
    }

    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userData = data['user'];

        AuthService().saveTokens(accessToken, refreshToken);

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setCurrentUser(User.fromJson(userData));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.loginSuccess)),
        );

        context.go('/');
      } else {
        final error = jsonDecode(response.body)['message'] ?? localizations.invalidCredentials;
        _showError(context, error);
      }
    } catch (e) {
      _showError(context, localizations.connectionError);
    }
  }

  void _showError(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

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
                          localizations.welcomeBack,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.pleaseLogin,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        MyTextfield(
                          controller: emailController,
                          hintText: localizations.email,
                          obscureText: false,
                        ),
                        const SizedBox(height: 16),
                        MyTextfield(
                          controller: passwordController,
                          hintText: localizations.password,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        MyButton(
                          text: localizations.login,
                          onTap: () => signUserIn(context),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(localizations.notMember, style: theme.textTheme.bodyMedium),
                            const SizedBox(width: 4),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.go('/register'),
                                child: Text(
                                  localizations.register,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(localizations.orContinueWith),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.googleSignInClicked)),
                            );
                          },
                          child: SquareTitle(imagePath: 'lib/images/google.png', size: 50),
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
