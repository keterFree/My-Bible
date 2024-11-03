import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/repository/show_services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'scripture_picker.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String title = '', location = '', theme = '';
  DateTime? date;
  String? serviceTitle;
  String? serviceId; // Holds the service ID after creation.
  bool isUploading = false;

  bool showbuildMainServiceSection = false;
  bool showbuildImageUploadSection = false;
  bool showbuildSermonSection = false;
  bool showbuildDevotionSection = false;
  bool done = false;
  List<String> sermonPoints = [];

  // Controllers and Lists
  final List<String> imageIds = [];
  final List<Uint8List> uploadedImages = [];
  final List<Map<String, dynamic>> devotions = [];
  final TextEditingController _pointController = TextEditingController();
  final TextEditingController devotionTitleController = TextEditingController();
  final TextEditingController devotionContentController =
      TextEditingController();
  final TextEditingController sermonTitleController = TextEditingController();
  final TextEditingController sermonSpeakerController = TextEditingController();

  List<Map<String, dynamic>>? selectedDevotionScripture;
  List<Map<String, dynamic>>? selectedSermonScripture;

  @override
  void initState() {
    super.initState();
    setState(() {
      showbuildMainServiceSection = true;
    });
  }

  // Helper Method for Buttons
  ElevatedButton elevatedB(String label, VoidCallback method) {
    return ElevatedButton(
      onPressed: isUploading ? null : method,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
      child: isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label),
    );
  }

  // Error Handling
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // HTTP Response Handling
  Future<void> _handleHttpResponse(
      http.Response response, String successMsg, VoidCallback onSuccess) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _showSnackBar(successMsg);
      onSuccess(); // Move to the next section
    } else {
      _showSnackBar(
          'Error: ${json.decode(response.body)['message'] ?? response.reasonPhrase}');
    }
  }

  void showImageUploadSection() {
    setState(() {
      showbuildMainServiceSection = false;
      showbuildImageUploadSection = true;
    });
  }

  void showSermonSection() {
    setState(() {
      showbuildImageUploadSection = false;
      showbuildSermonSection = true;
    });
  }

  void showDevotionSection() {
    setState(() {
      showbuildSermonSection = false;
      showbuildDevotionSection = true;
    });
  }

  void showServicesSection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ServicesScreen()),
    );
  }

  void markProcessComplete() {
    setState(() {
      showbuildDevotionSection = false;
      done = true;
    });
  }

  // Image Upload Logic
  Future<void> uploadImages() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }
    setState(() => isUploading = true);
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if (result != null) {
      for (var file in result.files) {
        Uint8List fileBytes =
            file.bytes ?? await File(file.path!).readAsBytes();
        final request =
            http.MultipartRequest('POST', Uri.parse(ApiConstants.uploadImage))
              ..headers['Authorization'] =
                  'Bearer $token' // Add authorization header
              ..files.add(http.MultipartFile.fromBytes(
                'file',
                fileBytes,
                filename: serviceTitle,
              ));

        final response = await request.send();
        if (response.statusCode == 201) {
          final responseData =
              json.decode(await response.stream.bytesToString());
          print('\nimage response ${responseData}\n');
          setState(() {
            imageIds.add(responseData['_id']);
            uploadedImages.add(fileBytes);
          });
          _showSnackBar('Image uploaded: ${responseData['name']}');
        } else {
          _showSnackBar('Image upload failed: ${response.reasonPhrase}');
        }
      }
    } else {
      _showSnackBar('No files selected');
    }
    setState(() => isUploading = false);
  }

  // Reset Form State
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
      sermonPoints.clear();
      selectedDevotionScripture = null;
      selectedSermonScripture = null;
      ScripturePicker(onScripturesSelected: (scripture) {
        setState(() => scripture.clear());
      });
    });
  }

  // Submit Service and Retrieve ID
  Future<void> submitService() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }
    if (_formKey.currentState!.validate() && date != null) {
      final serviceData = {
        'title': title,
        'date': date!.toIso8601String(),
        'location': location,
        'theme': theme,
      };

      try {
        final response = await http.post(
          Uri.parse(ApiConstants.uploadService),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(serviceData),
        );
        final data = json.decode(response.body);
        setState(() {
          serviceId = data['serviceId'];
          serviceTitle = data['title'];
        }); // Capture the service ID.
        await _handleHttpResponse(
          response,
          'Service created successfully!',
          showImageUploadSection, // Move to the next section
        );
      } catch (error) {
        _showSnackBar('An error occurred: $error');
      }
    } else if (date == null) {
      _showSnackBar('Please set the Date ');
    }
  }

  // Submit Sermon
  Future<void> submitSermon() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }
    if (serviceId == null) {
      _showSnackBar('Service must be created first!');
      return;
    }

    final sermonData = {
      'title': sermonTitleController.text,
      'speaker': sermonSpeakerController.text,
      'notes': sermonPoints,
      'scriptures': selectedSermonScripture ?? [],
    };
    print("sermondata $sermonData");
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.uploadSermon}/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(sermonData),
      );
      await _handleHttpResponse(
        response,
        'Sermon saved successfully!',
        showDevotionSection, // Move to devotion section
      );
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  // Save Devotions
  Future<void> saveDevotions() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }
    if (devotionTitleController.text.isNotEmpty ||
        devotionContentController.text.isNotEmpty) {
      addDevotion();
    }
    if (serviceId == null) {
      _showSnackBar('Service must be created first!');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.uploadDevotions}/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(devotions),
      );
      await _handleHttpResponse(
        response,
        'Devotions saved successfully!',
        showServicesSection, // Move to devotion section
      );
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  Future<void> saveImages() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }
    if (serviceId == null) {
      _showSnackBar('Service must be created first!');
      return;
    }
    print('image ids: ${imageIds.toString()}');
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.saveImages}/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(imageIds),
      );
      await _handleHttpResponse(
        response,
        'Images saved successfully!',
        showSermonSection, // Move to sermon section
      );
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  // Add Devotion to List
  void addDevotion() {
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
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to ServicesScreen if done is true
    if (done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Service creation complete!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ServicesScreen()),
        );
      });
    }
    return BaseScaffold(
      title: 'Create Service',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (showbuildMainServiceSection)
                _buildMainServiceSection()
              else
                ListTile(
                  title: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    theme,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  leading: Icon(
                    Icons.event_note_rounded,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              if (showbuildImageUploadSection) _buildImageUploadSection(),
              if (showbuildSermonSection) _buildSermonSection(),
              if (showbuildDevotionSection) _buildDevotionSection(),
              if (done) Center(child: Text('Service creation complete!')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTextField('Title', (value) => title = value),
        _buildTextField('Location', (value) => location = value),
        _buildTextField('Theme', (value) => theme = value),
        _buildDatePicker(),
        elevatedB('Create Service', submitService),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      style: Theme.of(context).textTheme.bodyMedium,
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
      child: Text(
        date == null ? 'Select Date' : DateFormat('yyyy-MMM-dd').format(date!),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Upload relevant Images',
            style: TextStyle(fontSize: 20),
          ),
          const Divider(),
          Text('Uploaded Images: ${imageIds.length}'),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 2.0,
              childAspectRatio: 1,
            ),
            itemCount: uploadedImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () => _deleteImage(index),
                onTap: () => _showSnackBar("Long press to remove image"),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      uploadedImages[index],
                      fit: BoxFit
                          .cover, // Makes sure images fill the space nicely
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              elevatedB('Upload Images', uploadImages),
              elevatedB('Save Images', saveImages),
            ],
          ),
        ],
      ),
    );
  }

