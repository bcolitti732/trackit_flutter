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
    packets: [], // Inicializamos con una lista vacía
    isProfileComplete: false, // Agregar este campo
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
        packets: [], // Los nuevos usuarios no tienen paquetes inicialmente
        isProfileComplete: false, // Establecer como incompleto al crear
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
      id: currentUser.id, // Mantenemos el ID actual
      name: nom,
      email: email,
      password: currentUser.password, // Mantenemos la contraseña actual
      phone: phone,
      birthdate: currentUser.birthdate, // Mantenemos la fecha de nacimiento actual
      packets: currentUser.packets, // Mantenemos los paquetes actuales
      isProfileComplete: currentUser.isProfileComplete, // Mantener el estado actual
    );

    try {
      final updatedUser = await UserService.modificaUser(nouUsuari);
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

  Future<bool> eliminarUsuariPerId(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await UserService.deleteUser(id);
      if (success) {
        _users.removeWhere((user) => user.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> canviarContrasenya(String password) async {
    _setLoading(true);
    _setError(null);

    final newUser = User(
      id: currentUser.id,
      name: currentUser.name,
      email: currentUser.email,
      password: password,
      phone: currentUser.phone,
      birthdate: currentUser.birthdate,
      packets: currentUser.packets, // Mantenemos los paquetes actuales
      isProfileComplete: currentUser.isProfileComplete, // Mantener el estado actual
    );

    try {
      final user = await UserService.modificaUser(newUser);

      if (user != null) {
        setCurrentUser(user);
        return true;
      } else {
        _setError('Error cambiando contraseña: Usuario no encontrado');
        return false;
      }
    } catch (e) {
      _setError('Error cambiando contraseña: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
