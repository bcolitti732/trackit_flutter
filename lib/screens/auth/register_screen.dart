import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:seminari_flutter/components/my_textfield.dart';
import 'package:seminari_flutter/components/my_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final birthdateController = TextEditingController();

  final String baseUrl = 'http://localhost:4000/api/auth/register';

  void registerUser(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final name = nameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final phone = phoneController.text;
    final birthdate = birthdateController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty || birthdate.isEmpty) {
      _showError(context, loc.allFieldsRequired);
      return;
    }

    if (password.length < 6) {
      _showError(context, loc.passwordMinLength);
      return;
    }

    if (!email.contains('@')) {
      _showError(context, loc.invalidEmail);
      return;
    }

    if (!_isValidDateFormat(birthdate)) {
      _showError(context, loc.invalidDateFormat);
      return;
    }

    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'birthdate': birthdate,
    });

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.userRegistered)),
        );
        context.go('/login');
      } else {
        final error = jsonDecode(response.body)['message'] ?? loc.unknownError;
        _showError(context, error);
      }
    } catch (e) {
      _showError(context, loc.connectionError);
    }
  }

  bool _isValidDateFormat(String date) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(date)) return false;
    try {
      final parsedDate = DateTime.parse(date);
      return parsedDate.year > 1900;
    } catch (e) {
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthdateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                  ),
                  child: Text(
                    loc.register,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(context, nameController, loc.name),
                const SizedBox(height: 10),
                _buildTextField(context, emailController, loc.email),
                const SizedBox(height: 10),
                _buildTextField(context, passwordController, loc.password, obscureText: true),
                const SizedBox(height: 10),
                _buildTextField(context, phoneController, loc.phone),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(context, birthdateController, loc.dateOfBirthHint),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: MyButton(
                    text: loc.register,
                    onTap: () => registerUser(context),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.alreadyHaveAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          loc.signIn,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String hintText, {bool obscureText = false}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: MyTextfield(
        controller: controller,
        hintText: hintText,
        obscureText: obscureText,
      ),
    );
  }
}
