import 'package:flutter/material.dart';
import 'package:frontend/events/event_details.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:intl/intl.dart'; // Import for formatting dates

class AllEventsScreen extends StatelessWidget {
  final List<dynamic> events;

  const AllEventsScreen({super.key, required this.events});

  // Group events by month
  Map<String, List<dynamic>> _groupEventsByMonth(List<dynamic> events) {
    Map<String, List<dynamic>> groupedEvents = {};

    for (var event in events) {
      DateTime eventDate = DateTime.parse(event['date']);
      String monthYear =
          DateFormat('MMMM yyyy').format(eventDate); // Example: "October 2024"

      if (!groupedEvents.containsKey(monthYear)) {
        groupedEvents[monthYear] = [];
      }
      groupedEvents[monthYear]!.add(event);
    }

    return groupedEvents;
  }

  @override
  Widget build(BuildContext context) {
    // Group events by month
    final groupedEvents = _groupEventsByMonth(events);
    final months = groupedEvents.keys.toList();

    return BaseScaffold(
      title: 'All Events',
      body: Stack(
        children: [
          Container(
              decoration:
                  const BoxDecoration(color: Color.fromARGB(100, 0, 0, 0))),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: events.isEmpty
                ? const Center(child: Text('No events available.'))
                : ListView.builder(
                    itemCount: months.length,
                    itemBuilder: (context, monthIndex) {
                      String month = months[monthIndex];
                      List<dynamic> monthEvents = groupedEvents[month]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Title
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              month,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Events List for this Month
                          ...monthEvents.map((event) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: ListTile(
                                  tileColor: const Color.fromARGB(100, 0, 0, 0),
                                  leading: Icon(
                                    Icons.event_available_outlined,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                                  ),
                                  title: Text(
                                    event['title'],
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    event['description'],
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  trailing: Text(
                                    DateFormat('dd').format(DateTime.parse(
                                        event['date'])), // Day only
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EventDetailScreen(event: event),
                                      ),
                                    );
                                  },
                                ),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
