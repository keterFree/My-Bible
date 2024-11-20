import 'package:flutter/material.dart';

class TranslationSelectionPage extends StatefulWidget {
  final Future<Map<String, List<Map<String, dynamic>>>>
      groupedTranslationsFuture;

  const TranslationSelectionPage(
      {super.key, required this.groupedTranslationsFuture});

  @override
  _TranslationSelectionPageState createState() =>
      _TranslationSelectionPageState();
}

class _TranslationSelectionPageState extends State<TranslationSelectionPage> {
  late Map<String, List<Map<String, dynamic>>> _groupedTranslations;
  late List<String> _filteredLanguages;
  late TextEditingController _languageSearchController;

  @override
  void initState() {
    super.initState();
    _languageSearchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Translation")),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: widget.groupedTranslationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No translations available'));
          }

          // Set the data after the snapshot is loaded
          _groupedTranslations = snapshot.data!;
          _filteredLanguages = _groupedTranslations.keys.toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar for languages
                TextField(
                  controller: _languageSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Languages',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _filteredLanguages = _groupedTranslations.keys
                          .where((language) => language
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView(
                    children: _filteredLanguages.map((language) {
                      return GestureDetector(
                        onTap: () {
                          _navigateToTranslations(context, language);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(language),
                            trailing: Icon(Icons.arrow_forward),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToTranslations(BuildContext context, String language) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return TranslationListPage(
          language: language,
          translations: _groupedTranslations[language]!,
        );
      },
    );
  }
}

class TranslationListPage extends StatefulWidget {
  final String language;
  final List<Map<String, dynamic>> translations;

  const TranslationListPage(
      {super.key, required this.language, required this.translations});

  @override
  _TranslationListPageState createState() => _TranslationListPageState();
}

class _TranslationListPageState extends State<TranslationListPage> {
  late TextEditingController _translationSearchController;
  late List<Map<String, dynamic>> _filteredTranslations;

  @override
  void initState() {
    super.initState();
    _translationSearchController = TextEditingController();
    _filteredTranslations = widget.translations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.language} Translations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar for translations
            TextField(
              controller: _translationSearchController,
              decoration: const InputDecoration(
                labelText: 'Search Translations',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  _filteredTranslations = widget.translations
                      .where((translation) => translation['translations']
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTranslations.length,
                itemBuilder: (context, index) {
                  final translation = _filteredTranslations[index];
                  return ListTile(
                    title: Text(translation['translations']),
                    onTap: () {
                      // Handle translation selection
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
