import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/message.dart';

class MessageService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/Messages';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/Messages';
    } else {
      return 'http://localhost:4000/api/Messages';
    }
  }

  // Fetch contacts for a user
  static Future<List<User>> fetchContacts(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/contacts/$userId');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener contactos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener contactos: $e');
    }
  }

  // Fetch messages between two users
  static Future<List<Message>> fetchMessages(String user1Id, String user2Id) async {
    try {
      final url = Uri.parse('$baseUrl/$user1Id/$user2Id');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mensajes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  // Acknowledge (update) a message by its ID
  static Future<Message> acknowledgeMessage(String messageId) async {
    try {
      final url = Uri.parse('$baseUrl/Messages/$messageId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messageId': messageId}),
      );

      if (response.statusCode == 200) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar mensaje: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar mensaje: $e');
    }
  }
}
