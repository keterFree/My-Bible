import 'package:flutter/material.dart';
import 'package:frontend/screens/baseScaffold.dart';
import 'package:frontend/screens/book/books.dart';
import 'package:frontend/screens/book/verses/verses.dart';
// import 'package:frontend/db_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart'; // Database functions

class ChaptersScreen extends StatefulWidget {
  final int bookNumber;

  const ChaptersScreen({Key? key, required this.bookNumber}) : super(key: key);

  @override
  _ChaptersScreenState createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  late Future<List<Map<String, dynamic>>> chaptersFuture;

  @override
  void initState() {
    super.initState();
    chaptersFuture =
        fetchChapters(widget.bookNumber); // Fetch chapters from the database
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        title: getBookName(widget.bookNumber),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: chaptersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No chapters found.'));
            } else {
              final chapters = snapshot.data!;
              return ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index]['Chapter'] as int;
                  final verseCount = chapters[index]['Versecount'] as int;

                  return ListTile(
                    textColor: Theme.of(context).textTheme.bodyLarge!.color,
                    title: Text('Chapter $chapter'),
                    trailing: Text('$verseCount'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VersesScreen(
                            bookNo: widget.bookNumber,
                            chapter: chapter,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
        ));
  }
}

// Fetch chapters from the database for a given book
Future<List<Map<String, dynamic>>> fetchChapters(int bookNumber) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bibledb.db');

  final db = await openDatabase(path);
  final chapters = await db.rawQuery(
    'SELECT Chapter, COUNT(Versecount) as Versecount FROM bible WHERE Book = ? GROUP BY Chapter',
    [bookNumber],
  );

  return chapters;
}
