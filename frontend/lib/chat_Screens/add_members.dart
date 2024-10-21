import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AddMembersOrLeadersPage extends StatefulWidget {
  final Map groupObj;

  const AddMembersOrLeadersPage({super.key, required this.groupObj});

  @override
  _AddMembersOrLeadersPageState createState() =>
      _AddMembersOrLeadersPageState();
}

class _AddMembersOrLeadersPageState extends State<AddMembersOrLeadersPage> {
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  List<String> selectedMembers = [];
  List<String> selectedLeaders = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      var url = Uri.parse(ApiConstants.user);
      // print(token);
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      print(response);
      if (response.statusCode == 200) {
        print(json.decode(response.body).length);
        setState(() {
          allUsers = json.decode(response.body);
          filteredUsers = allUsers;
        });
      } else {
        print('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = allUsers
          .where((user) =>
              user['name'].toLowerCase().contains(query.toLowerCase()) ||
              user['phone'].contains(query))
          .toList();
    });
  }

  void _onUserSelected(String userId, bool isLeader) {
    setState(() {
      if (isLeader) {
        if (selectedLeaders.contains(userId)) {
          selectedLeaders.remove(userId);
        } else {
          selectedLeaders.add(userId);
        }
      } else {
        if (selectedMembers.contains(userId)) {
          selectedMembers.remove(userId);
        } else {
          selectedMembers.add(userId);
        }
      }
    });
  }

  Future<void> addMembersOrLeaders() async {
    print("Adding members");
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      var url =
          Uri.parse("${ApiConstants.addToGroup}/${widget.groupObj["_id"]}");
      final response = await http.put(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: json.encode({
            'membersToAdd': selectedMembers,
            'leadersToAdd': selectedLeaders
          }));

      if (response.statusCode == 200) {
        print('Group updated successfully');
        Navigator.pop(context);
      } else {
        print('Failed to add members or leaders: $response');
      }
    } catch (e) {
      print('Error adding members or leaders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Members to ${widget.groupObj["name"]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add), // Changed icon to "group add"
            onPressed: () => addMembersOrLeaders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                labelText: 'Search by name or phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Labels for checkboxes
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add as ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.headlineLarge!.color),
                ),
                Row(
                  children: [
                    Text(
                      'Member',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color:
                              Theme.of(context).textTheme.headlineLarge!.color),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Leader',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color:
                              Theme.of(context).textTheme.headlineLarge!.color),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  title: Text(
                    user['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold), // Bold for name
                  ),
                  subtitle: Text(
                    user['phone'],
                    style: const TextStyle(
                        fontSize: 12.0), // Smaller font for phone
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          // Checkbox for adding as member
                          Checkbox(
                            value: selectedMembers.contains(user['_id']),
                            onChanged: (value) {
                              _onUserSelected(user['_id'], false);
                            },
                            activeColor: Theme.of(context)
                                .primaryColor, // Custom color for WhatsApp-like style
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          width: 16), // Space between the two columns
                      Column(
                        children: [
                          // Checkbox for adding as leader
                          Checkbox(
                            value: selectedLeaders.contains(user['_id']),
                            onChanged: (value) {
                              _onUserSelected(user['_id'], true);
                            },
                            activeColor: Colors
                                .green, // Use green to differentiate leader role
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
