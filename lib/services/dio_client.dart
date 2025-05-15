import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    // Configuración base
    _dio.options.baseUrl = 'http://localhost:4000/api'; // Cambia esto por tu URL base
    _dio.options.connectTimeout = const Duration(seconds: 10); // Tiempo de espera de conexión
    _dio.options.receiveTimeout = const Duration(seconds: 10); // Tiempo de espera de respuesta

    // Agregar interceptores
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Leer el token desde FlutterSecureStorage
          final token = await _secureStorage.read(key: 'flutter.accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('Token añadido al encabezado: $token');
          } else {
            print('No se encontró el token en FlutterSecureStorage');
          }
        } catch (e) {
          print('Error al leer el token: $e');
        }

        return handler.next(options); // Continuar con la solicitud
      },
      onResponse: (response, handler) {
        // Interceptar respuestas
        print('Respuesta recibida: ${response.statusCode}');
        return handler.next(response); // Continuar con la respuesta
      },
      onError: (DioError error, handler) {
        // Manejar errores globalmente
        print('Error ocurrido: ${error.message}');
        if (error.response?.statusCode == 401) {
          // Manejo de errores de autenticación (por ejemplo, token expirado)
          print('Error 401: Token no autorizado o expirado');
        }
        return handler.next(error); // Continuar con el error
      },
    ));
  }

  Dio get dio => _dio;
}