import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  bool isLoggedIn = false; 
  static String? accessToken;
  static String? refreshToken;


  void saveTokens(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clearTokens() {
    accessToken = null;
    refreshToken = null;
  }

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:9000/api/users';
    } else if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:9000/api/users';
    } else {
      return 'http://localhost:9000/api/users';
    }
  }

  //login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    final body = json.encode({'email': email, 'password': password});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'email o contrasenya incorrectes'};
      }
    } catch (e) {
      return {'error': 'Error de connexió'};
    }
  }

  Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  required String phone,
  required String birthdate,
  required bool available,
}) async {
  final url = Uri.parse('$_baseUrl/register');

  final body = json.encode({
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'birthdate': birthdate,
    'available': available,
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      return {'error': 'Error al registrar l\'usuari'};
    }
  } catch (e) {
    return {'error': 'Error de connexió'};
  }
}

  void logout() {
    isLoggedIn = false; 
  }
}
