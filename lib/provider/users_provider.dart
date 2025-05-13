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
      );
      final createdUser = await UserService.createUser(nouUsuari);
      _users.add(createdUser);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error creating user: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> modificarUsuari(String nom, String email, String phone) async {
    if (currentUser.id == null || currentUser.id!.isEmpty) {
      _setError('Error: El ID del usuario es nulo o vacío');
      return false;
    }

    _setLoading(true);
    _setError(null);

    // Creamos un nuevo usuario con los campos que se pueden modificar
    final nouUsuari = User(
      id: currentUser.id, // Mantenemos el ID actual
      name: nom,
      email: email,
      password: currentUser.password, // Mantenemos la contraseña actual
      phone: phone,
      birthdate:
          currentUser.birthdate, // Mantenemos la fecha de nacimiento actual
      packets: currentUser.packets, // Mantenemos los paquetes actuales
    );

    print(
      'Usuario a enviar al backend: ${nouUsuari.toJson(includeId: true, includePassword: true)}',
    );

    try {
      print(
        'Usuario a enviar al backend: ${nouUsuari.toJson(includeId: true, includePassword: true)}',
      );
      final updatedUser = await UserService.modificaUser(nouUsuari);
      if (updatedUser != null) {
        setCurrentUser(updatedUser);
        print('User updated successfully in provider: ${updatedUser.toJson()}');
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Error: El servicio devolvió un usuario nulo');
        print('Error: El servicio devolvió un usuario nulo');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error modificando el usuario: $e');
      print('Error modificando el usuario: $e');
      _setLoading(false);
      return false;
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
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error deleting user: $e');
      _setLoading(false);
      return false;
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
    );

    try {
      final user = await UserService.modificaUser(newUser);

      if (user != null) {
        currentUser = user;
        notifyListeners();
        return true;
      } else {
        _setError('Error canviant contrasenya: Usuari no trobat');
        return false;
      }
    } catch (e) {
      _setError('Error canviant contrasenya: $e');
      _setLoading(false);
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
