import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/repository/scripture_picker.dart';
import 'package:frontend/repository/show_services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Edit Service Screen that displays a specific section based on edit_no
class EditServiceScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final int editNo;

  const EditServiceScreen(
      {super.key,
      required this.serviceTitle,
      required this.serviceId,
      required this.editNo});

  @override
  _EditServiceScreenState createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String title = '', location = '', theme = '';
  DateTime? date;
  String? serviceTitle;
  String? serviceId;

  String? sermonTitle;
  String? sermonSpeaker;
  String? sermonId;

  Map? currentDevotion;

  bool isUploading = false;
  bool isLoading = true;

  bool showbuildMainServiceSection = false;
  bool showbuildImageUploadSection = false;
  bool showbuildSermonSection = false;
  bool showbuildDevotionSection = false;
  bool done = false;
  List sermonPoints = [];
  List devotions = [];

  // Controllers and Lists
  List<String> imageIds = [];
  List<Uint8List> uploadedImages = [];
  final TextEditingController _pointController = TextEditingController();
  TextEditingController devotionTitleController = TextEditingController();
  TextEditingController devotionContentController = TextEditingController();
  final TextEditingController sermonTitleController = TextEditingController();
  final TextEditingController sermonSpeakerController = TextEditingController();

  List<Map<String, dynamic>>? selectedDevotionScripture;
  List<Map<String, dynamic>>? selectedSermonScripture;

  @override
  void initState() {
    super.initState();
    serviceId = widget.serviceId;
    serviceTitle = widget.serviceTitle;
    print('serviceTitle: $serviceTitle');
    _fetchServiceData();
    showSection();
  }

  void _fetchServiceData() async {
    // This function should fetch the service data based on widget.serviceId
    // Assuming fetchServiceData is an async function that returns service details
    final serviceData = await fetchServiceById(widget.serviceId);
    print(widget.editNo);
    // Populate fields according to editNo
    if (widget.editNo == 1) {
      print(serviceData['date']);
      setState(() {
        title = serviceData['title'];
        date = DateTime.parse(serviceData['date']);
        location = serviceData['location'];
        theme = serviceData['themes'][0];
      });
    } else if (widget.editNo == 2) {
      setState(() {
        isLoading = true;
        imageIds = (serviceData['images'] as List)
            .map((image) => image['_id'] as String)
            .toList();
        uploadedImages = (serviceData['images'] as List)
            .map((image) => base64.decode(image['imageData'] as String))
            .toList();
        isLoading = false;
      });
    } else if (widget.editNo == 3) {
      print(serviceData['sermons']);
      final sermon = serviceData['sermons'][0];
      setState(() {
        sermonTitle = sermon['title'];
        sermonSpeaker = sermon['speaker'];
        sermonPoints = sermon['notes'];
        sermonId = sermon['_id'];
        if (sermon['scriptures'] is List) {
          selectedSermonScripture = (sermon['scriptures'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          print('selectedSermonScripture:  $selectedSermonScripture');
        } else {
          selectedSermonScripture =
              null; // Handle the case when it's not a List
        }
      });
    } else if (widget.editNo == 4) {
      setState(() {
        devotions = serviceData['devotions'];
      });
    }

    setState(() {
      isLoading = false; // Data loaded, hide loading spinner
    });
  }

  Future<Map<String, dynamic>> fetchServiceById(String id) async {
    final String url = '${ApiConstants.services}/$id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load service details');
    }
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
      print(
          'Error: ${json.decode(response.body)['message'] ?? response.reasonPhrase}');
    }
  }

  void showSection() {
    print(widget.editNo);
    if (widget.editNo == 1) {
      setState(() {
        showbuildMainServiceSection = true;
      });
    } else if (widget.editNo == 2) {
      setState(() {
        showbuildImageUploadSection = true;
      });
    } else if (widget.editNo == 3) {
      setState(() {
        showbuildSermonSection = true;
      });
    } else if (widget.editNo == 4) {
      setState(() {
        showbuildDevotionSection = true;
      });
    }
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
        // print('fileBytes: $fileBytes');
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
        final response = await http.put(
          Uri.parse('${ApiConstants.uploadService}/$serviceId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(serviceData),
        );
        final data = json.decode(response.body);
        setState(() {
          serviceTitle = data['title'];
        }); // Capture the service ID.
        await _handleHttpResponse(response, 'Service edited successfully!',
            () => Navigator.of(context).pop());
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
      'title': sermonTitleController.text.isEmpty
          ? sermonTitle
          : sermonTitleController.text,
      'speaker': sermonSpeakerController.text.isEmpty
          ? sermonSpeaker
          : sermonSpeakerController.text,
      'notes': sermonPoints,
      'scriptures': selectedSermonScripture ?? [],
    };
    print("sermondata $sermonData");
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.sermons}/$sermonId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(sermonData),
      );
      await _handleHttpResponse(
        response,
        'Sermon saved successfully!',
        () => Navigator.of(context).pop(),
      );
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  // Save Devotions
  Future<void> addDevotion() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }

    if (serviceId == null) {
      _showSnackBar('Service must be created first!');
      return;
    }
    final devotionData = [
      {
        'title': devotionTitleController.text,
        'content': devotionContentController.text,
        'scriptures': selectedDevotionScripture ?? [],
      }
    ];
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.uploadDevotions}/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(devotionData),
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

  Future<void> saveDevotion() async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackBar("Token not found or expired, try loggin in.");
      return;
    }

    if (serviceId == null) {
      _showSnackBar('Service must be created first!');
      return;
    }
    final devotionData = {
      'title': devotionContentController.text.isEmpty
          ? currentDevotion!['title']
          : devotionTitleController.text,
      'content': devotionContentController.text.isEmpty
          ? currentDevotion!['content']
          : devotionContentController.text,
      'scriptures': selectedDevotionScripture == null
          ? currentDevotion!['scriptures']
          : currentDevotion!['scriptures'] + selectedDevotionScripture,
    };

    print('devotionData $devotionData\n from: $currentDevotion');
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.devotions}/${currentDevotion!["_id"]}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(devotionData),
      );
      await _handleHttpResponse(
          response,
          'Devotions saved successfully!',
          () => setState(() {
                currentDevotion = null;
              }));
    } catch (error) {
      _showSnackBar('An error occurred: $error');
      print('An error occurred: $error');
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
        () => Navigator.of(context).pop(), // Move to sermon section
      );
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  String getTitle() {
    if (widget.editNo == 1) {
      return 'Edit Service Details';
    } else if (widget.editNo == 2) {
      return 'Edit Images';
    } else if (widget.editNo == 3) {
      return 'Edit Sermon Details';
    } else if (widget.editNo == 4) {
      return 'Edit Devotions';
    } else {
      return 'Default Title';
    }
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
      title: getTitle(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (showbuildMainServiceSection) _buildMainServiceSection(),
              if (showbuildImageUploadSection) _buildImageUploadSection(),
              if (showbuildSermonSection) _buildSermonSection(),
              if (showbuildDevotionSection) _buildDevotionSection(),
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
        _buildTextField(
            title.isEmpty ? 'Title' : title, (value) => title = value),
        _buildTextField(location.isEmpty ? 'Location' : location,
            (value) => location = value),
        _buildTextField(
            theme.isEmpty ? 'Theme' : theme, (value) => theme = value),
        _buildDatePicker(),
        elevatedB('Save Changes', submitService),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
          labelText: label, labelStyle: Theme.of(context).textTheme.bodyMedium),
      onChanged: onChanged,
      // validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
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
          Text('Long press to remove uploaded Images'),
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
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
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
                labelText: sermonTitle ?? 'Sermon Title',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: sermonSpeakerController,
              decoration: InputDecoration(
                labelText: sermonSpeaker ?? 'Speaker',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 10),
            _buildSermonPointsEditor(),
            SizedBox(height: 10),
            ScripturePicker(
              onScripturesSelected: (scripture) {
                print(
                    'selectedSermonScripture: $selectedSermonScripture => scripture: $scripture');
                setState(() => selectedSermonScripture =
                    selectedSermonScripture == null
                        ? scripture
                        : selectedSermonScripture! + scripture);
                print('selectedSermonScripture : $selectedSermonScripture');
              },
            ),
            SizedBox(height: 10),
            elevatedB('Save Changes', submitSermon),
            SizedBox(height: 50),
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
            currentDevotion == null ? devotionsList() : devotionDetails(),
          ],
        ),
      ),
    );
  }

  Column devotionsList() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devotions.length,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                setState(() {
                  currentDevotion = devotions[index];
                });
              },
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
        // addDevotion
        elevatedB('Add Devotion', () {
          setState(() {
            currentDevotion = {"title": "", "content": "", "scriptures": []};
          });
        }),
      ],
    );
  }

//title
// content
// scriptures
  Column devotionDetails() {
    setState(() {
      devotionContentController = TextEditingController(
        text: currentDevotion!['content'],
      );
      devotionTitleController = TextEditingController(
        text: currentDevotion!['title'],
      );
    });
    return Column(
      children: [
        TextFormField(
          controller: devotionTitleController,
          // initialValue:currentDevotion!['title'],
          decoration: InputDecoration(
            labelText:
                currentDevotion == null || currentDevotion!['title'].isEmpty
                    ? 'Devotion Title'
                    : currentDevotion!['title'],
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            elevatedB(
                currentDevotion!['_id'] == null
                    ? 'Save Devotion'
                    : 'Save Changes',
                currentDevotion!['_id'] == null ? addDevotion : saveDevotion),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableMultilineField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 200, // Prevent unlimited growth
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
