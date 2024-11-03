import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/groups_list.dart';
import 'package:frontend/chat_Screens/users_list.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
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

  bool _isLoading = true; // Loading indicator state
  bool _hasError = false; // Error flag

  List<dynamic> allGroups = [];
  List<dynamic> allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData(); // Combined fetch
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _fetchUserDetails();
      await Future.wait([_fetchGroups(), _fetchUsers()]);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      print("Token not found or expired, try loggin in.");
      throw Exception('Invalid token');
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
      rethrow;
    }
  }

  Future<void> _fetchGroups() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) throw Exception('Invalid token');

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
        throw Exception('Failed to fetch groups');
      }
    } catch (e) {
      print('Error fetching groups: $e');
      rethrow;
    }
  }

  Future<void> _fetchUsers() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) throw Exception('Invalid token');

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
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/error.json', height: 200),
          const SizedBox(height: 20),
          const Text(
            'Failed to load members.\nPlease try again',
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: "Chats",
      body: _isLoading
          ? _buildLoadingIndicator() // Show loading indicator
          : _hasError
              ? _buildErrorState() // Show error state
              : Column(
                  children: [
                    // User Info Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ones ? "Groups" : "Members",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .appBarTheme
                                  .titleTextStyle!
                                  .color,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
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
                      labelColor:
                          Theme.of(context).appBarTheme.titleTextStyle!.color,
                      unselectedLabelColor:
                          Theme.of(context).textTheme.bodyMedium!.color,
                      indicatorColor:
                          Theme.of(context).appBarTheme.titleTextStyle!.color,
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
                          GroupsListScreen(
                              groups: allGroups), // Display Group List
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
