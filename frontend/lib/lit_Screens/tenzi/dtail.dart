import 'package:flutter/material.dart';
import 'package:frontend/lit_Screens/tenzi/model.dart';

class WimboWaTenzi extends StatelessWidget {
  final Wimbo hymn;

  const WimboWaTenzi({Key? key, required this.hymn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hymn.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                hymn.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),

              // Subtitle
              if (hymn.subtitle.isNotEmpty)
                Text(
                  hymn.subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[700]),
                ),
              const SizedBox(height: 16.0),

              // Chorus Section
              if (hymn.chorus.isNotEmpty) ...[
                Text(
                  "Chorus:",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                ...hymn.chorus.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )),
                const SizedBox(height: 16.0),
              ],

              // Stanzas Section
              // Text(
              //   "Stanzas:",
              //   style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 8.0),
              // ...hymn.stanzas.map((line) => Padding(
              //       padding: const EdgeInsets.only(bottom: 4.0),
              //       child: Text(
              //         line,
              //         style: Theme.of(context).textTheme.bodyLarge,
              //       ),
              //     )),
            ],
          ),
        ),
      ),
    );
  }
}
