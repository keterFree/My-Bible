import 'package:flutter/material.dart';
import 'package:frontend/db_helper.dart';
import 'package:frontend/constants.dart';

class ScripturePicker extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onScripturesSelected;

  const ScripturePicker({super.key, required this.onScripturesSelected});

  @override
  _ScripturePickerState createState() => _ScripturePickerState();
}

class _ScripturePickerState extends State<ScripturePicker> {
  String? selectedBook;
  int? selectedChapter;
  List<int> selectedVerses = [];
  int chapterCount = 0;
  int verseCount = 0;

  List<Map<String, dynamic>> scriptures = []; // Store multiple selections

  void loadChapters(String book) async {
    final bookId = Lists.books.indexOf(book);
    chapterCount = await DBHelper.getChapterCount(bookId);
    setState(() {
      selectedBook = book;
      selectedChapter = null;
      selectedVerses.clear();
    });
  }

  void loadVerses(int chapter) async {
    final bookId = Lists.books.indexOf(selectedBook!);
    verseCount = await DBHelper.getVerseCount(bookId, chapter);
    setState(() {
      selectedChapter = chapter;
      selectedVerses.clear();
    });
  }

  void addScripture() {
    if (selectedBook != null &&
        selectedChapter != null &&
        selectedVerses.isNotEmpty) {
      final scripture = {
        'book': Lists.books.indexOf(selectedBook!), // Use index for book ID
        'chapter': selectedChapter!,
        'verseNumbers': List.from(selectedVerses), // Clone the list
      };

      setState(() {
        scriptures.add(scripture);
        selectedVerses.clear();
        selectedChapter = null;
        selectedBook = null;
      });

      // Trigger callback with the updated list of scriptures
      widget.onScripturesSelected(scriptures);
    }
  }

  void toggleVerseSelection(int verse) {
    setState(() {
      if (selectedVerses.contains(verse)) {
        selectedVerses.remove(verse);
      } else {
        selectedVerses.add(verse);
      }
    });
  }

  void selectRange(int start, int end) {
    setState(() {
      selectedVerses = List.generate(end - start + 1, (index) => start + index);
    });
  }

  void selectEntireChapter() {
    setState(() {
      selectedVerses = List.generate(verseCount, (index) => index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: 10),

        // Display selected scriptures
        if (scriptures.isNotEmpty) ...[
          const Text(
            'Selected Scriptures:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true, // To avoid scrolling conflicts with the parent
            itemCount: scriptures.length,
            itemBuilder: (context, index) {
              final scripture = scriptures[index];
              final bookName = Lists.books[scripture['book']];
              final chapter = scripture['chapter'];
              print(scripture['verseNumbers']
                  .runtimeType); // Should output List<int> or List<dynamic>
              final verses =
                  (scripture['verseNumbers'] as List).cast<int>().join(', ');
              return ListTile(
                title: Text('$bookName $chapter:$verses'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeScripture(index),
                ),
              );
            },
          ),
          const Divider(), // Optional: Add a divider for separation
        ],

        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownButton<String>(
              hint: const Text('Add Scripture'),
              value: selectedBook,
              items: Lists.books.map((book) {
                return DropdownMenuItem(value: book, child: Text(book));
              }).toList(),
              onChanged: (book) => loadChapters(book!),
            ),
            if (selectedBook != null)
              DropdownButton<int>(
                hint: const Text('Select Chapter'),
                value: selectedChapter,
                items: List.generate(chapterCount, (index) {
                  return DropdownMenuItem(
                      value: index + 1, child: Text('Chapter ${index + 1}'));
                }),
                onChanged: (chapter) => loadVerses(chapter!),
              ),
          ],
        ),
        if (selectedChapter != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => showRangeDialog(),
                child: const Text('Select Verse Range'),
              ),
              ElevatedButton(
                onPressed: selectEntireChapter,
                child: const Text('Select Entire Chapter'),
              ),
            ],
          ),
          Wrap(
            spacing: 8.0,
            children: List.generate(verseCount, (index) {
              final verse = index + 1;
              return FilterChip(
                selectedColor:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                label: Text('$verse'),
                selected: selectedVerses.contains(verse),
                onSelected: (_) => toggleVerseSelection(verse),
              );
            }),
          ),
          ElevatedButton(
            onPressed: addScripture,
            child: const Text('Add Scripture'),
          ),
        ],
      ],
    );
  }

  void removeScripture(int index) {
    setState(() {
      scriptures.removeAt(index);
    });

    // Trigger callback with the updated scriptures list
    widget.onScripturesSelected(scriptures);
  }

  void showRangeDialog() {
    int? startVerse;
    int? endVerse;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Verse Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                hint: const Text('Start Verse'),
                value: startVerse,
                items: List.generate(verseCount, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('Verse ${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  setState(() => startVerse = value);
                },
              ),
              DropdownButton<int>(
                hint: const Text('End Verse'),
                value: endVerse,
                items: List.generate(verseCount, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('Verse ${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  setState(() => endVerse = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (startVerse != null && endVerse != null) {
                  Navigator.pop(context);
                  selectRange(startVerse!, endVerse!);
                }
              },
              child: const Text('Select Range'),
            ),
          ],
        );
      },
    );
  }
}
