import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ProgramScreen extends StatefulWidget {
  final Map event;

  const ProgramScreen({required this.event, super.key});

  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? startTime;
  String? endTime;
  String? description;

  // Function to convert TimeOfDay to HH:mm format
  String _formatTimeOfDay(TimeOfDay time) {
    String timed =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    print(timed);
    return timed;
  }

  // Function to show time picker and update start time
  Future<void> _selectStartTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        startTime = _formatTimeOfDay(
            pickedTime); // Convert and format the selected time
      });
    }
  }

  // Function to show time picker and update end time
  Future<void> _selectEndTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        endTime = _formatTimeOfDay(pickedTime);
      });
    }
  }

  // Function to handle adding a new program item
  Future<void> _addProgramItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Prepare the request body
      final body = {
        'startTime': startTime!,
        'endTime': endTime!,
        'description': description!,
      };
      final token = Provider.of<TokenProvider>(context, listen: false).token;

      // Send a POST request to the API
      try {
        Uri url =
            Uri.parse('${ApiConstants.programItem}/${widget.event['_id']}');
        print(url.toString());
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        // Check the response status
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, add the program item to the list
          setState(() {
            widget.event['program'].add(body);
          });
          Navigator.pop(context); // Close the modal after saving
        } else {
          // Handle errors or display a message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to add program item: ${response.body}')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occurred while adding the program item')),
        );
      }
    }
  }

  // Function to open a modal for updating/adding a program item
  void _showUpdateProgramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.red,
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          title: Text("Add Program Item",
              style: Theme.of(context).textTheme.bodySmall),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Time Input
                  GestureDetector(
                    onTap: _selectStartTime,
                    child: AbsorbPointer(
                      child: TextFormField(
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                            labelText: "Start Time",
                            labelStyle: Theme.of(context).textTheme.bodySmall),
                        readOnly: true,
                        validator: (value) {
                          final RegExp timeRegex =
                              RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
                          if (startTime == null ||
                              startTime!.isEmpty ||
                              !timeRegex.hasMatch(startTime!)) {
                            return "Please enter a valid start time in HH:mm format";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          startTime = value;
                          print(startTime);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // End Time Input
                  GestureDetector(
                    onTap: _selectEndTime,
                    child: AbsorbPointer(
                      child: TextFormField(
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                            labelText: "End Time",
                            labelStyle: Theme.of(context).textTheme.bodySmall),
                        readOnly: true,
                        validator: (value) {
                          final RegExp timeRegex =
                              RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
                          if (endTime == null ||
                              endTime!.isEmpty ||
                              !timeRegex.hasMatch(endTime!)) {
                            return "Please enter a valid end time in HH:mm format";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          endTime = value;
                          print(endTime);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description Input
                  TextFormField(
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: Theme.of(context).textTheme.bodySmall),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a description";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      description = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _addProgramItem,
              child: Text("Add Program",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary)),
            ),
          ],
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
          const Text('The program is currently not available.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Event Program",
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(100, 0, 0, 0), // Background overlay
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: ElevatedButton(
                    onPressed: _showUpdateProgramDialog,
                    child: Text("Update Program",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary)),
                  ),
                ),
                const Text(
                  "Program Schedule",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                widget.event['program'].isEmpty
                    ? _buildErrorState()
                    : Expanded(
                        child: ListView.builder(
                          itemCount: widget.event['program'].length,
                          itemBuilder: (context, index) {
                            final programItem = widget.event['program'][index];
                            return Card(
                              color: const Color.fromARGB(150, 0, 0, 0),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          programItem['startTime']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                        ),
                                        const Text(
                                          'to',
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          programItem['endTime']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      programItem['description']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontFamily: 'Roboto',
                                            fontSize: 16,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
