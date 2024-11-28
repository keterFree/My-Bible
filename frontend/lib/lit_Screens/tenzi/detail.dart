import 'package:flutter/material.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:frontend/lit_Screens/tenzi/model.dart';
import 'package:google_fonts/google_fonts.dart';

class WimboWaTenzi extends StatelessWidget {
  final Wimbo hymn;

  const WimboWaTenzi({Key? key, required this.hymn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: hymn.title,
      appBarActions: [],
      lightModeColor: Colors.black.withOpacity(0.3),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hymn.subtitle.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hymn.subtitle,
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                  ],
                ),
              const SizedBox(height: 16.0),

              // Display first stanza
              if (hymn.stanzas.isNotEmpty) ...[
                _buildStanza(context, 1, hymn.stanzas[0]),
                const SizedBox(height: 16.0),
              ],

              // Display chorus (only after the first stanza)
              if (hymn.chorus.isNotEmpty) ...[
                ...hymn.chorus.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, left: 10),
                      child: Text(
                        line,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    )),
                const SizedBox(height: 16.0),
              ],

              // Display the remaining stanzas after the chorus
              if (hymn.stanzas.length > 1) ...[
                for (int i = 1; i < hymn.stanzas.length; i++) ...[
                  _buildStanza(context, i + 1, hymn.stanzas[i]),
                  const SizedBox(height: 16.0),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStanza(
      BuildContext context, int stanzaIndex, List<String> stanza) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stanza title
        // Text(
        //   "Stanza $stanzaIndex:",
        //   style: Theme.of(context)
        //       .textTheme
        //       .bodyLarge
        //       ?.copyWith(fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 8.0),
        // Stanza lines
        ...stanza.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )),
      ],
    );
  }
}
