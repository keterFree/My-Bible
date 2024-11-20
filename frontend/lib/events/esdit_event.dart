import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _eventData = {
    'title': '',
    'description': '',
    'theme': '',
    'date': '',
    'time': '',
    'venue': '',
    'keyGuests': <String>[],
    'planners': [],
  };

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = true; // Track the loading state
  final TextEditingController _guestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    try {
      Response response = await Dio().get(
        '${ApiConstants.event}/byId/${widget.eventId}',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      setState(() {
        _eventData['title'] = data['title'];
        _eventData['description'] = data['description'];
        _eventData['theme'] = data['theme'];
        _eventData['venue'] = data['venue'];
        _eventData['date'] = data['date'];
        _eventData['time'] = data['time'];
        _eventData['keyGuests'] = List<String>.from(data['keyGuests']);
        selectedDate = DateTime.parse(data['date']);
       
        try {
          // Check if data['time'] is in the correct format before splitting
          if (data['time'] != null && data['time'].contains(':')) {
            final timeParts = data['time'].split(':');

            if (timeParts.length == 2) {
              // Safely parse the hour and minute, handling any invalid formats
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);

              if (hour != null && minute != null) {
                selectedTime = TimeOfDay(hour: hour, minute: minute);
              } else {
                throw FormatException('Invalid time format');
              }
            } else {
              throw FormatException(
                  'Time string does not have the correct format');
            }
          } else {
            throw FormatException('Time is null or missing ":" separator');
          }
        } catch (e) {
          print('Failed to parse time: $e');
          // Handle the error, e.g., show an error message to the user
        }

        isLoading = false; // Hide the loading indicator
      });
    } catch (e) {
      print('Failed to fetch event details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch event details: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false; // Hide the loading indicator if an error occurs
      });
    }
  }

  Future<void> _updateEvent(BuildContext context) async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    try {
      Response response = await Dio().put(
        '${ApiConstants.event}/edit/${widget.eventId}',
        data: _eventData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('Event updated: ${response.data}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully!')),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _eventData['date'] = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _eventData['time'] = picked.format(context);
      });
    }
  }

  void _addKeyGuest(String guest) {
    if (guest.isNotEmpty && !_eventData['keyGuests'].contains(guest)) {
      setState(() {
        _eventData['keyGuests'].add(guest);
        _guestController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator()); // Display loading indicator when isLoading is true
    }

    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: 'Edit Event',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _eventData['title'],
                  decoration: InputDecoration(labelText: 'Title'),
                  onSaved: (value) => _eventData['title'] = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _eventData['description'],
                  decoration: InputDecoration(labelText: 'Description'),
                  onSaved: (value) => _eventData['description'] = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _eventData['theme'],
                  decoration: InputDecoration(labelText: 'Theme'),
                  onSaved: (value) => _eventData['theme'] = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a theme' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _eventData['venue'],
                  decoration: InputDecoration(labelText: 'Venue'),
                  onSaved: (value) => _eventData['venue'] = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a venue' : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _guestController,
                  decoration: InputDecoration(
                    labelText: 'Add Key Guest',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _addKeyGuest(_guestController.text);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6.0,
                  children: _eventData['keyGuests']
                      .map<Widget>((guest) => Chip(
                            label: Text(guest),
                            onDeleted: () {
                              setState(() {
                                _eventData['keyGuests'].remove(guest);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            selectedDate == null
                                ? 'Select Date'
                                : 'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            selectedTime == null
                                ? 'Select Time'
                                : 'Selected Time: ${selectedTime!.format(context)}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _updateEvent(context);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
