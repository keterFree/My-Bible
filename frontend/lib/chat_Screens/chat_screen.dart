import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/add_members.dart';
import 'package:frontend/chat_Screens/group_details.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
    print(message.toString());
    bool isCurrentUser = message['sender']["_id"] == userId;
    String senderName =
        isCurrentUser ? 'You' : message['sender']["name"] ?? 'Anonymous';

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
            // Display sender name in bold font
            Text(
              senderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            // Display the message content
            Text(
              message['content'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
            // Display timestamp
            Text(
              formatTimestamp(message['timestamp']),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
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

  Widget buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).cardColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
  bool isLeader = false; // Track if the user is a group leader
  bool isMember = false;

  @override
  void initState() {
    super.initState();
    initializeSocketConnection();
    checkUserRole();
    fetchPreviousMessages();
  }

  // Mock function to determine if the user is a leader or member
  void checkUserRole() {
    print("${widget.group['members'][0]} -> $userId");

    // for members in widget.group['members']

    setState(() {
      for (var leader in widget.group['leaders']) {
        if (leader["_id"] == userId) {
          isLeader = true;
          print("is Leader");
        }
      }
      for (var member in widget.group['members']) {
        if (member["_id"] == userId) {
          isMember = true;
          print("is Member");
        }
      }
    });
  }

  void fetchPreviousMessages() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    final groupId = widget.group['_id'];
    print("$groupId --> $token");
    final url =
        '${ApiConstants.groupMessages}/$groupId'; // Assuming this is the endpoint
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedMessages = jsonDecode(response.body);

        setState(() {
          messages = fetchedMessages; // Add fetched messages to the state
        });
      } else {
        print('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

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
        'groupId': widget.group['_id'],
        'userId': userId,
      });
    });

    socket.onReconnect((_) {
      print('Reconnected to the server');
      socket.emit('joinGroup', {
        'groupId': widget.group['_id'],
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
    try {
      final newMessage = {
        'content': messageContent,
        'sender': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      socket.emit('sendGroupMessage', {
        'groupId': widget.group['_id'],
        'message': newMessage,
        'userId': userId,
      });

      // setState(() {
      //   messages.add(newMessage);
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  // Handlers for PopupMenu actions
  void onAddMembers() {
    print(widget.group["name"]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMembersOrLeadersPage(groupObj: widget.group),
      ),
    );
  }

  void onRequestToJoin() {
    // TODO: Implement the logic to request to join
    print('Request to Join clicked');
  }

  void moreOnGroup() {
    print('More on group');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoreOnGroup(groupObj: widget.group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool isDarkMode =
    //     WidgetsBinding.instance.platformDispatcher.platformBrightness ==
    //         Brightness.dark;

    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.8),
      title: widget.group['name'],
      appBarActions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'addMembers') {
              onAddMembers();
            } else if (value == 'requestToJoin') {
              onRequestToJoin();
            } else if (value == 'more') {
              moreOnGroup();
            }
          },
          itemBuilder: (context) {
            return <PopupMenuEntry<String>>[
              if (isLeader)
                const PopupMenuItem<String>(
                  value: 'addMembers',
                  child: Text('Add Members'),
                ),
              if (!isMember)
                const PopupMenuItem<String>(
                  value: 'requestToJoin',
                  child: Text('Request to Join Group'),
                ),
              const PopupMenuItem<String>(
                value: 'more',
                child: Text('Group details'),
              ),
            ];
          },
          icon: const Icon(Icons.more_vert),
        ),
      ],
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
      floatingActionButton: !isMember
          ? FloatingActionButton(
              onPressed: () {
                if (isLeader) onAddMembers();
                if (!isMember) onRequestToJoin();
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.group_add_sharp),
            )
          : const SizedBox(),
    );
  }
}
