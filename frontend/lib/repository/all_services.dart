import 'package:flutter/material.dart';
import 'package:frontend/repository/service.dart'; // Adjust the import to your service details screen
import 'package:frontend/base_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for formatting dates

class AllServicesScreen extends StatelessWidget {
  final List<dynamic> services;

  const AllServicesScreen({super.key, required this.services});

  // Group services by month
  Map<String, List<dynamic>> _groupServicesByMonth(List<dynamic> services) {
    Map<String, List<dynamic>> groupedServices = {};

    for (var service in services) {
      DateTime serviceDate = DateTime.parse(service['date']);
      String monthYear = DateFormat('MMMM yyyy')
          .format(serviceDate); // Example: "October 2024"

      if (!groupedServices.containsKey(monthYear)) {
        groupedServices[monthYear] = [];
      }
      groupedServices[monthYear]!.add(service);
    }

    return groupedServices;
  }

  @override
  Widget build(BuildContext context) {
    // Group services by month
    final groupedServices = _groupServicesByMonth(services);
    final months = groupedServices.keys.toList();

    // Sort months from earliest to latest
    months.sort((a, b) => DateFormat('MMMM yyyy')
        .parse(a)
        .compareTo(DateFormat('MMMM yyyy').parse(b)));

    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: 'All Services',
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: services.isEmpty
            ? const Center(child: Text('No services available.'))
            : ListView.builder(
                itemCount: months.length,
                itemBuilder: (context, monthIndex) {
                  String month = months[monthIndex];
                  List<dynamic> monthServices = groupedServices[month]!;

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
                      // Services List for this Month
                      ...monthServices.map((service) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: ListTile(
                              tileColor: const Color.fromARGB(100, 0, 0, 0),
                              leading: Icon(
                                Icons
                                    .handshake_outlined, // Change icon as needed
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                              ),
                              title: Text(
                                service['title'],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                  '${service['themes'].map((theme) => theme).join(', ')}',
                                  style: GoogleFonts.roboto(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                  )),
                              trailing: Text(
                                DateFormat('dd').format(DateTime.parse(
                                    service['date'])), // Day only
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceDetailsScreen(
                                        serviceId: service['id']),
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
    );
  }
}
