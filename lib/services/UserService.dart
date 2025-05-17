import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../services/dio_client.dart';
import '../models/user.dart';
import '../models/packet.dart';

class UserService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/users';
    } else if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/users';
    } else {
      return 'http://localhost:4000/api/users';
    }
  }

  static Future<List<User>> getUsers({int page = 1, int limit = 10}) async {
    try {
      final url = Uri.parse('$baseUrl?page=$page&limit=$limit');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final List<dynamic> usersJson = data['data'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (e) {
      throw Exception('Error al obtener usuarios');
    }
  }

  static Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear usuario: ${response.statusCode}');
    }
  }

  static Future<User> getUserById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error al obtener usuario: ${response.statusCode}");
    }
  }

  static Future<User> updateUser(String id, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error actualizando usuario: ${response.statusCode}');
    }
  }

  static Future<bool> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error eliminando usuario: ${response.statusCode}');
    }
  }

  static Future<User> getCurrentUser() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/users/me'); // El interceptor añade el token automáticamente

      if (response.statusCode == 200) {
        final data = response.data; // `response.data` ya es un objeto JSON
        return User.fromJson(data);
      } else {
        throw Exception('Error al obtener el usuario actual: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener el usuario actual: $e');
    }
  }

  static Future<List<Packet>> getUserPackets(String userId) async {
    try {
      final dio = DioClient().dio; // Obtén la instancia de Dio configurada
      final response = await dio.get('/users/$userId/packets'); // El interceptor añade el token automáticamente

      if (response.statusCode == 200) {
        final List<dynamic> packetsJson = response.data; // `response.data` ya es un objeto JSON
        return packetsJson.map((json) => Packet.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener los paquetes del usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los paquetes del usuario: $e');
    }
  }

  static Future<Packet> getPacketById(String packetId) async {
    try {
      final dio = DioClient().dio; // Usa Dio para manejar el token automáticamente
      final response = await dio.get('/packets/$packetId');

      if (response.statusCode == 200) {
        return Packet.fromJson(response.data);
      } else {
        throw Exception('Error al obtener el paquete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener el paquete: $e');
    }
  }
}
