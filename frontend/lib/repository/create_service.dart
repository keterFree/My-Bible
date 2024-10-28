import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'scripture_picker.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String title = '';
  String location = '';
  DateTime? date;
  String theme = '';
  List<String> imageIds = [];

  final TextEditingController devotionTitleController = TextEditingController();
  final TextEditingController devotionContentController =
      TextEditingController();
  final List<Map<String, dynamic>> devotions = [];

  final TextEditingController sermonTitleController = TextEditingController();
  final TextEditingController sermonSpeakerController = TextEditingController();
  final List<Map<String, dynamic>> sermons = [];

  List<Map<String, dynamic>>? selectedDevotionScripture;
  List<Map<String, dynamic>>? selectedSermonScripture;

  Future<void> uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      final file = result.files.first;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your-backend-url/upload-image'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      final response = await request.send();
      if (response.statusCode == 201) {
        final responseData = json.decode(await response.stream.bytesToString());
        setState(() {
          imageIds.add(responseData['_id']);
        });
      } else {
        _showSnackBar('Image upload failed');
      }
    }
  }

  Future<void> submitService() async {
    if (_formKey.currentState!.validate() && date != null) {
      final serviceData = {
        'title': title,
        'date': date!.toIso8601String(),
        'location': location,
        'theme': theme,
        'images': imageIds,
        'devotions': devotions,
        'sermons': sermons,
      };

      final response = await http.post(
        Uri.parse('https://your-backend-url/create-service'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(serviceData),
      );

      if (response.statusCode == 201) {
        _showSnackBar('Service created successfully!');
        Navigator.pop(context);
      } else {
        _showSnackBar('Failed to create service');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Service')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Title', (value) => title = value),
              _buildTextField('Location', (value) => location = value),
              _buildTextField('Theme', (value) => theme = value),
              _buildDatePicker(),
              ElevatedButton(
                  onPressed: uploadImage, child: Text('Upload Image')),
              SizedBox(height: 8),
              Text('Uploaded Images: ${imageIds.length}'),
              Divider(),
              _buildDevotionSection(),
              Divider(),
              _buildSermonSection(),
              SizedBox(height: 16),
              ElevatedButton(
                  onPressed: submitService, child: Text('Create Service')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDatePicker() {
    return TextButton(
      onPressed: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) {
          setState(() {
            date = selectedDate;
          });
        }
      },
      child: Text(date == null ? 'Select Date' : date!.toIso8601String()),
    );
  }

  Widget _buildDevotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Devotions', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTextField('Devotion Title', (_) {}),
        ScripturePicker(onScripturesSelected: (scripture) {
          setState(() {
            selectedDevotionScripture = scripture;
          });
        }),
        _buildTextField('Devotion Content', (_) {}),
        ElevatedButton(
          onPressed: () {
            setState(() {
              devotions.add({
                'title': devotionTitleController.text,
                'content': devotionContentController.text,
                'scriptures': selectedDevotionScripture ?? [],
              });
              devotionTitleController.clear();
              devotionContentController.clear();
              selectedDevotionScripture = null;
            });
          },
          child: Text('Add Devotion'),
        ),
      ],
    );
  }

  Widget _buildSermonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sermons', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTextField('Sermon Title', (_) {}),
        ScripturePicker(onScripturesSelected: (scripture) {
          setState(() {
            selectedSermonScripture = scripture;
          });
        }),
        _buildTextField('Sermon Speaker', (_) {}),
        ElevatedButton(
          onPressed: () {
            setState(() {
              sermons.add({
                'title': sermonTitleController.text,
                'speaker': sermonSpeakerController.text,
                'scriptures': selectedSermonScripture ?? [],
              });
              sermonTitleController.clear();
              sermonSpeakerController.clear();
              selectedSermonScripture = null;
            });
          },
          child: Text('Add Sermon'),
        ),
      ],
    );
  }
}
