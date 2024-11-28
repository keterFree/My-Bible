import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/hymns/model.dart';
import 'package:google_fonts/google_fonts.dart';

class HymnDetailPage extends StatelessWidget {
  final Hymn hymn;

  const HymnDetailPage({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '${hymn.number}. ${hymn.title}',
      appBarActions: [],
      lightModeColor: Colors.black.withOpacity(0.3),
      body: SingleChildScrollView(
        // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Category
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hymn.category.toUpperCase(),
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
                  // overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Display the First Verse
            if (hymn.verses.isNotEmpty)
              Text(
                hymn.verses[0],
                style: TextStyle(fontSize: 16),
                // overflow: TextOverflow.ellipsis, // Handle overflow
              ),

            // Chorus (if any)
            hymn.chorus.isEmpty
                ? SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Chorus:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
            hymn.chorus.isEmpty
                ? SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 16),
                    child: Text(
                      hymn.chorus,
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      // overflow: TextOverflow.ellipsis, // Handle overflow
                    ),
                  ),
            ...hymn.verses.skip(1).map((verse) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    verse,
                    style: TextStyle(fontSize: 16),
                    // overflow: TextOverflow.ellipsis, // Handle overflow
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
