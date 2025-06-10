import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/UserService.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  User currentUser = User(
    id: null,
    name: '',
    email: '',
    password: '',
    phone: '',
    birthdate: '',
    packetsIds: [],
    isProfileComplete: false,
    role: 'user',
    deliveryProfile: null,
  );

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void setCurrentUser(User user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _setLoading(true);
    _setError(null);

    try {
      _users = await UserService.getUsers();
    } catch (e) {
      _setError('Error loading users: $e');
      _users = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> crearUsuari(
    String nom,
    String email,
    String password,
    String phone,
    String birthdate,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final nouUsuari = User(
        name: nom,
        email: email,
        password: password,
        phone: phone,
        birthdate: birthdate,
        packetsIds: [],
        isProfileComplete: false,
        role: 'user',
        deliveryProfile: null,
      );
      final createdUser = await UserService.createUser(nouUsuari);
      _users.add(createdUser);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error creating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> modificarUsuari(
    String nom,
    String email,
    String phone,
  ) async {
    if (currentUser.id == null || currentUser.id!.isEmpty) {
      _setError('Error: El ID del usuario es nulo o vacío');
      return false;
    }

    _setLoading(true);
    _setError(null);

    final nouUsuari = User(
      id: currentUser.id,
      name: nom,
      email: email,
      password: currentUser.password,
      phone: phone,
      birthdate: currentUser.birthdate,
      packetsIds: currentUser.packetsIds,
      isProfileComplete: currentUser.isProfileComplete,
      role: currentUser.role,
      deliveryProfile: currentUser.deliveryProfile, 
    );

    try {
      final updatedUser = await UserService.updateUser(currentUser.id!, nouUsuari);
      if (updatedUser != null) {
        setCurrentUser(updatedUser);
        return true;
      } else {
        _setError('Error: El servicio devolvió un usuario nulo');
        return false;
      }
    } catch (e) {
      _setError('Error modificando el usuario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}