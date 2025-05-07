import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:seminari_flutter/components/my_textfield.dart';
import 'package:seminari_flutter/components/my_button.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final birthdateController = TextEditingController();

  final String baseUrl = 'http://localhost:4000/api/auth/register';

  void registerUser(BuildContext context) async {
    final name = nameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final phone = phoneController.text;
    final birthdate = birthdateController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        birthdate.isEmpty) {
      _showError(context, 'All fields are required.');
      return;
    }

    if (password.length < 6) {
      _showError(context, 'Password must be at least 6 characters long.');
      return;
    }

    if (!email.contains('@')) {
      _showError(context, 'Please enter a valid email address.');
      return;
    }

    if (!_isValidDateFormat(birthdate)) {
      _showError(context, 'Date of Birth must be in the format YYYY-MM-DD.');
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
          const SnackBar(content: Text('User registered successfully!')),
        );
        context.go('/login');
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Unknown error';
        _showError(context, error);
      }
    } catch (e) {
      _showError(context, 'Connection error');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[300] ?? Colors.grey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: MyTextfield(
                    controller: nameController,
                    hintText: 'Name',
                    obscureText: false,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: MyTextfield(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: MyTextfield(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: MyTextfield(
                    controller: phoneController,
                    hintText: 'Phone',
                    obscureText: false,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: MyTextfield(
                    controller: birthdateController,
                    hintText: 'Date of Birth (YYYY-MM-DD)',
                    obscureText: false,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: MyButton(onTap: () => registerUser(context)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
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
}