// Delete an image by index
  void _deleteImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);
      imageIds.removeAt(index);
    });
  }

  Widget _buildSermonSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: sermonTitleController,
              decoration: InputDecoration(
                labelText: 'Sermon Title',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: sermonSpeakerController,
              decoration: InputDecoration(
                labelText: 'Speaker',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 10),
            _buildSermonPointsEditor(),
            SizedBox(height: 10),
            ScripturePicker(
              onScripturesSelected: (scripture) {
                setState(() => selectedSermonScripture = scripture);
              },
            ),
            SizedBox(height: 10),
            elevatedB('Save Sermon', submitSermon),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonPointsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sermon Notes',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200), // Limit ListView height
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sermonPoints.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.local_print_shop_rounded,
                    color: Theme.of(context).textTheme.bodyMedium!.color),
                title: Text(sermonPoints[index],
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).textTheme.bodyMedium!.color),
                  onPressed: () {
                    setState(() {
                      sermonPoints.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pointController,
                decoration: InputDecoration(
                  labelText: 'Sermon points...',
                  hintText: 'Enter detailed notes for the sermon...',
                  alignLabelWithHint: true,
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  border:
                      OutlineInputBorder(), // Adds a border for better visibility
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0), // Increases padding for comfort
                ),
                onSubmitted: (_) => _addPoint(), // Add on 'Enter'
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
              onPressed: _addPoint, // Call the function to add point
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  void _addPoint() {
    if (_pointController.text.trim().isNotEmpty) {
      setState(() {
        sermonPoints.add(_pointController.text.trim());
        _pointController.clear();
      });
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    }
  }

  Widget _buildDevotionSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Devotional messages",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 20)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devotions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devotions[index]['title'],
                      style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Text(devotions[index]['content'],
                      style: Theme.of(context).textTheme.bodyMedium),
                  leading: Icon(
                    Icons.note_alt_rounded,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                    onPressed: () {
                      setState(() => devotions.removeAt(index));
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: devotionTitleController,
              decoration: InputDecoration(
                labelText: 'Devotion Title',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 10),
            _buildExpandableMultilineField(),
            SizedBox(height: 10),
            ScripturePicker(onScripturesSelected: (scripture) {
              setState(() => selectedDevotionScripture = scripture);
            }),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                elevatedB('Add Devotion', addDevotion),
                elevatedB('Save Devotions', saveDevotions),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMultilineField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 150, // Prevent unlimited growth
      ),
      child: TextField(
        controller: devotionContentController,
        maxLines: null, // Makes the field expandable
        keyboardType: TextInputType.multiline,
        textInputAction:
            TextInputAction.newline, // Ensures 'Enter' creates new line
        decoration: InputDecoration(
          labelText: 'Devotion Content',
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          border: OutlineInputBorder(),
          alignLabelWithHint: true, // Aligns the label with multiline input
        ),
      ),
    );
  }
}
