import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final String groupId; // Empty if one-on-one chat
  final String receiverId; // Receiver ID for one-on-one chat
  final String receiverName; // Receiver's name for display

  const ChatScreen(
      {super.key, required this.groupId,
      required this.receiverId,
      required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {
    socket = IO.io('https://your-backend-url', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to socket server');

      if (widget.groupId.isNotEmpty) {
        // Join the group chat room
        socket.emit('joinGroup', {'groupId': widget.groupId});
      } else {
        // For direct message, join the private chat room
        socket.emit('joinDirectChat', {'receiverId': widget.receiverId});
      }
    });

    socket.on('receiveMessage', (message) {
      setState(() {
        messages.add(message['content']);
      });
    });

    socket.on('disconnect', (_) => print('Disconnected'));
  }

  void sendMessage(String content) {
    final token = Provider.of<TokenProvider>(context).token;

    // Initialize userId and userName
    String currentUserId = '';

    // Decode token and extract user details if token is not null
    if (token != null) {
      try {
        final jwt = JWT.decode(token);
        currentUserId = jwt.payload['user']['id'] ?? '';
      } catch (e) {
        print('Error decoding token: $e');
      }
    }
    final message = {
      'groupId': widget.groupId,
      'content': content,
      'sender': currentUserId,
      'receiverId': widget.receiverId,
    };
    socket.emit(widget.groupId.isNotEmpty ? 'sendMessage' : 'sendDirectMessage',
        message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.groupId.isNotEmpty ? 'Group Chat' : widget.receiverName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(messages[index]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: sendMessage,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    sendMessage('Hello');
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
    socket.dispose();
    super.dispose();
  }
}
