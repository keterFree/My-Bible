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

  Future<void> fetchHighlights(BuildContext context) async {
    try {
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      var url = Uri.parse(ApiConstants.highlightsEndpoint);

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
        List<dynamic> highlightsData = json.decode(response.body);
        List<Map<String, dynamic>> highlightsWithVerses = [];

        for (var highlight in highlightsData) {
          final verseData = await fetchVerse(
              highlight['book'], highlight['chapter'], highlight['verse']);
          highlightsWithVerses.add({
            'highlight': highlight as Map<String, dynamic>,
            'verseText': verseData['verse'],
          });
        }

        setState(() {
          _highlights = highlightsWithVerses;
        });
      } else {
        print('Failed to load highlights');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<Map<String, dynamic>> fetchVerse(
      int bookNo, int chapter, int verse) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bibledb.db');
    final db = await openDatabase(path);
    final verses = await db.rawQuery(
      'SELECT Versecount, verse FROM bible WHERE Book = ? AND Chapter = ? AND VerseCount = ?',
      [bookNo, chapter, verse],
    );
    return verses.isNotEmpty ? verses.first : {};
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
      setState(() {
        first = false;
      });
    }
    return BaseScaffold(
      title: "Highlights",
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : _highlights.isEmpty
              ? Center(child: _buildErrorState())
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
                        '${getBookName(highlight['book'])} ${highlight['chapter']}: ${highlight['verse']}\n\n$verseText',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
    );
  }
}
