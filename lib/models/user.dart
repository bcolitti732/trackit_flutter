import 'package:intl/intl.dart';

class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String birthdate;
  final bool isProfileComplete;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthdate,
    required this.isProfileComplete,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String formattedDate = '';
    if (json['birthdate'] != null) {
      final date = DateTime.parse(json['birthdate']);
      formattedDate = DateFormat('yyyy-MM-dd').format(date);
    }

    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      birthdate: formattedDate,
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
      'isProfileComplete': isProfileComplete,
      if (includePassword) 'password': password,
    };
  }
}