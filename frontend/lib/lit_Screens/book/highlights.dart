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

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  _HighlightsScreenState createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  List<Map<String, dynamic>> _highlights = [];
  bool first = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() => first = true);
  }

  String getBookName(int bookNumber) {
    const books = Lists.books;
    return books[bookNumber];
  }

  /// Fetch all verses for a scripture entry (handles multiple verse numbers).
  Future<String> fetchVerses(
      int bookNo, int chapter, List<int> verseNumbers) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bibledb.db');
    final db = await openDatabase(path);

    final placeholders = List.filled(verseNumbers.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT verse FROM bible WHERE Book = ? AND Chapter = ? AND VerseCount IN ($placeholders)',
      [bookNo, chapter, ...verseNumbers],
    );
    String verses = '';

    // Loop through the verse numbers and corresponding results
    for (int i = 0; i < verseNumbers.length; i++) {
      final verseNumber = verseNumbers[i];
      final verseText = result[i]['verse'].toString(); // Get the verse text
      verses +=
          '$verseNumber   "$verseText"\n'; // Prepend verse number and add a newline
    }

    return verses.trim();
  }

  Future<void> fetchHighlights(BuildContext context) async {
    try {
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      var url = Uri.parse(ApiConstants.highlightsEndpoint);

      setState(() => _isLoading = true);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> highlightsData = json.decode(response.body);
        // print(highlightsData);
        List<Map<String, dynamic>> highlightsWithVerses = [];

        for (var highlight in highlightsData) {
          String combinedVerses = '';

          // Fetch all scripture entries for the highlight.
          for (var scripture in highlight['scripture']) {
            int book = scripture['book'];
            int chapter = scripture['chapter'];
            List<int> verseNumbers = List<int>.from(scripture['verseNumbers']);

            // Fetch and concatenate the verses.
            String verses = await fetchVerses(book, chapter, verseNumbers);
            combinedVerses +=
                '${getBookName(book)} $chapter:${verseNumbers.join(", ")}\n$verses\n\n';
          }

          highlightsWithVerses.add({
            'highlight': highlight as Map<String, dynamic>,
            'verseText': combinedVerses.trim(),
          });
        }

        setState(() => _highlights = highlightsWithVerses);
      } else {
        print('Failed to load highlights');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'pink':
        return const Color.fromARGB(99, 247, 81, 81);
      case 'yellow':
        return const Color.fromARGB(100, 255, 235, 59);
      case 'blue':
        return const Color.fromARGB(100, 33, 149, 243);
      case 'green':
        return const Color.fromARGB(100, 76, 175, 79);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/error.json', height: 200),
          const SizedBox(height: 20),
          const Text('No highlights found.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (first) {
      fetchHighlights(context);
      setState(() => first = false);
    }

    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.6),
      title: "Highlights",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _highlights.isEmpty
              ? _buildErrorState()
              : ListView.builder(
                  itemCount: _highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = _highlights[index]['highlight'];
                    final verseText = _highlights[index]['verseText'];
                    final color = _getColorFromName(highlight['color']);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        verseText,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
    );
  }
}
