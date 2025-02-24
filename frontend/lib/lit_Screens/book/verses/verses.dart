import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/book/books.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class VersesScreen extends StatefulWidget {
  final int bookNo;
  final int chapter;

  const VersesScreen({super.key, required this.bookNo, required this.chapter});

  @override
  _VersesScreenState createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  late Future<List<Map<String, dynamic>>> versesFuture;
  late int currentChapter;
  late PageController _pageController;
  int totalChapters = 0;
  late Logger _logger;
  bool isLoading = false;
  Set<int> selectedVerses = {}; // Track selected verses

  @override
  void initState() {
    super.initState();
    currentChapter = widget.chapter;
    _logger = Logger();
    _pageController = PageController(initialPage: currentChapter - 1);
    fetchTotalChapters(widget.bookNo).then((chapters) {
      setState(() {
        totalChapters = chapters;
      });
    });
    versesFuture = fetchVerses(widget.bookNo, currentChapter);
  }

  void _toggleVerseSelection(int verse) {
    setState(() {
      if (selectedVerses.contains(verse)) {
        selectedVerses.remove(verse);
      } else {
        selectedVerses.add(verse);
      }
    });
  }

  Future<void> _loadVerses(int chapter) async {
    setState(() {
      currentChapter = chapter;
      selectedVerses.clear(); // Clear selection when chapter changes
      versesFuture = fetchVerses(widget.bookNo, currentChapter);
    });
  }

  Future<void> _bookmarkSelectedVerses(
      String token, String note, BuildContext context) async {
    var url = Uri.parse(ApiConstants.bookMarkEndpoint);

    try {
      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'book': widget.bookNo,
          'chapter': currentChapter,
          'verseNumbers': selectedVerses.toList(), // Convert Set to List
          'note': note, // Include the user’s note
        }),
      );

      if (response.statusCode == 200 && mounted) {
        _logger.i('Verses bookmarked successfully');
      } else if (mounted) {
        _logger.e('Failed to bookmark verses');
      }
    } catch (e) {
      _logger.e('Error: $e');
    }

    selectedVerses.clear();
    setState(() {}); // Update UI
  }

  Future<void> _showNoteInputDialog(BuildContext context, String token) async {
    TextEditingController noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add a Note',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
                hintText: "Enter your note here",
                hintStyle: Theme.of(context).textTheme.bodySmall),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                // Add any default style properties here
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0), // example padding
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _bookmarkSelectedVerses(token, noteController.text,
                    context); // Call the bookmark method with the note
              },
              child: const Text('Save Bookmark'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel without saving
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showOptions(BuildContext context, token) {
    showModalBottomSheet(
      backgroundColor: Colors.white.withOpacity(0.8),
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              textColor: Theme.of(context).colorScheme.secondary,
              leading: Icon(Icons.highlight,
                  color: Theme.of(context).iconTheme.color),
              title: const Text('Highlight'),
              onTap: () {
                Navigator.pop(context);
                _showColorPicker(context, token);
              },
            ),
            ListTile(
              textColor: Theme.of(context).colorScheme.secondary,
              leading: Icon(Icons.bookmark,
                  color: Theme.of(context).iconTheme.color),
              title: const Text('Bookmark'),
              onTap: () => _showNoteInputDialog(
                context,
                token,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, token) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (isLoading) {
          return const CircularProgressIndicator(); // or disable the button
        } else {
          return Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens,
                    color: Color.fromARGB(100, 255, 235, 59)),
                title: const Text('Yellow'),
                onTap: () {
                  _highlightSelectedVerses(token, 'yellow', context);
                  Navigator.pop(context); // Close the color picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens,
                    color: Color.fromARGB(100, 76, 175, 79)),
                title: const Text('Green'),
                onTap: () {
                  _highlightSelectedVerses(token, 'green', context);
                  Navigator.pop(context); // Close the color picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens,
                    color: Color.fromARGB(100, 233, 30, 98)),
                title: const Text('Pink'),
                onTap: () {
                  _highlightSelectedVerses(token, 'pink', context);
                  Navigator.pop(context); // Close the color picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens,
                    color: Color.fromARGB(100, 33, 149, 243)),
                title: const Text('Blue'),
                onTap: () {
                  _highlightSelectedVerses(token, 'blue', context);
                  Navigator.pop(context); // Close the color picker
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _highlightSelectedVerses(
      String token, String color, BuildContext context) async {
    if (isLoading) return; // Prevent multiple simultaneous requests
    setState(() {
      isLoading = true;
    });

    var url = Uri.parse(ApiConstants.highlightsEndpoint);

    try {
      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'book': widget.bookNo,
          'chapter': currentChapter,
          'verseNumbers': selectedVerses.toList(), // Send verses as an array
          'color': color, // Use the chosen color
        }),
      );

      if (response.statusCode == 200 && mounted) {
        _logger.i('Verses highlighted successfully');
      } else if (mounted) {
        _logger.e('Failed to highlight verses');
      }
    } catch (e) {
      _logger.e('Error: $e');
    }

    selectedVerses.clear();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<TokenProvider>(context, listen: false)
        .token; // Get the token from Provider
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.8),
      title: '${getBookName(widget.bookNo)} $currentChapter',
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (pageIndex) async {
              if (pageIndex == currentChapter &&
                  currentChapter < totalChapters) {
                await _loadVerses(currentChapter + 1);
              } else if (pageIndex < currentChapter && currentChapter > 1) {
                await _loadVerses(currentChapter - 1);
              }
            },
            itemBuilder: (context, index) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: versesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No verses found.'));
                  } else {
                    final verses = snapshot.data!;
                    return ListView.builder(
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        final verseNumber =
                            verses[index]['Versecount'] as int? ?? 10001;
                        final text = verses[index]['verse'] as String? ??
                            "No text available";
                        final isSelected = selectedVerses.contains(verseNumber);

                        return ListTile(
                          textColor:
                              Theme.of(context).textTheme.bodyLarge!.color,
                          leading: Text('$verseNumber'),
                          title: Text(text),
                          selected: isSelected,
                          selectedTileColor:
                              const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(0.6),
                          // const Color.fromARGB(88, 255, 240, 107),
                          onTap: () => _toggleVerseSelection(verseNumber),
                        );
                      },
                    );
                  }
                },
              );
            },
          ),
          if (selectedVerses.isNotEmpty)
            Positioned(
              bottom: 80,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                onPressed: () =>
                    _showOptions(context, token), // Correct function reference
                child: const Icon(Icons.brightness_high_outlined),
              ),
            ),
        ],
      ),
    );
  }
}

Future<int> fetchTotalChapters(int bookNo) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bibledb.db');

  final db = await openDatabase(path);
  final result = await db.rawQuery(
    'SELECT COUNT(DISTINCT Chapter) as chapterCount FROM bible WHERE Book = ?',
    [bookNo],
  );

  return result.isNotEmpty ? result.first['chapterCount'] as int : 0;
}

Map<int, List<Map<String, dynamic>>> cachedVerses = {};

Future<List<Map<String, dynamic>>> fetchVerses(int bookNo, int chapter) async {
  if (cachedVerses.containsKey(chapter)) {
    return cachedVerses[chapter]!;
  }
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bibledb.db');
  final db = await openDatabase(path);
  final verses = await db.rawQuery(
    'SELECT Versecount, verse FROM bible WHERE Book = ? AND Chapter = ?',
    [bookNo, chapter],
  );
  cachedVerses[chapter] = verses;
  return verses;
}
