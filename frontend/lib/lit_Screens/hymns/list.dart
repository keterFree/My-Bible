import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/hymns/detail.dart';
import 'package:frontend/lit_Screens/hymns/model.dart';
import 'package:google_fonts/google_fonts.dart';

class HymnListPage extends StatefulWidget {
  const HymnListPage({super.key});

  @override
  State<HymnListPage> createState() => _HymnListPageState();
}

class _HymnListPageState extends State<HymnListPage> {
  late Future<Map<String, List<Hymn>>> hymnsFuture;

  // Search and filter state
  String searchQuery = '';
  String selectedCategory = 'All'; // Default to show all categories
  List<Hymn> displayedHymns = [];
  Map<String, List<Hymn>> hymnsByCategory = {};

  @override
  void initState() {
    super.initState();
    hymnsFuture = parseHymnsByCategory();
  }

  Future<Map<String, List<Hymn>>> parseHymnsByCategory() async {
    final jsonString = await rootBundle.loadString('assets/hymns.json');
    final Map<String, dynamic> data = json.decode(jsonString);

    final hymnsJson = data['hymns'] as Map<String, dynamic>;
    final categoriesJson = data['categories'] as Map<String, dynamic>;

    Map<String, List<int>> categories = categoriesJson.map(
      (key, value) => MapEntry(key, List<int>.from(value)),
    );

    Map<String, List<Hymn>> hymnsByCategory = {};
    hymnsJson.forEach((key, hymnJson) {
      Hymn hymn = Hymn.fromJson(hymnJson, categories);
      hymnsByCategory.putIfAbsent(hymn.category, () => []).add(hymn);
    });

    return hymnsByCategory;
  }

  void updateDisplayedHymns() {
    List<Hymn> filteredHymns = [];
    hymnsByCategory.forEach((category, hymns) {
      if (selectedCategory == 'All' || selectedCategory == category) {
        filteredHymns.addAll(hymns);
      }
    });

    if (searchQuery.isNotEmpty) {
      filteredHymns = filteredHymns.where((hymn) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        return hymn.title.toLowerCase().contains(lowerCaseQuery) ||
            hymn.number.toString().contains(lowerCaseQuery);
      }).toList();
    }

    setState(() {
      displayedHymns = filteredHymns;
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: Text(
                'All Categories',
                style: TextStyle(
                  fontWeight:  FontWeight.bold,
                  color: Theme.of(context).primaryColor),
              ),
              onTap: () {
                setState(() {
                  selectedCategory = 'All';
                  updateDisplayedHymns();
                });
                Navigator.pop(context);
              },
            ),
            ...hymnsByCategory.keys.map((category) {
              return ListTile(
                title: Text(category,
                    style: GoogleFonts.abrilFatface(
                      textStyle:
                          TextStyle(color: Theme.of(context).primaryColor),
                    )),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                    updateDisplayedHymns();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Hymns',
      appBarActions: [],
      body: FutureBuilder<Map<String, List<Hymn>>>(
        future: hymnsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyLarge,
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              'No hymns found.',
              style: Theme.of(context).textTheme.bodyLarge,
            ));
          } else {
            if (hymnsByCategory.isEmpty) {
              hymnsByCategory = snapshot.data!;
              displayedHymns =
                  hymnsByCategory.values.expand((list) => list).toList();
            }

            return Column(
              children: [
                _buildSearchAndFilterBar(),
                Expanded(
                  child: ListView.builder(
                    itemCount: displayedHymns.length,
                    itemBuilder: (context, index) {
                      final hymn = displayedHymns[index];
                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ListTile(
                          tileColor: const Color.fromARGB(100, 0, 0, 0),
                          title: Text(
                            '${hymn.number}. ${hymn.title}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            hymn.category,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HymnDetailPage(hymn: hymn),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search hymns',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                  updateDisplayedHymns();
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_outlined,
                color: Theme.of(context).textTheme.bodyLarge!.color),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
    );
  }
}
