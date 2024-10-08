import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DirectMessageScreen extends StatefulWidget {
  final dynamic user;
  final String directMessageId;

  const DirectMessageScreen({super.key, required this.user, required this.directMessageId});

  @override
  _DirectMessageScreenState createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = []; // To store messages locally
  String userId = '';
  String userName = 'Anonymous';
  String userContacts = '';

  @override
  void initState() {
    super.initState();
    initializeSocketConnection();
  }

  void initializeSocketConnection() {
    // Initialize the socket connection
    socket = IO.io(ApiConstants.authbaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    // Listen for connection errors
    socket.onConnectError((data) {
      print('Connection error: $data');
    });

    // Listen for successful connection
    socket.onConnect((_) {
      print('Connected to socket server');
      // Join the room for the current direct message conversation
      socket.emit('joinRoom', {'directMessageId': widget.directMessageId});
    });

    // Listen for messages from the server
    socket.on('receiveDirectMessage', (data) {
      print('Message received: $data');
      setState(() {
        messages.add(data); // Add new message to the list
      });
    });

    // Handle disconnection
    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;
    Future<void> fetchUserDetails() async {
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      if (token == null) {
        print("Token not found or expired");
        return;
      }

      try {
        final jwt = JWT.decode(token);
        setState(() {
          userId = jwt.payload['user']['id'] ?? 'empty';
          userName = jwt.payload['user']['name'] ?? 'Anonymous';
          userContacts = jwt.payload['user']['phone'] ?? '';
        });
      } catch (e) {
        print('Error decoding token: $e');
      }
    }

    print("userId $userId");
    final newMessage = {
      'content': message,
      'sender': userId, // Replace with actual sender ID if available
    };

    // Send a direct message to the server
    socket.emit('sendDirectMessage', {
      'directMessageId':
          widget.directMessageId, // Use the directMessageId from the widget
      'message': newMessage,
    });

    // Clear the message input field
    _messageController.clear();

    // Update local state with the sent message
    setState(() {
      messages.add(newMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name']),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message['content'] ?? ''),
                  subtitle: Text(
                    message['sender'] == 'CurrentUserId'
                        ? 'You'
                        : widget.user['name'],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the socket connection
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
