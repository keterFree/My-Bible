import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/translation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BibleMenuScreen extends StatelessWidget {
  const BibleMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Bible Library',
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              _buildMenuItem(
                icon: Icons.search,
                title: 'Explore other versions',
                onTap: () {
                  _navigateToTranslationSelectionPage(context);
                },
                context: context,
                iconArrangement: Axis.horizontal, // Adjust if needed
                iconSize: 25, // Set custom icon size
                textSize: 15, // Set custom text size
                padding: EdgeInsets.all(16.0),
              ),
              const SizedBox(height: 16.0),
              _buildMenuItem(
                icon: Icons.book,
                title: 'King James Version',
                onTap: () {
                  Navigator.pushNamed(context, '/books');
                },
                context: context,
                iconArrangement: Axis.vertical, // Adjust if needed
                iconSize: 60, // Set custom icon size
                textSize: 20, // Set custom text size
                padding: EdgeInsets.symmetric(
                    vertical: 50.0, horizontal: 16), // Custom padding
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // 3 columns
                  crossAxisSpacing: 16.0, // Horizontal spacing between items
                  mainAxisSpacing: 16.0, // Vertical spacing between items
                  children: [
                    _buildMenuItem(
                      icon: Icons.music_note,
                      title: 'Hymns',
                      onTap: () {
                        // Handle navigation to hymns
                      },
                      context: context,
                      iconArrangement: Axis.vertical, // Adjust if needed
                      iconSize: 40, // Set custom icon size
                      textSize: 18, // Set custom text size
                      padding: EdgeInsets.all(16.0), // Custom padding
                    ),
                    _buildMenuItem(
                      icon: Icons.library_music,
                      title: 'Tenzi za Rohoni',
                      onTap: () {
                        // Handle navigation to Tenzi za Rohoni
                      },
                      context: context,
                      iconArrangement: Axis.vertical, // Adjust if needed
                      iconSize: 40, // Set custom icon size
                      textSize: 18, // Set custom text size
                      padding: EdgeInsets.all(16.0), // Custom padding
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchTranslations() async {
    final response = await http.get(
        Uri.parse('https://bible.helloao.org/api/available_translations.json'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List translations = data['translations'];

      // Group translations by 'languageEnglishName'
      Map<String, List<Map<String, dynamic>>> groupedTranslations = {};

      for (var translation in translations) {
        String languageName = translation['languageEnglishName'];

        // If this language group doesn't exist yet, create it
        if (!groupedTranslations.containsKey(languageName)) {
          groupedTranslations[languageName] = [];
        }

        // Add the translation to the respective language group
        groupedTranslations[languageName]?.add({
          'translations': translation['name'],
          'id': translation['id'],
        });
      }

      return groupedTranslations;
    } else {
      throw Exception('Failed to load translations');
    }
  }

  void _navigateToTranslationSelectionPage(BuildContext context) {
    final groupedTranslations = fetchTranslations();

    // print(groupedTranslations);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranslationSelectionPage(
            groupedTranslationsFuture: groupedTranslations),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    required BuildContext context,
    Axis iconArrangement = Axis.vertical, // Default arrangement
    double iconSize = 40.0, // Default icon size
    double textSize = 16.0, // Default text size
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
        horizontal: 16.0, vertical: 20.0), // Default padding
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: padding, // Apply the custom padding here
        child: iconArrangement == Axis.vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize), // Set the dynamic icon size
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: textSize, // Set the dynamic text size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize), // Set the dynamic icon size
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: textSize, // Set the dynamic text size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
