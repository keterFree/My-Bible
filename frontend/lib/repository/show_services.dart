import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/repository/all_services.dart';
import 'package:frontend/repository/create_service.dart';
import 'package:frontend/repository/service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<dynamic>> _futureServices;
  List<dynamic> _filteredServices = [];
  DateTime _focusedDate = DateTime.now(); // Track the month in focus
  DateTime? _selectedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _futureServices = fetchServices();
  }

  Future<List<dynamic>> fetchServices() async {
    const String baseUrl = ApiConstants.services; // Replace with your endpoint
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final services = jsonDecode(response.body);
      _filterServicesByMonth(_focusedDate, services);
      return services;
    } else {
      throw Exception('Failed to load services');
    }
  }

  void _filterServicesByMonth(DateTime date, List<dynamic> services) {
    setState(() {
      _filteredServices = services.where((service) {
        final serviceDate = DateTime.parse(service['date']);
        return serviceDate.year == date.year && serviceDate.month == date.month;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'All Services',
      darkModeColor: Colors.black.withOpacity(0.6),
      // lightModeColor: Colors.black.withOpacity(0.1),
      appBarActions: [
        IconButton(
            icon: const Icon(Icons.add_home_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateServiceScreen(), // Pass the resolved list
                ),
              );
            }),
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: () async {
            // Wait for the services to be fetched
            final services = await _futureServices;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllServicesScreen(
                    services: services), // Pass the resolved list
              ),
            );
          },
        ),
      ],
      body: FutureBuilder<List<dynamic>>(
        future: _futureServices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No services available',
                    style: Theme.of(context).textTheme.bodyMedium));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                _buildCalendar(snapshot.data!),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildServiceList(_filteredServices),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ElevatedButton elevatedB(String label, VoidCallback method) {
    return ElevatedButton(
      onPressed: method,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
      child: Text(label),
    );
  }

  Widget _buildCalendar(List<dynamic> services) {
    return TableCalendar(
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
      focusedDay: _focusedDate,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _focusedDate = focusedDay;
        });

        // Check if the selected day has services
        final dayServices = services.where((service) {
          final serviceDate = DateTime.parse(service['date']);
          return isSameDay(selectedDay, serviceDate);
        }).toList();

        if (dayServices.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsScreen(
                serviceId: dayServices.first['_id'],
              ),
            ),
          );
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDate = focusedDay;
        });

        // Update services list based on the new month in focus
        _filterServicesByMonth(focusedDay, services);
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      eventLoader: (day) {
        return services.where((service) {
          final serviceDate = DateTime.parse(service['date']);
          return isSameDay(day, serviceDate);
        }).toList();
      },
    );
  }

  Widget _buildServiceList(List<dynamic> services) {
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ListTile(
          tileColor: const Color.fromARGB(100, 0, 0, 0),
          leading: Icon(
            Icons.handshake_outlined,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
          title: Text(service['title'],
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              )),
          subtitle:
              Text('${service['themes'].map((theme) => theme).join(', ')}',
                  style: GoogleFonts.roboto(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  )),
          trailing: Text(
            DateFormat('dd')
                .format(DateTime.parse(service['date'])), // Day only
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailsScreen(
                    serviceId: service['_id']), // Create this screen
              ),
            );
          },
        );
      },
    );
  }

  Map<String, List<dynamic>> _groupServicesByMonth(List<dynamic> services) {
    final Map<String, List<dynamic>> grouped = {};

    for (var service in services) {
      final month =
          DateFormat('MMMM yyyy').format(DateTime.parse(service['date']));
      if (grouped.containsKey(month)) {
        grouped[month]!.add(service);
      } else {
        grouped[month] = [service];
      }
    }

    return grouped;
  }
}
