import 'package:flutter/material.dart';
import 'package:frontend/events/program.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: event['title'],
      body: Stack(
        children: [
          Container(
              decoration:
                  const BoxDecoration(color: Color.fromARGB(170, 0, 0, 0))),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProgramScreen(
                              event: event, // Pass the program list
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        // Add any default style properties here
                        padding: const EdgeInsets.symmetric(horizontal: 16.0), // example padding
                      ),
                      child: const Text(
                        "Program",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (event['theme']).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (event['description']).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w300,
                          fontSize: 20,
                          letterSpacing: 1.5,
                          color: Colors.grey[300],
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    DateFormat('MMM d yy', 'en_US')
                        .format(DateTime.parse(event['date']))
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                  ),
                  Container(
                    height: 2, // Underline thickness
                    width: 100, // Adjust width as needed
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['time'],
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    event['venue'].toUpperCase(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Key Guest(s)",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.white),
                  ),
                  Container(
                    height: 2, // Underline thickness
                    width: 150, // Adjust width as needed
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['keyGuests'].join('\n'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey[300],
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Organized by ${event['planners']?.map((planner) => planner['name'])?.join(', ') ?? 'N/A'}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: 'Roboto',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
