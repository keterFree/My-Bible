import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GroupMessageScreen extends StatefulWidget {
  final dynamic group;

  const GroupMessageScreen({super.key, required this.group});

  @override
  _GroupMessageScreenState createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = []; // To store group messages locally
  String userId = '';
  String userName = 'Anonymous';
  String userContacts = '';

  @override
  void initState() {
    super.initState();
    initializeSocketConnection();
  }

  void initializeSocketConnection() {
    socket = IO.io(ApiConstants.authbaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
      // Join the group room
      socket.emit('joinGroup', {
        'groupId': widget.group['groupId'],
        'userId': userId,
      });
    });

    socket.on('receiveGroupMessage', (data) {
      setState(() {
        messages.add(data); // Add the received message to the list
      });
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;
    final newMessage = {
      'content': message,
      'sender': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket.emit('sendGroupMessage', {
      'groupId': widget.group['groupId'],
      'message': newMessage,
      'userId': userId,
    });

    _messageController.clear();
    setState(() {
      messages.add(newMessage);
    });
  }

  Widget buildMessageBubble(dynamic message) {
    bool isCurrentUser = message['sender'] == userId;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isCurrentUser ? 12 : 0),
            topRight: Radius.circular(isCurrentUser ? 0 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              formatTimestamp(message['timestamp']),
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      print("Token not found or expired");
    }

    try {
      final jwt = JWT.decode(token!);
      setState(() {
        userId = jwt.payload['user']['id'] ?? 'empty';
        userName = jwt.payload['user']['name'] ?? 'Anonymous';
        userContacts = jwt.payload['user']['phone'] ?? '';
      });
    } catch (e) {
      print('Error decoding token: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group['name']),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return buildMessageBubble(message);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      sendMessage(_messageController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
