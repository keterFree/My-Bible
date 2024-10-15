import 'package:flutter/material.dart';

class MoreOnGroup extends StatelessWidget {
  final dynamic groupObj;

  const MoreOnGroup({super.key, required this.groupObj});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupObj['name']), // Display the group name in the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Name and Restricted Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    groupObj['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (groupObj['restricted'] == true)
                    const Icon(Icons.lock,
                        color: Colors.red), // Show lock icon if restricted
                ],
              ),
              const SizedBox(height: 8.0),

              // Description
              if (groupObj['description'] != null)
                Text(
                  groupObj['description'],
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

              const SizedBox(height: 16.0),

              // Group Creator
              Text(
                // 'Created by: ${groupObj['creator']}', // Display the group's creator
                'Created by: ${groupObj['creator']['name']}', // Display the group's creator
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),

              // Leaders List
              Text(
                'Leaders (${groupObj['leaders'].length}):',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              // Handling leaders list
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap:
                    true, // Allow the list to take only the required space
                itemCount: groupObj['leaders'].length,
                itemBuilder: (context, index) {
                  final leader = groupObj['leaders'][index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(leader['name']),
                    subtitle: const Text('Leader'),
                  );
                },
              ),
              const Divider(height: 24),
              // Members List
              Text(
                'Members (${groupObj['members'].length}):',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),

              // Handling members list
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap:
                    true, // Allow the list to take only the required space
                itemCount: groupObj['members'].length,
                itemBuilder: (context, index) {
                  final member = groupObj['members'][index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(member['name']),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
