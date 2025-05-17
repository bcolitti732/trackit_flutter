import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/message_service.dart';

class MessagesProvider with ChangeNotifier {
  List<Message> _messages = [];
  List<User> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  List<User> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchContacts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _contacts = await MessageService.fetchContacts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String user1Id, String user2Id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await MessageService.fetchMessages(user1Id, user2Id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> acknowledgeMessage(String messageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedMessage = await MessageService.acknowledgeMessage(messageId);
      final index = _messages.indexWhere((msg) => msg.created == updatedMessage.created);
      if (index != -1) {
        _messages[index] = updatedMessage;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}