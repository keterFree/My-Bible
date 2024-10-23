import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/base_scaffold.dart';
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
  int? editingIndex;

  List<Map<String, dynamic>> programItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails(); // Fetch event details from the API
  }

  Future<void> _fetchEventDetails() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    final url = Uri.parse('${ApiConstants.event}/byId/${widget.event['_id']}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        final eventData = jsonDecode(response.body);
        setState(() {
          programItems = List<Map<String, dynamic>>.from(eventData['program']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load event: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStartTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            startTime != null && (DateTime.tryParse(startTime!) != null)
                ? TimeOfDay.fromDateTime(DateTime.parse(startTime!))
                : TimeOfDay.now());
    if (pickedTime != null) {
      setState(() {
        startTime = _formatTimeOfDay(pickedTime);
      });
    }
  }

  Future<void> _selectEndTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: endTime != null && (DateTime.tryParse(endTime!) != null)
            ? TimeOfDay.fromDateTime(DateTime.parse(endTime!))
            : TimeOfDay.now());
    if (pickedTime != null) {
      setState(() {
        endTime = _formatTimeOfDay(pickedTime);
      });
    }
  }

  Future<void> _addOrEditProgramItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (startTime == null ||
          endTime == null ||
          (description?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all fields.')),
        );
        return;
      }

      final body = {
        'startTime': startTime!,
        'endTime': endTime!,
        'description': description!,
      };
      final token = Provider.of<TokenProvider>(context, listen: false).token;

      try {
        Uri url;
        http.Response response;

        if (editingIndex != null) {
          final programItem = programItems[editingIndex!];
          url = Uri.parse(
              '${ApiConstants.programItem}/${widget.event['_id']}/${programItem['_id']}');
          response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        } else {
          url = Uri.parse('${ApiConstants.programItem}/${widget.event['_id']}');
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        }

        if (response.statusCode == 200) {
          final eventData = jsonDecode(response.body);
          setState(() {
            programItems =
                List<Map<String, dynamic>>.from(eventData['program']);
            isLoading = false;
          });
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Operation failed: ${response.body}')),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showProgramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              editingIndex != null ? "Edit Program Item" : "Add Program Item"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _selectStartTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: startTime ?? "Select Start Time"),
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _selectEndTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: endTime ?? "Select End Time"),
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: description,
                  decoration: InputDecoration(labelText: "Description"),
                  onSaved: (value) => description = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 20),
                // Preview Section
                if (startTime != null && endTime != null && description != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Preview:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text("Start Time: $startTime"),
                      Text("End Time: $endTime"),
                      Text("Description: $description"),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _addOrEditProgramItem();
                _clearForm();
              },
              child: Text(editingIndex != null ? "Save Changes" : "Add Item"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: "Event Program",
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                onPressed: () => _showProgramDialog(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  // Add any default style properties here
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0), // example padding
                ),
                child: const Text("Add Program Item"),
              ),
            ),
            const SizedBox(height: 20),
            widget.event['program'].isEmpty
                ? _buildErrorState()
                : Expanded(
                    child: ListView.builder(
                      itemCount: programItems.length,
                      itemBuilder: (context, index) {
                        final programItem = programItems[index];
                        print('build:  $programItem\n\n');
                        return Card(
                          color: const Color.fromARGB(100, 0, 0, 0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ListTile(
                              leading: SizedBox(
                                width: 90, // Fixed width to avoid overflow
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      programItem['startTime'] ?? 'N/A',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    // const SizedBox(height: 4),
                                    Text(
                                      programItem['endTime'] ?? 'N/A',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                programItem['description'] ?? 'No Description',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color,
                                ),
                                onPressed: () {
                                  editingIndex = index;
                                  setState(() {
                                    startTime = programItem['startTime'];
                                    endTime = programItem['endTime'];
                                    description = programItem['description'];
                                  });
                                  _showProgramDialog();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      // isLoading
      //     ? Center(child: CircularProgressIndicator())
      //     : programItems.isEmpty
      //         ? _buildErrorState()
      //         : ListView.builder(
      //             itemCount: programItems.length,
      //             itemBuilder: (context, index) {
      //               final item = programItems[index];
      //               print("build : ${item.toString()}");
      //               return ListTile(
      //                 title: Text(item['description'] ?? 'No Description'),
      //                 subtitle:
      //                     Text('${item['startTime']} - ${item['endTime']}'),
      //                 trailing: IconButton(
      //                   icon: const Icon(Icons.edit),
      //                   onPressed: () => _showProgramDialog(),
      //                 ),
      //               );
      //             },
      //           ),
    );
  }

  void _clearForm() {
    setState(() {
      startTime = null;
      endTime = null;
      description = null;
      editingIndex = null;
      _formKey.currentState?.reset();
    });
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
}
