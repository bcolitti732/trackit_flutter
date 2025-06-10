import 'package:intl/intl.dart';

class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String birthdate;
  final List<String> packetsIds;
  final bool isProfileComplete;
  final String role;
  final Map<String, dynamic>? deliveryProfile;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthdate,
    required this.packetsIds,
    required this.isProfileComplete,
    required this.role,
    this.deliveryProfile,
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
      packetsIds: List<String>.from(json['packets'] ?? []),
      isProfileComplete: json['isProfileComplete'] ?? false,
      role: json['role'] ?? 'user',
      deliveryProfile: json['deliveryProfile'],
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false, bool includeId = false}) {
    return {
      if (includeId && id != null) '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'birthdate': birthdate,
      if (includePassword) 'password': password,
      'packets': packetsIds,
      'isProfileComplete': isProfileComplete,
      'role': role,
      if (deliveryProfile != null) 'deliveryProfile': deliveryProfile,
    };
  }
}