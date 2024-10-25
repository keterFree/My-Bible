import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  var _groupedBookmarks = {};
  bool first = false;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    setState(() {
      first = true;
    });
  }

  String getBookName(int bookNumber) {
    const books = Lists.books;
    return books[bookNumber];
  }

  Future<void> fetchBookmarks(BuildContext context) async {
    try {
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      var url = Uri.parse(ApiConstants.bookMarkEndpoint);
      setState(() => _isLoading = true);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List bookmarksData = json.decode(response.body);

        for (var bookmark in bookmarksData) {
          List scriptures = bookmark['scripture'];
          String fullText = '';

          // Fetch all verses for each scripture entry
          for (var scripture in scriptures) {
            int book = scripture['book'];
            int chapter = scripture['chapter'];
            List<int> verseNumbers = List<int>.from(scripture['verseNumbers']);

            // Append fetched verses to fullText
            String verses = await fetchVerses(book, chapter, verseNumbers);
            fullText +=
                '${getBookName(book)} $chapter:${verseNumbers.join(", ")}\n$verses\n\n';
          }

          // Store the combined text in the bookmark
          bookmark['text'] = fullText.trim();
        }

        var groupedData =
            groupBy(bookmarksData, (bookmark) => bookmark['note']);

        groupedData.forEach((note, bookmarks) {
          bookmarks.sort((a, b) {
            if (a['scripture'][0]['book'] != b['scripture'][0]['book']) {
              return a['scripture'][0]['book']
                  .compareTo(b['scripture'][0]['book']);
            } else if (a['scripture'][0]['chapter'] !=
                b['scripture'][0]['chapter']) {
              return a['scripture'][0]['chapter']
                  .compareTo(b['scripture'][0]['chapter']);
            } else {
              return a['scripture'][0]['verseNumbers'][0]
                  .compareTo(b['scripture'][0]['verseNumbers'][0]);
            }
          });
        });

        setState(() => _groupedBookmarks = groupedData);
      } else {
        print('Failed to load bookmarks');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> fetchVerses(
      int bookNo, int chapter, List<int> verseNumbers) async {
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/error.json', height: 200),
          const SizedBox(height: 20),
          const Text('No bookmarks found.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (first) {
      fetchBookmarks(context);
      setState(() {
        first = false;
      });
    }
    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.8),
      title: "Bookmarks",
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
            : _groupedBookmarks.isEmpty
                ? Center(child: _buildErrorState())
                : ListView.builder(
                    itemCount: _groupedBookmarks.keys.length,
                    itemBuilder: (context, index) {
                      String note = _groupedBookmarks.keys.elementAt(index);
                      List<dynamic> bookmarks = _groupedBookmarks[note]!;

                      return ExpansionTile(
                        iconColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        collapsedBackgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        collapsedIconColor: Theme.of(context)
                            .appBarTheme
                            .titleTextStyle!
                            .color!
                            .withOpacity(0.9),
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        leading: const Icon(Icons.library_books),
                        title: Text(
                          note.isNotEmpty ? note : 'No Note',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        children: bookmarks.map((bookmark) {
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            title: Text(
                              bookmark['text'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            // leading: Icon(
                            //   Icons.bookmark,
                            //   color: Theme.of(context).colorScheme.secondary,
                            // ),
                          );
                        }).toList(),
                      );
                    },
                  ),
      ),
    );
  }
}
