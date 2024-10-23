import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/base_scaffold.dart';
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
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
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
          selectedLeaders
              .remove(userId); // Remove from leaders if deselected as member
        } else {
          selectedMembers.add(userId);
        }
      }
    });
  }

  Future<void> addMembersOrLeaders() async {
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
    return BaseScaffold(
      title: 'Add Members to ${widget.groupObj["name"]}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            child: const Icon(Icons.group_add),
            onPressed: () => addMembersOrLeaders(),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color for the search bar
                borderRadius: BorderRadius.circular(30.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Subtle shadow
                    blurRadius: 6.0, // Shadow spread
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400, // Lighter hint text color
                    fontStyle: FontStyle.italic, // Italic hint text for style
                  ),
                  border: InputBorder.none, // Remove the outline border
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600, // Custom color for the icon
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: () {
                      // Clear the search field
                      setState(() {
                        searchQuery = "";
                        filteredUsers = allUsers;
                      });
                    },
                  ), // Optional clear button
                ),
              ),
            ),
          ),

          // Labels for checkboxes
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Add as Leader (Optional)',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
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
                final isSelectedMember = selectedMembers.contains(user['_id']);
                final isSelectedLeader = selectedLeaders.contains(user['_id']);

                return ListTile(
                  onTap: () {
                    _onUserSelected(
                        user['_id'], false); // Add or remove as member
                  },
                  title: Text(
                    user['name'],
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user['phone'],
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontSize: 12.0),
                  ),
                  trailing: isSelectedMember
                      ? Column(
                          children: [
                            Checkbox(
                              value: isSelectedLeader,
                              onChanged: (value) {
                                _onUserSelected(user['_id'],
                                    true); // Add or remove as leader
                              },
                              activeColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ],
                        )
                      : null,
                  selected:
                      isSelectedMember, // Show visual feedback when selected
                  selectedTileColor: Colors.green.withOpacity(
                      0.6), // Slight background color when selected
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
