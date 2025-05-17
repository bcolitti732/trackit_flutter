import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seminari_flutter/models/user.dart';
import 'package:seminari_flutter/services/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final DioClient dioClient;

  AuthService(this.dioClient);

  bool isLoggedIn = false; 
  static String? accessToken;
  static String? refreshToken;

  void saveTokens(String access, String refresh) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'flutter.accessToken', value: access);
    await storage.write(key: 'flutter.refreshToken', value: refresh);
    print('Tokens guardados correctamente');
  }

  void clearTokens() {
    accessToken = null;
    refreshToken = null;
  }

  static String get _baseUrl {
    const localUrl = 'http://localhost:4000/api/auth';
    const androidUrl = 'http://10.0.2.2:4000/api/auth';

    if (kIsWeb) {
      return localUrl;
    }
    return Platform.isAndroid ? androidUrl : localUrl;
  }

  Future<void> refreshTokenIfNeeded() async {
    if (refreshToken == null) return;

    final url = Uri.parse('$_baseUrl/refresh');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        saveTokens(data['accessToken'], data['refreshToken']);
      } else {
        print('Failed to refresh token: ${response.body}');
      }
    } catch (e) {
      print('Error refreshing token: $e');
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
        final data = json.decode(response.body);

        // Guarda los tokens
        saveTokens(data['accessToken'], data['refreshToken']);
        isLoggedIn = true; // Cambia el estado de inicio de sesión

        // Devuelve el estado de perfil completo
        return {
          'isProfileComplete': data['isProfileComplete'],
        };
      } else {
        print('Error en la respuesta del servidor: ${response.body}');
        return {'error': 'Email o contraseña incorrectos'};
      }
    } catch (e) {
      print('Error de conexión: $e');
      return {'error': 'Error de conexión'};
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

  Future<Map<String, dynamic>> completeProfile({
    required String phone,
    required String birthdate,
    required String password,
  }) async {
    final body = {
      'phone': phone,
      'birthdate': birthdate,
      'password': password,
    };

    try {
      // Usa la instancia compartida de DioClient
      final response = await dioClient.dio.put(
        '/auth/complete-profile',
        data: body,
      );

      if (response.statusCode == 200) {
        final data = response.data; // `response.data` ya es un objeto JSON

        // Guarda los nuevos tokens si el backend los devuelve
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          saveTokens(data['accessToken'], data['refreshToken']);
        }

        return data; // Devuelve los datos del usuario actualizado
      } else {
        return {
          'error': response.data['message'] ?? 'Error al completar el perfil',
        };
      }
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  void logout() async {
    isLoggedIn = false;
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'flutter.accessToken');
    await storage.delete(key: 'flutter.refreshToken');
    print('Tokens eliminados. Usuario desconectado.');
  }
}
