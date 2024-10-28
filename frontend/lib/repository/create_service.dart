import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/constants.dart';
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
  List<Uint8List> uploadedImages = []; // Add this line

  Future<void> uploadImages() async {
    // Pick multiple image files
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true, // Allow multiple selections
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        // Check if file.bytes is null, if so, use the file path
        Uint8List? fileBytes;
        if (file.bytes != null) {
          fileBytes = file.bytes;
        } else {
          // If bytes are not available, read the file using the file path
          final filePath = file.path;
          if (filePath != null) {
            fileBytes = await File(filePath).readAsBytes();
          }
        }

        // If fileBytes is still null, show an error
        if (fileBytes == null) {
          _showSnackBar('Failed to read the file: ${file.name}');
          continue; // Skip to the next file
        }

        // Create a multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConstants.uploadImage),
        );

        // Add the file to the request
        request.files.add(http.MultipartFile.fromBytes(
          'file', // This should match the field name in your Node.js code
          fileBytes, // Use the file bytes
          filename: file.name, // The original filename
        ));

        // Send the request
        final response = await request.send();

        // Handle the response
        if (response.statusCode == 201) {
          final responseData =
              json.decode(await response.stream.bytesToString());
          setState(() {
            print(responseData.toString());
            imageIds.add(responseData['_id']); // Store the uploaded image ID
            // You can also store the image bytes for display
            uploadedImages.add(fileBytes!); // Store the image bytes for display
          });
          _showSnackBar('Image uploaded successfully: ${file.name}');
        } else {
          _showSnackBar('Image upload failed: ${response.reasonPhrase}');
        }
      }
    } else {
      _showSnackBar('No files selected');
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
        Uri.parse(ApiConstants.uploadService),
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
              Text('Uploaded Images: ${imageIds.length}'),
              Row(
                children: [
                  // Display uploaded images
                  ...uploadedImages.map((imageBytes) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Image.memory(imageBytes, height: 100),
                    );
                  }).toList()
                ],
              ),
              ElevatedButton(
                  onPressed: uploadImages, child: Text('Upload Images')),
              SizedBox(height: 8),
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
