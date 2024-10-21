import 'package:flutter/material.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: event['title'],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    context,
                    Icons.label,
                    "Theme",
                    event['theme'] ?? 'N/A',
                  ),
                  // Event Description
                  _buildInfoCard(
                    context,
                    Icons.description,
                    "Description",
                    event['description'] ?? 'No Description',
                  ),

                  _buildInfoCard(
                    context,
                    Icons.calendar_today,
                    "Date",
                    event['date'] ?? 'N/A',
                  ),
                  _buildInfoCard(
                    context,
                    Icons.access_time,
                    "Time",
                    event['time'] ?? 'N/A',
                  ),
                  _buildInfoCard(
                    context,
                    Icons.location_on,
                    "Venue",
                    event['venue'] ?? 'N/A',
                  ),
                  _buildInfoCard(
                    context,
                    Icons.people,
                    "Key Guests",
                    event['keyGuests']?.join('\n') ?? 'N/A',
                  ),
                  _buildInfoCard(
                    context,
                    Icons.person_add,
                    "Planners",
                    event['planners']?.join('\n') ?? 'N/A',
                  ),
                  const SizedBox(height: 20),
                  const Text("Program:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Program List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: event['program']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final programItem = event['program'][index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            "${programItem['startTime']} - ${programItem['endTime']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(programItem['description']),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, IconData icon, String title, String value) {
    return Card(
      color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
