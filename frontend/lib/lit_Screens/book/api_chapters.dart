import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class ChapterPage extends StatefulWidget {
  final String bibleId;
  final String bookId;
  final int chapter;

  const ChapterPage({
    Key? key,
    required this.bookId,
    required this.chapter,
    required this.bibleId,
  }) : super(key: key);

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  int totalChapters = 0;
  late PageController _pageController;
  String bookTitle = '';
  final Map<int, Map<String, dynamic>> _chapterCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.chapter - 1);
    _fetchTotalChapters();
    _preloadChapters(
        widget.chapter); // Preload the current, previous, and next chapters
  }

  Future<void> _fetchTotalChapters() async {
    final url =
        "https://bible.helloao.org/api/${widget.bibleId}/${widget.bookId}/1.json";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalChapters = data["book"]["numberOfChapters"];
        bookTitle = data["book"]["name"] ?? '';
      });
    } else {
      throw Exception("Failed to fetch total chapters");
    }
  }

  Future<Map<String, dynamic>> _fetchChapterData(int chapter) async {
    if (_chapterCache.containsKey(chapter)) {
      return _chapterCache[chapter]!;
    }

    final url =
        "https://bible.helloao.org/api/${widget.bibleId}/${widget.bookId}/$chapter.json";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _chapterCache[chapter] = data;
      return data;
    } else {
      throw Exception("Failed to load chapter data");
    }
  }

  void _preloadChapters(int currentChapter) {
    // Preload the current, next, and previous chapters
    if (currentChapter > 1) {
      _fetchChapterData(currentChapter - 1);
    }
    _fetchChapterData(currentChapter);
    if (currentChapter < totalChapters) {
      _fetchChapterData(currentChapter + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      lightModeColor: Colors.black.withOpacity(0.3),
      darkModeColor: Colors.black.withOpacity(0.8),
      title: bookTitle.isEmpty ? widget.bookId : bookTitle,
      appBarActions: [],
      body: totalChapters == 0
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: totalChapters,
              onPageChanged: (index) {
                // Preload chapters around the current index
                _preloadChapters(index + 1);
              },
              itemBuilder: (context, index) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _fetchChapterData(index + 1),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset('assets/images/error.json',
                                height: 200),
                            const SizedBox(height: 20),
                            Text(
                              "Error: There was an error connecting to server.\nCheck your internet connection and try again",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    } else {
                      final data = snapshot.data!;
                      final verses =
                          data["chapter"]["content"] as List<dynamic>;
                      final bookTitle = data["book"]["name"];

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("$bookTitle ${index + 1}",
                                    style: GoogleFonts.outfit(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: verses.length,
                                itemBuilder: (context, verseIndex) {
                                  final verse = verses[verseIndex];
                                  final content =
                                      (verse['content'] as List?)?.join() ??
                                          ''; // Safeguard here
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${verse['number'] ?? ''}. ", // Display verse number
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                content, // Safely display content
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
