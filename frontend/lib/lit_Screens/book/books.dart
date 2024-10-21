import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:frontend/lit_Screens/book/chapters.dart'; // Screen for displaying chapters
import 'package:frontend/db_helper.dart'; // Database function location

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late Future<List<int>> booksFuture;

  @override
  void initState() {
    super.initState();
    booksFuture = DBHelper.fetchBooks(); // Fetch books from the database
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    Color background = isDarkMode
        ? Colors.black.withOpacity(0.8)
        : Colors.black.withOpacity(0.6);
    return BaseScaffold(
      title: 'Books',
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: background),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0), // Add padding for better UI
            child: FutureBuilder<List<int>>(
              future: booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No books found.'));
                } else {
                  final books = snapshot.data!;

                  // Ensure list is scrollable by using SingleChildScrollView
                  return SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap:
                          true, // Allow the ListView to shrink based on content
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable internal scroll, managed by SingleChildScrollView
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final bookNumber = books[index];
                        final bookName =
                            getBookName(bookNumber); // A helper function

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          title: Text(bookName,
                              style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChaptersScreen(bookNumber: bookNumber),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

String getBookName(int bookNumber) {
  const books = Lists.books;
  return books[bookNumber];
}
