import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/repository/edit_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting dates
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io'; // For File
import 'package:path_provider/path_provider.dart'; // For saving images

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late Future<Map<String, dynamic>> _futureService;
  int _currentPage = 0;
  List allImages = [];

  @override
  void initState() {
    super.initState();
    _futureService = fetchServiceById(widget.serviceId);
  }

  @override
  void dispose() {
    super.dispose();
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

  Uint8List _decodeImageBytes(Map<String, dynamic> imageData) {
    return base64Decode(imageData['imageData']);
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      print("Token not found or expired, try loggin in.");
    }

    return BaseScaffold(
      title: 'Service Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureService,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No service details found'));
          }

          final service = snapshot.data!;
          allImages = service['images'];
          return Stack(
            children: [
              _buildGradientOverlay(),
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    service['title'],
                    style: GoogleFonts.lato(
                      textStyle:
                          Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDate(service['date'], context),
                  Text(service['location'], style: _textStyle(context)),
                  const SizedBox(height: 16),
                  _buildThemes(service['themes'], context),
                  const SizedBox(height: 20),
                  _buildImageGallery(allImages, context),
                  const SizedBox(height: 20),
                  _buildSermonList(service['sermons'], context),
                  const SizedBox(height: 20),
                  _buildDevotionList(service['devotions'], context),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDevotionList(List<dynamic> devotions, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Devotions:',
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                )),
            IconButton(
              icon: Icon(Icons.edit_note_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditServiceScreen(
                      serviceId: widget.serviceId,
                      editNo: 4,
                    ), // Create this screen
                  ),
                );
              },
            )
          ],
        ),
        ...devotions.map((devotion) => FutureBuilder<String>(
              future: _fetchScriptures(devotion['scriptures']),
              builder: (context, snapshot) {
                return ListTile(
                  title: Text(devotion['title'].toUpperCase(),
                      style: GoogleFonts.roboto(
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                      )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(devotion['content'], style: _textStyle(context)),
                      SizedBox(height: 10),
                      if (snapshot.hasData)
                        Text(
                          snapshot.data!,
                          textAlign: TextAlign.justify,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                );
              },
            )),
      ],
    );
  }

  Widget _buildSermonList(List<dynamic> sermons, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sermon:',
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                )),
            IconButton(
              icon: Icon(Icons.edit_note_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditServiceScreen(
                      serviceId: widget.serviceId,
                      editNo: 3,
                    ), // Create this screen
                  ),
                );
              },
            )
          ],
        ),
        ...sermons.map((sermon) => FutureBuilder<String>(
              future: _fetchScriptures(sermon['scriptures']),
              builder: (context, snapshot) {
                // print(snapshot);
                return ListTile(
                  title: Text(sermon['title'].toUpperCase(),
                      style: GoogleFonts.roboto(
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                      )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: ${sermon['speaker']}',
                          style: _textStyle(context)),
                      if (snapshot.hasData)
                        Text(
                          snapshot.data!,
                          textAlign: TextAlign.justify,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 8),
                      ...sermon['notes']
                          .map((note) => Text(
                                "• $note",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ))
                          .toList(),
                    ],
                  ),
                );
              },
            )),
      ],
    );
  }

  Future<String> _fetchScriptures(List<dynamic> scriptures) async {
    List<String> versesList = [];

    for (var scripture in scriptures) {
      // print('scripture: $scripture');
      final bookName = getBookName(scripture['book']);
      final chapter = scripture['chapter'];
      final verses = await fetchVerses(
          scripture['book'], chapter, scripture['verseNumbers']);
      versesList.add('$bookName $chapter\n $verses');
    }
    return versesList.join('\n');
  }

  Widget _buildDate(String dateString, BuildContext context) {
    final parsedDate = DateTime.parse(dateString);
    final formattedDate =
        DateFormat.yMMMMd().format(parsedDate); // e.g., October 30, 2024

    return Text(
      formattedDate,
      style: GoogleFonts.lato(
        textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic),
      ),
    );
  }

  TextStyle _textStyle(BuildContext context) {
    return GoogleFonts.roboto(
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildThemes(List<dynamic> themes, BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: themes.map((theme) {
        return Text(theme.toUpperCase(),
            style: GoogleFonts.roboto(
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ));
      }).toList(),
    );
  }

  Future<void> _downloadImage(
      Uint8List imageBytes, BuildContext context) async {
    try {
      // Get the Downloads directory
      final directory = await getExternalStorageDirectory();
      final downloadPath = '${directory!.path}/E-Pistle';

      // Create Downloads directory if it doesn't exist
      final downloadDir = Directory(downloadPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Define the file path within the Downloads folder
      final filePath = '$downloadPath/downloaded_image.png';
      final file = File(filePath);

      // Write the file to the Downloads folder
      await file.writeAsBytes(imageBytes);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to Downloads folder')),
      );
    } catch (e) {
      // Handle any errors and notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

// Modify the image builder to open full-screen on tap
  Widget _buildImageGallery(List<dynamic> images, BuildContext context) {
    if (images.isEmpty) {
      return const Center(child: Text('No images available'));
    }

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final Uint8List imageBytes = _decodeImageBytes(images[index]);
              return GestureDetector(
                onTap: () =>
                    _showFullScreenImage(context, imageBytes, images[index]),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => _buildIndicator(index == _currentPage),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, Uint8List imageBytes, image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white, size: 30),
                      onPressed: () async {
                        await _downloadImage(imageBytes, context);
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.delete, color: Colors.redAccent, size: 30),
                      onPressed: () async {
                        await _deleteImage(
                            image['_id'], context); // Call delete function
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteImage(String imageId, BuildContext context) async {
    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Token not found or expired, try loggin in.")),
      );
      return;
    }
    final url =
        '${ApiConstants.images}/$imageId'; // Adjust the endpoint if necessary
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted successfully')),
      );
      setState(() {
        allImages.removeWhere((image) => image['_id'] == imageId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image')),
      );
    }
  }

  // Helper widget for the page indicators
  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 20.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent : Colors.grey,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  String getBookName(int bookNumber) {
    const books = Lists.books;
    return books[bookNumber];
  }

  Future<String> fetchVerses(int bookNo, int chapter, List verseNumbers) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bibledb.db');
    final db = await openDatabase(path);

    // Fetch all verses matching the given numbers
    final placeholders = List.filled(verseNumbers.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT verse FROM bible WHERE Book = ? AND Chapter = ? AND VerseCount IN ($placeholders)',
      [bookNo, chapter, ...verseNumbers],
    );

    // Initialize an empty string to hold the verses
    String verses = '';

    // Loop through the verse numbers and corresponding results
    for (int i = 0; i < verseNumbers.length; i++) {
      final verseNumber = verseNumbers[i];
      final verseText = result[i]['verse'].toString(); // Get the verse text
      verses +=
          '$verseNumber   "$verseText"\n'; // Prepend verse number and add a newline
    }

    return verses.trim(); // Return the verses, trimming any trailing whitespace
  }
}
