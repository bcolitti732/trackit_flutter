import 'package:intl/intl.dart';

class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String birthdate;
  final List<String> packetsIds; // Lista de identificadores de paquetes
  final bool isProfileComplete;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthdate,
    required this.packetsIds,
    required this.isProfileComplete,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String formattedDate = '';
    if (json['birthdate'] != null) {
      final date = DateTime.parse(json['birthdate']);
      formattedDate = DateFormat('yyyy-MM-dd').format(date);
    }

    return User(
      id: json['_id'], // Asegúrate de que el backend devuelve `_id`
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      birthdate: formattedDate,
      packetsIds: List<String>.from(json['packets'] ?? []), // Mapea los identificadores de paquetes
      isProfileComplete: json['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false, bool includeId = false}) {
    return {
      if (includeId && id != null) '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'birthdate': birthdate,
      if (includePassword) 'password': password, // Solo incluir la contraseña si se solicita
      'packets': packetsIds, // Devuelve solo los identificadores de paquetes
      'isProfileComplete': isProfileComplete,
    };
  }
}