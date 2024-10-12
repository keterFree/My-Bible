import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/constants.dart';

abstract class BaseMessageScreen extends StatefulWidget {
  final String title;

  const BaseMessageScreen({super.key, required this.title});
}

abstract class _BaseMessageScreenState<T extends BaseMessageScreen>
    extends State<T> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = [];
  String userId = '';
  String userName = 'Anonymous';

  @override
  void initState() {
    super.initState();
    initializeSocketConnection();
    decodeUserFromToken();
  }

  void initializeSocketConnection();

  void decodeUserFromToken() {
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
      });
    } catch (e) {
      print('Error decoding token: $e');
    }
  }

  void sendMessage(String messageContent);

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
          borderRadius: BorderRadius.circular(12),
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
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute}';
  }

  Widget buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                sendMessage(_messageController.text);
                _messageController.clear(); // Clear the input field
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController
        .dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }
}

class GroupMessageScreen extends BaseMessageScreen {
  final dynamic group;

  GroupMessageScreen({super.key, required this.group})
      : super(title: group['name']);

  @override
  _GroupMessageScreenState createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState
    extends _BaseMessageScreenState<GroupMessageScreen> {
  @override
  void initializeSocketConnection() {
    socket = IO.io(ApiConstants.authbaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to socket server');
      socket.emit('joinGroup', {
        'groupId': widget.group['groupId'],
        'userId': userId,
      });
    });

    socket.on('receiveGroupMessage', (data) {
      setState(() {
        messages.add(data);
      });
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  @override
  void sendMessage(String messageContent) {
    final newMessage = {
      'content': messageContent,
      'sender': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket.emit('sendGroupMessage', {
      'groupId': widget.group['groupId'],
      'message': newMessage,
      'userId': userId,
    });

    setState(() {
      messages.add(newMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
          buildMessageInput(),
        ],
      ),
    );
  }
}

class DirectMessageScreen extends BaseMessageScreen {
  final dynamic user;
  final Map directMessage;

  DirectMessageScreen({
    super.key,
    required this.user,
    required this.directMessage,
  }) : super(title: user['name']);

  @override
  _DirectMessageScreenState createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState
    extends _BaseMessageScreenState<DirectMessageScreen> {
  @override
  void initializeSocketConnection() {
    socket = IO.io(ApiConstants.authbaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to socket server');
      socket.emit('joinRoom', {
        'directMessage': widget.directMessage['directMessageId'],
      });
    });

    socket.on('receiveDirectMessage', (data) {
      if (data['sender'] != userId) {
        setState(() {
          messages.add(data);
        });
      }
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  @override
  void sendMessage(String messageContent) {
    final newMessage = {
      'content': messageContent,
      'sender': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket.emit('sendDirectMessage', {
      'directMessageId': widget.directMessage['directMessageId'],
      'message': newMessage,
    });

    setState(() {
      messages.add(newMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
          buildMessageInput(),
        ],
      ),
    );
  }
}
