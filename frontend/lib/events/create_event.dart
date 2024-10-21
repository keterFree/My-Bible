import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
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
    'keyGuests': <String>[], // Initialize as List<String>
    'planners': []
  };

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController _guestController =
      TextEditingController(); // Guest input controller

  Future<void> createEvent(BuildContext context, String token,
      Map<String, dynamic> eventData) async {
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
      rethrow; // Ensure the error propagates to the caller
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final token = Provider.of<TokenProvider>(context, listen: false).token;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        await createEvent(context, token!, _eventData);

        if (mounted) Navigator.pop(context); // Dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
          ),
        );

        if (mounted) Navigator.pop(context); // Navigate back
      } catch (e) {
        if (mounted) Navigator.pop(context); // Dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Prevent selection of past dates
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
        _guestController.clear(); // Clear the input after adding
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
                    TextField(
                      controller: _guestController,
                      decoration: InputDecoration(
                        labelText: 'Add Key Guest',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
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
                                style: Theme.of(context).textTheme.bodyLarge,
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
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
