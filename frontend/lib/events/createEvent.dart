import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/baseScaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl package

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _eventData = {
    'title': '',
    'description': '',
    'theme': '',
    'date': '',
    'time': '',
    'venue': '',
    'keyGuests': [],
  };

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> createEvent(
      BuildContext context, String token, Map<String, dynamic> eventData) async {
    try {
      Response response = await Dio().post(
        ApiConstants.event,
        data: eventData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      print('Event created: ${response.data}');
    } catch (e) {
      print('Error creating event: $e');
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      try {
        await createEvent(context, token!, _eventData);
        Navigator.pop(context);
      } catch (e) {
        print('Error creating event: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
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
    if (picked != null && picked != selectedTime) {
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
      });
    }
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
      title: 'Create Event',
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: background),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onSaved: (value) => _eventData['title'] = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onSaved: (value) => _eventData['description'] = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Theme',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onSaved: (value) => _eventData['theme'] = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a theme' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Venue',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onSaved: (value) => _eventData['venue'] = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a venue' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _selectDate(context),
                            child: Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : 'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _selectTime(context),
                            child: Text(
                              selectedTime == null
                                  ? 'Select Time'
                                  : 'Selected Time: ${selectedTime!.format(context)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Key Guest',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onFieldSubmitted: (value) {
                        _addKeyGuest(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Key Guests: ${_eventData['keyGuests'].join(', ')}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _submitForm(context),
                      child: const Text('Create Event'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
