import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/book/api_books.dart';
import 'package:lottie/lottie.dart';

class FilteredTranslationsPage extends StatefulWidget {
  final Future<List<dynamic>> translations;
  final String selectedLanguageName;

  const FilteredTranslationsPage({
    Key? key,
    required this.translations,
    required this.selectedLanguageName,
  }) : super(key: key);

  @override
  _FilteredTranslationsPageState createState() =>
      _FilteredTranslationsPageState();
}

class _FilteredTranslationsPageState extends State<FilteredTranslationsPage> {
  List<dynamic> _filteredTranslations = [];
  List<dynamic> _allTranslations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Fetch and filter translations by selected language
    widget.translations.then((translations) {
      final filtered = translations
          .where((translation) =>
              translation['languageEnglishName'] == widget.selectedLanguageName)
          .toList();

      setState(() {
        _allTranslations = filtered;
        _filteredTranslations = filtered;
      });
    });

    // Add listener to filter translations based on search input
    _searchController.addListener(_filterBySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTranslations = _allTranslations
          .where((translation) => (translation['englishName'] as String)
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: widget.selectedLanguageName,
      appBarActions: [],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by English name",
                hintStyle: Theme.of(context).textTheme.bodyLarge,
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).textTheme.bodyLarge!.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredTranslations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/images/error.json', height: 200),
                        const SizedBox(height: 20),
                        Text(
                            "No results found for '${_searchController.text}'.",
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTranslations.length,
                    itemBuilder: (context, index) {
                      final translation = _filteredTranslations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        child: ListTile(
                          tileColor: Colors.black.withOpacity(0.2),
                          title: Text(translation['englishName'],
                              style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BooksPage(id: translation['id']),
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
