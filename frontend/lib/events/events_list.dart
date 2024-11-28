import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'package:frontend/constants.dart';
import 'package:frontend/events/all_events.dart';
import 'package:frontend/events/create_event.dart';
import 'package:frontend/events/event_details.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Add this import
import 'package:intl/intl.dart';

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

  void _printEvents() async {
    final pdf = pw.Document();

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text('List of Events',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              // Loop through the events and display details
              ...events.map(
                (event) {
                  // Format date
                  final formattedDate = DateFormat('MMM d yy', 'en_US')
                      .format(DateTime.parse(event['date']))
                      .toUpperCase();

                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        pw.Text('Title: ${event['title']}',
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),

                        // Event Date
                        pw.Text('Date: $formattedDate',
                            style: pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(height: 5),

                        // Organizers
                        pw.Text(
                          'Organized by: ${event['planners']?.map((planner) => planner['name'])?.join(', ') ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),

                        // Key Guests
                        pw.Text(
                          'Key Guests: ${event['keyGuests']?.join(', ') ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),

                        // Venue
                        pw.Text(
                          'Venue: ${event['venue'] ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),

                        // Start Time
                        pw.Text(
                          'Start Time: ${event['time'] ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),

                        // Event Description
                        pw.Text(
                          'Description: ${event['description'] ?? 'No description available'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),

                        // Event Theme
                        pw.Text(
                          'Theme: ${event['theme'] ?? 'No theme specified'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to a file and provide download option
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool isDarkMode =
    //     WidgetsBinding.instance.platformDispatcher.platformBrightness ==
    //         Brightness.dark;

    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: 'Church Events',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: _printEvents,
          tooltip: 'Print Event List',
        ),
      ],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _buildErrorState()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              // Add any default style properties here
                              padding:
                                  const EdgeInsets.all(16.0), // example padding
                            ),
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
                                textStyle: const TextStyle(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _showAllEvents,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              // Add any default style properties here
                              padding:
                                  const EdgeInsets.all(16.0), // example padding
                            ),
                            child: Text(
                              "All Events",
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(),
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
                  onTap: () {
                    print(event['date']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: event),
                      ),
                    );
                  },
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.description, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event['description'] ?? 'No Description',
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.monitor_heart_outlined,
                                color: Colors.green),
                            const SizedBox(width: 10),
                            Text('Theme: ${event['theme'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.orange),
                            const SizedBox(width: 10),
                            Text(
                                'Date: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.purple),
                            const SizedBox(width: 10),
                            Text('Time: ${event['time'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 10),
                            Text('Venue: ${event['venue'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Colors.cyan),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Key Guests: ${event['keyGuests']?.join(', ') ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add, color: Colors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Planners: ${event['planners']?.map((planner) => planner['name'])?.join(', ') ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
          Lottie.asset('assets/images/error.json', width: 150),
          const SizedBox(height: 20),
          Text(
            'Failed to load events.',
            style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
