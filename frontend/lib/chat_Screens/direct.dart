import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DirectMessageScreen extends StatefulWidget {
  final dynamic user;
  final Map directMessage;

  const DirectMessageScreen(
      {super.key, required this.user, required this.directMessage});

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
    // Populate initial messages from widget
    messages = widget.directMessage['messages'];
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
      socket.emit('joinRoom',
          {'directMessage': widget.directMessage['directMessageId']});
    });

    // Listen for messages from the server
    socket.on('receiveDirectMessage', (data) {
      print('Message received: $data');
      // Only add the message if it's from another user
      if (data['sender'] != userId) {
        setState(() {
          messages.add(data); // Add new message to the list
        });
      }
    });

    // Handle disconnection
    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;
    final newMessage = {
      'content': message,
      'sender': userId, // Replace with actual sender ID if available
      'timestamp': DateTime.now().toIso8601String(), // Add a timestamp locally
    };

    // Send a direct message to the server
    socket.emit('sendDirectMessage', {
      'directMessageId': widget.directMessage[
          "directMessageId"], // Use the directMessage from the widget
      'message': newMessage,
    });

    // Clear the message input field
    _messageController.clear();

    // Add the sent message to the list locally
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
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formatTimestamp(message['timestamp']),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('h:mm a').format(dateTime); // E.g., 3:45 PM
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
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    String backgroundImage =
        isDarkMode ? 'assets/images/pdark.jpeg' : 'assets/images/plight.jpg';
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  isDarkMode ? BlendMode.darken : BlendMode.lighten,
                ),
                alignment: Alignment.topLeft),
          ),
        ),
        Scaffold(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).appBarTheme.backgroundColor!.withOpacity(0.8),
            title: Text(widget.user['name']),
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
        ),
      ],
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
