import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/book/language_books.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

class TranslationSelectionPage extends StatefulWidget {
  const TranslationSelectionPage({Key? key}) : super(key: key);

  @override
  _TranslationSelectionPageState createState() =>
      _TranslationSelectionPageState();
}

class _TranslationSelectionPageState extends State<TranslationSelectionPage> {
  List<String> _languageNames = [];
  List<String> _filteredLanguageNames = [];
  final TextEditingController _searchController = TextEditingController();
  bool loading = true;
  String? errorMessage;
  late Future<List<dynamic>> translationsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAndSetTranslations();

    // Add a listener to filter the list based on the search input
    _searchController.addListener(_filterLanguages);
  }

  Future<List<dynamic>> fetchTranslations() async {
    try {
      final response = await http.get(Uri.parse(
          'https://bible.helloao.org/api/available_translations.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('translations') && data['translations'] is List) {
          return data['translations'];
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception(
            "Failed to fetch translations (status: ${response.statusCode})");
      }
    } catch (error) {
      throw Exception("An error occurred while fetching translations: $error");
    }
  }

  void _fetchAndSetTranslations() {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    translationsFuture = fetchTranslations();

    translationsFuture.then((translations) {
      final languageNames = translations
          .map((translation) => translation['languageEnglishName'] as String)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _languageNames = languageNames;
        _filteredLanguageNames = languageNames;
        loading = false;
      });
    }).catchError((error) {
      setState(() {
        errorMessage = error.toString();
        loading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLanguageNames = _languageNames
          .where((language) => language.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Select Language",
      appBarActions: [],
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset('assets/images/error.json', height: 200),
                      const SizedBox(height: 20),
                      Text(
                        "Error: $errorMessage",
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: _fetchAndSetTranslations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search languages",
                          hintStyle: Theme.of(context).textTheme.bodyLarge,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredLanguageNames.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset('assets/images/error.json',
                                      height: 200),
                                  const SizedBox(height: 20),
                                  Text(
                                    "No languages found.",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  ElevatedButton(
                                    onPressed: _fetchAndSetTranslations,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredLanguageNames.length,
                              itemBuilder: (context, index) {
                                final languageName =
                                    _filteredLanguageNames[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  child: ListTile(
                                    tileColor: Colors.black.withOpacity(0.2),
                                    title: Text(
                                      languageName,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FilteredTranslationsPage(
                                            translations: translationsFuture,
                                            selectedLanguageName: languageName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
