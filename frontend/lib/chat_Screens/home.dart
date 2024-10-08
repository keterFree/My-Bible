import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/groupsList.dart';
import 'package:frontend/chat_Screens/usersList.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/baseScaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  _ChatHomeScreenState createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String userId = '';
  String userName = 'Anonymous';
  String userContacts = '';
  bool ones = true;
  List<dynamic> allGroups = [];
  List<dynamic> allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserDetails();
    _fetchGroups();
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      print("Token not found or expired");
      return;
    }

    try {
      final jwt = JWT.decode(token);
      setState(() {
        userId = jwt.payload['user']['id'] ?? '';
        userName = jwt.payload['user']['name'] ?? 'Anonymous';
        userContacts = jwt.payload['user']['phone'] ?? '';
      });
    } catch (e) {
      print('Error decoding token: $e');
    }
  }

  Future<void> _fetchGroups() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      var url = Uri.parse(ApiConstants.group);
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        setState(() {
          allGroups = json.decode(response.body);
        });
      } else {
        print('Failed to fetch groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  Future<void> _fetchUsers() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      var url = Uri.parse(ApiConstants.user);
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        setState(() {
          allUsers = json.decode(response.body);
        });
      } else {
        print('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Chats",
      body: Column(
        children: [
          // User Info Section
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ones ? "Groups" : "Members",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          userContacts,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          userName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const Icon(Icons.account_circle, size: 50),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // TabBar for Group and One-on-One Chats
          TabBar(
            onTap: (value) => {
              setState(() {
                ones = !ones;
              })
            },
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Groups'),
            ],
          ),

          // TabBarView to display GroupChatScreen and OneOnOneChatScreen
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UsersListScreen(
                  users: allUsers,
                  currentUser: userId,
                ), // Display User List
                GroupsListScreen(groups: allGroups), // Display Group List
              ],
            ),
          ),
        ],
      ),
    );
  }
}
