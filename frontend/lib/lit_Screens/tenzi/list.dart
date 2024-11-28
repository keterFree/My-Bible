import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/tenzi/dtail.dart';
import 'package:frontend/lit_Screens/tenzi/model.dart';

class NyimboZaTenzi extends StatefulWidget {
  const NyimboZaTenzi({super.key});

  @override
  _NyimboZaTenziState createState() => _NyimboZaTenziState();
}

class _NyimboZaTenziState extends State<NyimboZaTenzi> {
  late Future<List<Wimbo>> hymnsFuture;
  List<Wimbo> allHymns = [];
  List<Wimbo> filteredHymns = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    hymnsFuture = loadHymns();
  }

  Future<List<Wimbo>> loadHymns() async {
    final jsonString = await rootBundle.loadString('assets/tenzi.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    final hymns = jsonData.map((data) => Wimbo.fromJson(data)).toList();
    allHymns = hymns; // Store all hymns
    filteredHymns = hymns; // Initially display all hymns
    return hymns;
  }

  void filterHymns(String query) {
    setState(() {
      filteredHymns = allHymns
          .where((hymn) =>
              hymn.title.toLowerCase().contains(query.toLowerCase()) ||
              hymn.subtitle.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    return BaseScaffold(
      title: "Tenzi Za Rohoni",
      appBarActions: [],
      body: FutureBuilder<List<Wimbo>>(
        future: hymnsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hymns available."));
          } else {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterHymns,
                    decoration: InputDecoration(
                      labelText: "Search hymns",
                      hintText: "Enter title or subtitle",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                // Hymn List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredHymns.length,
                    itemBuilder: (context, index) {
                      final hymn = filteredHymns[index];
                      return Card(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.6),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              hymn.songNumber.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            hymn.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
                          subtitle: Text(
                            hymn.subtitle,
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WimboWaTenzi(hymn: hymn),
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
}
