import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/events/createEvent.dart';
import 'package:frontend/lit_Screens/baseScaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  bool hasError = false;
  Map<DateTime, List<dynamic>> eventsMap = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchEvents(context);
  }

  Future<void> _fetchEvents(BuildContext context) async {
    final token = context.read<TokenProvider>().token;
    try {
      Response response = await Dio().get(
        ApiConstants.event,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      // Organize events by their date
      setState(() {
        events = response.data;
        eventsMap = _groupEventsByDate(events);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Map<DateTime, List<dynamic>> _groupEventsByDate(List<dynamic> events) {
    Map<DateTime, List<dynamic>> groupedEvents = {};
    for (var event in events) {
      DateTime eventDate = DateTime.parse(event['date']);
      if (groupedEvents[eventDate] == null) {
        groupedEvents[eventDate] = [];
      }
      groupedEvents[eventDate]!.add(event);
    }
    return groupedEvents;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return eventsMap[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    Color background = isDarkMode
        ? Colors.black.withOpacity(0.8)
        : Colors.black.withOpacity(0.6);

    return BaseScaffold(
      title: 'Church Events',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _buildErrorState()
              : Stack(
                  children: [
                    Container(decoration: BoxDecoration(color: background)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateEventScreen()),
                              );
                            },
                            child: Text(
                              "Set Event",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(child: _buildCalendar()),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showEventDetails(selectedDay);
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.deepOrange,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        //  BoxDecoration(
        //   color: Colors.green,
        //   shape: BoxShape.circle,
        // ),
      ),
    );
  }

  void _showEventDetails(DateTime selectedDay) {
    List<dynamic> selectedEvents = _getEventsForDay(selectedDay);
    if (selectedEvents.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: selectedEvents.length,
            itemBuilder: (context, index) {
              final event = selectedEvents[index];
              return ListTile(
                title: Text(event['title']),
                subtitle: Text(event['description']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(event: event),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/error.json', height: 200),
          const SizedBox(height: 20),
          const Text('Failed to load events. Please try again.'),
        ],
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({required this.event, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['title']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Description: ${event['description']}"),
              Text("Theme: ${event['theme']}"),
              Text("Date: ${event['date']}"),
              Text("Time: ${event['time']}"),
              Text("Venue: ${event['venue']}"),
              Text("Key Guests: ${event['keyGuests'].join(', ')}"),
              Text("Planners: ${event['planners'].join(', ')}"),
              const SizedBox(height: 10),
              const Text("Program:"),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: event['program'].length,
                itemBuilder: (context, index) {
                  final programItem = event['program'][index];
                  return ListTile(
                    title: Text(
                        "${programItem['startTime']} - ${programItem['endTime']}"),
                    subtitle: Text(programItem['description']),
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
