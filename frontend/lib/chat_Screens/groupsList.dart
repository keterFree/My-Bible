import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/chatScreen.dart';

class GroupsListScreen extends StatelessWidget {
  final List<dynamic> groups;

  const GroupsListScreen({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Container(
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .color!
                      .withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 3), // Changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.group,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(groups[index]['name'],
                  style: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
              subtitle: Text(
                '${groups[index]['description'] ?? 'No description available'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              trailing: Text(
                groups[index]['members'].length == 0
                    ? 'no members'
                    : '${groups[index]['members'].length} members',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
              onTap: () {
                // Navigate to GroupScreen, passing the group details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupMessageScreen(group: groups[index]),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
          ),
        );
      },
    );
  }
}
