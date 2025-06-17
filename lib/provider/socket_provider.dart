// provider/socket_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketProvider with ChangeNotifier {
  late IO.Socket _socket;

  IO.Socket get socket => _socket;

  Future<void> connect() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'flutter.accessToken');

  _socket = IO.io('http://192.168.1.44:4005', <String, dynamic>{
    'transports': <String>['websocket'],
    'autoConnect': false,
    'auth': {
      'token': token,
    },
  });

  _socket.onConnect((_) {
    print('🟢 Conectado');
    notifyListeners();
  });

  _socket.onDisconnect((_) {
    print('🔴 Desconectado');
    notifyListeners();
    print('Intentando reconectar...');
    _socket.connect(); // Reconecta automáticamente
  });

  _socket.onConnectError((data) {
    print('❌ Connect error: $data');
  });

  _socket.onError((data) {
    print('❗ Socket error: $data');
  });

  print('🔌 Intentando conectar socket...');
  _socket.connect(); // <--- ¡ESTO ES LO QUE TE FALTABA!
}

  void disconnect() {
    _socket.disconnect();
  }

  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }

  void emitVacio(String event) {
    _socket.emit(event);
  }

  void on(String event, Function(dynamic) handler) {
    _socket.on(event, handler);
  }

  void off(String event) {
    _socket.off(event);
  }
}
