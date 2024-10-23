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
      setState(() {
        _isLoading = true; // Show loading indicator
      });
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List bookmarksData = json.decode(response.body);

        // Wait for all async operations to complete
        for (var bookmark in bookmarksData) {
          bookmark['text'] = await fetchVerse(
              bookmark['book'], bookmark['chapter'], bookmark['verse']);
        }

        // OR (alternative) using Future.forEach
        // await Future.forEach(bookmarksData, (bookmark) async {
        //   bookmark['text'] = await fetchVerse(
        //       bookmark['book'], bookmark['chapter'], bookmark['verse']);
        // });

        var groupedData =
            groupBy(bookmarksData, (bookmark) => bookmark['note']);

        groupedData.forEach((note, bookmarks) {
          bookmarks.sort((a, b) {
            if (a['book'] != b['book']) {
              return a['book'].compareTo(b['book']);
            } else if (a['chapter'] != b['chapter']) {
              return a['chapter'].compareTo(b['chapter']);
            } else {
              return a['verse'].compareTo(b['verse']);
            }
          });
        });

        setState(() {
          _groupedBookmarks = groupedData;
        });
      } else {
        print('Failed to load bookmarks');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<String> fetchVerse(int bookNo, int chapter, int verse) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bibledb.db');
    final db = await openDatabase(path);
    final result = await db.rawQuery(
      'SELECT verse FROM bible WHERE Book = ? AND Chapter = ? AND VerseCount = ?',
      [bookNo, chapter, verse],
    );
    return result[0]['verse'].toString();
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

                      // return ExpansionTile(
                      //   iconColor: Theme.of(context).iconTheme.color,
                      //   title: Text(
                      //     note.isNotEmpty ? note : 'No Note',
                      //     style: Theme.of(context).textTheme.bodyLarge,
                      //   ),
                      //   children: bookmarks.map((bookmark) {
                      //     return ListTile(
                      //       title: Text(
                      //         '${getBookName(bookmark['book'])} ${bookmark['chapter']}:${bookmark['verse']}',
                      //         style: Theme.of(context).textTheme.bodyMedium,
                      //       ),
                      //       subtitle: Text(
                      //         '${bookmark['text']}',
                      //         style: Theme.of(context).textTheme.bodyMedium,
                      //       ),
                      //     );
                      //   }).toList(),
                      // );

                      return ExpansionTile(
                        iconColor: Theme.of(context)
                            .colorScheme
                            .secondary, // Customize the icon color
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(
                                0.3), // Add a light background color for the expanded tile
                        collapsedBackgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(
                                0.3), // Background color when tile is collapsed
                        collapsedIconColor: Theme.of(context)
                            .appBarTheme
                            .titleTextStyle!
                            .color!
                            .withOpacity(0.9),
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0), // Add padding around the tile
                        leading: const Icon(Icons.library_books),
                        title: Text(note.isNotEmpty ? note : 'No Note',
                            style: Theme.of(context).textTheme.bodyLarge),
                        children: bookmarks.map((bookmark) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal:
                                    16.0), // Adjust padding for list items
                            title: Text(
                              '${getBookName(bookmark['book'])} ${bookmark['chapter']}:${bookmark['verse']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight
                                        .bold, // Make the book name and verse bold
                                  ),
                            ),
                            subtitle: Text(
                              bookmark['text'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle
                                        .italic, // Italicize the verse text for better readability
                                  ),
                            ),
                            leading: Icon(
                              Icons
                                  .bookmark, // Add a bookmark icon to each list item
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary, // Match the icon color to the theme
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
      ),
    );
  }
}
