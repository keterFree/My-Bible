import 'package:flutter/material.dart';

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 3), // Changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.group,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(
                groups[index]['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${groups[index]['description'] ?? 'No description available'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600], // Lighter color for subtitle
                ),
              ),
              trailing: Text(
                'Members: ${groups[index]['members'].length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                ),
              ),
              onTap: () {
                // Navigate to GroupScreen, passing the group details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupScreen(group: groups[index]),
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

class GroupScreen extends StatelessWidget {
  final dynamic group;

  const GroupScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Members: ${group['members'].length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            // Additional content based on group details can go here
          ],
        ),
      ),
    );
  }
}