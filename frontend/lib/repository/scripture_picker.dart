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

  List<Map<String, dynamic>> scriptures = [];

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
        'book': Lists.books.indexOf(selectedBook!),
        'chapter': selectedChapter!,
        'verseNumbers': List.from(selectedVerses),
      };

      setState(() {
        scriptures.add(scripture);
        selectedVerses.clear();
        selectedChapter = null;
        selectedBook = null;
      });

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
        const SizedBox(height: 10),
        if (scriptures.isNotEmpty) ...[
          _buildText('Selected Scriptures', context),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            itemCount: scriptures.length,
            itemBuilder: (context, index) {
              final scripture = scriptures[index];
              final bookName = Lists.books[scripture['book']];
              final chapter = scripture['chapter'];
              final verses =
                  (scripture['verseNumbers'] as List).cast<int>().join(', ');

              return ListTile(
                title: _buildText('$bookName $chapter:$verses', context),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeScripture(index),
                ),
              );
            },
          ),
          const Divider(),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButton<String>(
              dropdownColor: Colors.black.withOpacity(0.85),
              hint: _buildText('Add Scripture', context),
              value: selectedBook,
              items: Lists.books.map((book) {
                return DropdownMenuItem(
                  value: book,
                  child: _buildText(book, context),
                );
              }).toList(),
              onChanged: (book) => loadChapters(book!),
            ),
            SizedBox(width: 10),
            if (selectedBook != null)
              DropdownButton<int>(
                dropdownColor: Colors.black.withOpacity(0.85),
                hint: _buildText('Select Chapter', context),
                value: selectedChapter,
                items: List.generate(chapterCount, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: _buildText('Chapter ${index + 1}', context),
                  );
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
                onPressed: showRangeDialog,
                child: Text('Verse Range'),
              ),
              ElevatedButton(
                onPressed: selectEntireChapter,
                child: Text('Entire Chapter'),
              ),
            ],
          ),
          _buildVerseGrid(),
          ElevatedButton(
            onPressed: addScripture,
            child: Text('Add Scripture'),
          ),
        ],
      ],
    );
  }

  Widget _buildVerseGrid() {
    return GridView.builder(
      shrinkWrap: true, // Ensures it only takes the necessary space
      physics:
          const NeverScrollableScrollPhysics(), // Prevents scrolling inside the grid
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // Adjust this based on how many columns you need
        crossAxisSpacing: 6.0,
        mainAxisSpacing: 6.0,
        childAspectRatio: 1.5, // Adjust for the size/shape of the chips
      ),
      itemCount: verseCount,
      itemBuilder: (context, index) {
        final verse = index + 1;
        return FilterChip(
          selectedShadowColor: Colors.transparent,
          shadowColor: Colors.transparent,
          backgroundColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          surfaceTintColor: Theme.of(context).colorScheme.secondary,
          selectedColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
          label: Text(
            '$verse',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          selected: selectedVerses.contains(verse),
          onSelected: (_) => toggleVerseSelection(verse),
        );
      },
    );
  }

  void removeScripture(int index) {
    setState(() {
      scriptures.removeAt(index);
    });

    widget.onScripturesSelected(scriptures);
  }

  Widget _buildText(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void showRangeDialog() {
    int? startVerse;
    int? endVerse;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.6),
          title: _buildText('Select Verse Range', context),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                dropdownColor: Colors.black.withOpacity(0.85),
                hint: _buildText('Start Verse', context),
                value: startVerse,
                items: List.generate(verseCount, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: _buildText('Verse ${index + 1}', context),
                  );
                }),
                onChanged: (value) {
                  setState(() => startVerse = value);
                },
              ),
              DropdownButton<int>(
                dropdownColor: Colors.black.withOpacity(0.85),
                hint: _buildText('End Verse', context),
                value: endVerse,
                items: List.generate(verseCount, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: _buildText('Verse ${index + 1}', context),
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
              child: Text('Select Range'),
            ),
          ],
        );
      },
    );
  }
}
