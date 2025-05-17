import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import '../models/user.dart';
import '../provider/messages_provider.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final User currentUser;
  final User contact;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.contact,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  IO.Socket? socket;
  List<Message> messageList = [];
  String? roomId;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchMessages();
  }

  void _initSocket() {
    final token = AuthService.accessToken ?? '';
    socket = IO.io('http://localhost:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token, //oki
      },
    });
    socket?.connect();

    socket?.on('receive_message', (data) {
      setState(() {
        messageList.add(Message.fromJson(Map<String, dynamic>.from(data)));
      });
      _scrollToBottom();
    });

    socket?.on('status', (data) {
      if (data['status'] == 'unauthorized') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  Future<void> _fetchMessages() async {
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    await messagesProvider.fetchMessages(
      
      widget.currentUser.id ?? '',
      widget.contact.id ?? '',
    );
    setState(() {
      messageList = List<Message>.from(messagesProvider.messages);
      if (messageList.isNotEmpty) {
        roomId = messageList[0].roomId;
        socket?.emit('join_room', roomId);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    print(widget.contact.id);
    final msg = Message(
      senderId: widget.currentUser.id ?? '',
      rxId: widget.contact.id ?? '',
      content: _controller.text.trim(),
      created: DateTime.now(),
      acknowledged: false,
      roomId: roomId ?? '',
    );
    socket?.emit('send_message', msg.toJson());
    setState(() {
      messageList.add(msg);
      _controller.clear();
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    socket?.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('💬 ${widget.contact.name ?? ''}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                final msg = messageList[index];
                final isOwn = msg.senderId == widget.currentUser.id;
                return Align(
                  alignment:
                      isOwn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOwn ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOwn
                                  ? (widget.currentUser.name ?? '')
                                  : (widget.contact.name ?? ''),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              msg.created.hour.toString().padLeft(2, '0') +
                                  ':' +
                                  msg.created.minute.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
