import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

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
    print('URL de la solicitud: $url');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('Estado de la respuesta: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Datos decodificados: $data');

      final List<dynamic> usersJson = data['data'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      print('Error al obtener usuarios: ${response.body}');
      throw Exception('Error al obtener usuarios');
    }
  } catch (e) {
    print('Excepción al obtener usuarios: $e');
    throw Exception('Error al obtener usuarios: $e');
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
      throw Exception('Error al crear usuari: ${response.statusCode}');
    }
  }

  static Future<User> getUserById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error a l'obtenir usuari: ${response.statusCode}");
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
      throw Exception('Error actualitzant usuari: ${response.statusCode}');
    }
  }

  static Future<bool> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error eliminant usuari: ${response.statusCode}');
    }
  }

  static Future<User?> modificaUser(User user) async {
  print('Enviando datos al backend para modificar usuario: ${user.toJson()}');
  try {
    // Construir el cuerpo de la solicitud
    final body = {
      "_id": user.id,
      "name": user.name,
      "email": user.email,
      "password": user.password,
      "phone": user.phone,
      "birthdate": DateFormat('yyyy-MM-dd').format(DateTime.parse(user.birthdate)),
    };

    print('Cuerpo de la solicitud: $body');

    // Realizar la solicitud HTTP PUT
    final response = await http.put(
      Uri.parse('$baseUrl/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('Estado de la respuesta: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    // Verificar el estado de la respuesta
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Datos recibidos del backend: $data');
      return User.fromJson(data);
    } else {
      print('Error del backend: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Excepción al modificar usuario: $e');
    throw Exception('Error al modificar usuario: $e');
  }
}

}