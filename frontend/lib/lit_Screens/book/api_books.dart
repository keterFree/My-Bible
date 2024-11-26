import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/book/api_chapters.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lottie/lottie.dart';

class BooksPage extends StatefulWidget {
  final String id;

  const BooksPage({Key? key, required this.id}) : super(key: key);

  @override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late Future<List<dynamic>> _booksFuture;
  String bookTitle = '';

  @override
  void initState() {
    super.initState();
    _booksFuture = _fetchBooks();
  }

  Future<List<dynamic>> _fetchBooks() async {
    final response = await http.get(
      Uri.parse('https://bible.helloao.org/api/${widget.id}/books.json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        bookTitle = data["translation"]["name"];
      });
      return data['books'] ?? [];
    } else {
      throw Exception('Failed to load books');
    }
  }

  void _retryFetchBooks() {
    setState(() {
      _booksFuture = _fetchBooks();
    });
  }

  void _showChaptersBottomSheet(BuildContext context, String bookName,
      int numberOfChapters, String bookId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, // Makes the modal adapt to content size
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8, // Adjusts the maximum height of the bottom sheet
          minChildSize: 0.3, // Adjusts the minimum height
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select a Chapter from $bookName",
                    // style: Theme.of(context).textTheme.headline6,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Prevents nested scrolling conflicts
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: numberOfChapters,
                        itemBuilder: (context, index) {
                          final chapter = index + 1;
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterPage(
                                    bibleId: widget.id,
                                    bookId: bookId,
                                    chapter: chapter,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Center(child: Text("$chapter")),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bookTitle = bookTitle.isEmpty ? widget.id : bookTitle;
    return BaseScaffold(
      title: bookTitle,
      appBarActions: [],
      body: FutureBuilder<List<dynamic>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/images/error.json', height: 200),
                  const SizedBox(height: 20),
                  Text(
                    "Error: There was an error connecting to the server.\nCheck your internet connection and try again",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retryFetchBooks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        Lottie.asset('assets/images/error.json', height: 200),
                        const SizedBox(height: 20),
                        Text(
                          "No books available.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _retryFetchBooks,
                          child: const Text('Retry'),
                        ),
                      ],
              ),
            );
          } else {
            final books = snapshot.data!;
            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: ListTile(
                    tileColor: Colors.black.withOpacity(0.2),
                    title: Text(book['name'],
                        style: Theme.of(context).textTheme.bodyLarge),
                    // subtitle: Text("Chapters: ${book['chapters']}"),
                    onTap: () {
                      _showChaptersBottomSheet(
                        context,
                        book['name'],
                        book["numberOfChapters"],
                        book['id'],
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
