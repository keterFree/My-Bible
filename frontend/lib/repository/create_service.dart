import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/base_scaffold.dart';
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

  List<Map<String, dynamic>>? selectedDevotionScripture;
  List<Map<String, dynamic>>? selectedSermonScripture;
  List<Uint8List> uploadedImages = [];
  bool isUploading = false; // State variable for upload progress

  ElevatedButton elevatedB(String label, VoidCallback method) {
    return ElevatedButton(
      onPressed: isUploading ? null : method,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
      child: isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label),
    );
  }

  Future<void> uploadImages() async {
    setState(() => isUploading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        Uint8List? fileBytes =
            file.bytes ?? await File(file.path!).readAsBytes();

        final request =
            http.MultipartRequest('POST', Uri.parse(ApiConstants.uploadImage));
        request.files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: file.name));
        final response = await request.send();

        if (response.statusCode == 201) {
          final responseData =
              json.decode(await response.stream.bytesToString());
          setState(() {
            imageIds.add(responseData['_id']);
            uploadedImages.add(fileBytes);
          });
          _showSnackBar('Image uploaded successfully: ${file.name}');
        } else {
          _showSnackBar('Image upload failed: ${response.reasonPhrase}');
        }
      }
    } else {
      _showSnackBar('No files selected');
    }
    setState(() => isUploading = false);
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
        'sermons': {
          'title': sermonTitleController.text,
          'speaker': sermonSpeakerController.text,
          'scriptures': selectedSermonScripture ?? [],
        },
      };

      try {
        final response = await http.post(
          Uri.parse(ApiConstants.uploadService),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(serviceData),
        );

        if (response.statusCode == 201) {
          _showSnackBar('Service created successfully!');
          _resetForm();
        } else {
          _showSnackBar('Failed to create service: ${response.reasonPhrase}');
        }
      } catch (error) {
        _showSnackBar('An error occurred: $error');
      }
    }
  }

  void _resetForm() {
    setState(() {
      title = '';
      location = '';
      theme = '';
      date = null;
      imageIds.clear();
      uploadedImages.clear();
      devotions.clear();
      devotionTitleController.clear();
      devotionContentController.clear();
      sermonTitleController.clear();
      sermonSpeakerController.clear();
      selectedDevotionScripture = null;
      selectedSermonScripture = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Create Service',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Title', (value) => title = value),
              _buildTextField('Location', (value) => location = value),
              _buildTextField('Theme', (value) => theme = value),
              _buildSermonSection(),
              const Divider(),
              _buildDatePicker(),
              Text('Uploaded Images: ${imageIds.length}'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150, // Adjust this for the desired width
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 2.0,
                  childAspectRatio:
                      1, // Control the aspect ratio (width/height) of items
                ),
                itemCount: uploadedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.memory(
                        uploadedImages[index],
                        fit: BoxFit
                            .cover, // Makes sure images fill the space nicely
                      ),
                    ),
                  );
                },
              ),
              elevatedB('Upload Images', uploadImages),
              const SizedBox(height: 8),
              const Divider(),
              _buildDevotionSection(),
              const SizedBox(height: 16),
              elevatedB('Create Service', submitService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
          labelText: label, labelStyle: Theme.of(context).textTheme.bodyMedium),
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
        if (selectedDate != null) setState(() => date = selectedDate);
      },
      child: Text(date == null ? 'Select Date' : date!.toIso8601String()),
    );
  }

  Widget _buildDevotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Devotions', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTextField('Devotion Title', (value) {
          devotionTitleController.text = value;
        }),
        ScripturePicker(onScripturesSelected: (scripture) {
          setState(() => selectedDevotionScripture = scripture);
        }),
        _buildTextField('Devotion Content', (value) {
          devotionContentController.text = value;
        }),
        elevatedB('Add Devotion', () {
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
        }),
      ],
    );
  }

  Widget _buildSermonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sermons', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTextField('Sermon Title', (value) {
          sermonTitleController.text = value;
        }),
        ScripturePicker(onScripturesSelected: (scripture) {
          setState(() => selectedSermonScripture = scripture);
        }),
        _buildTextField('Speaker', (value) {
          sermonSpeakerController.text = value;
        }),
      ],
    );
  }
}
