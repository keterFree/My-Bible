import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'package:frontend/constants.dart';
import 'package:frontend/events/all_events.dart';
import 'package:frontend/events/create_event.dart';
import 'package:frontend/events/event_details.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

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
  CalendarFormat _calendarFormat = CalendarFormat.month;

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

  List<dynamic> _getEventsForMonth(DateTime month) {
    return events.where((event) {
      DateTime eventDate = DateTime.parse(event['date']);
      return eventDate.year == month.year && eventDate.month == month.month;
    }).toList();
  }

  void _showAllEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllEventsScreen(events: events),
      ),
    );
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  style: GoogleFonts.lato(
                                    textStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _showAllEvents,
                                child: Text(
                                  "All Events",
                                  style: GoogleFonts.lato(
                                    textStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildCalendar(),
                          const SizedBox(height: 10),
                          Expanded(child: _buildEventListForMonth()),
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
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showEventDetails(selectedDay);
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        if (format != CalendarFormat.month) {
          setState(() {
            // Automatically switch back to the month view
            _calendarFormat = CalendarFormat.month;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only month view is allowed.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.rectangle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.deepOrange,
          shape: BoxShape.rectangle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildEventListForMonth() {
    List<dynamic> monthlyEvents = _getEventsForMonth(_focusedDay);
    if (monthlyEvents.isEmpty) {
      return const Center(child: Text('No events scheduled this month.'));
    }
    return ListView.builder(
      itemCount: monthlyEvents.length,
      itemBuilder: (context, index) {
        final event = monthlyEvents[index];
        return ListTile(
          tileColor: const Color.fromARGB(100, 0, 0, 0),
          leading: Icon(
            Icons.event_available_outlined,
            color: Theme.of(context).textTheme.bodyMedium!.color,
            // size:20
          ),
          title: Text(event['title'],
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              )),
          subtitle: Text(event['description'],
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.bodyMedium,
              )),
          trailing: Text(DateTime.parse(event['date']).day.toString(),
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.bodyMedium,
              )),
          onTap: () {
            print(event['date']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
        );
      },
    );
  }

  void _showEventDetails(DateTime selectedDay) {
    List<dynamic> selectedEvents = _getEventsForDay(selectedDay);
    if (selectedEvents.isEmpty) return;

    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
      context: context,
      builder: (context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return ListTile(
                  title: Align(
                    alignment: Alignment.topCenter,
                    child: Text(event['title'] ?? 'No Title',
                        style: GoogleFonts.poppins(
                          textStyle:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                        )),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event['description'] ?? 'No Description',
                              style: GoogleFonts.poppins(
                                textStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(
                            event['date'] ?? 'No Date',
                            style: GoogleFonts.poppins(
                              textStyle:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lotties/error.json', width: 150),
          const SizedBox(height: 20),
          Text(
            'Failed to load events.',
            style: GoogleFonts.poppins(
              textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}