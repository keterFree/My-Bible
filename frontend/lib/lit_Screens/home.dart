import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/lit_Screens/hymns/list.dart';
import 'package:frontend/lit_Screens/tenzi/list.dart';
import 'package:frontend/lit_Screens/translation.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/base_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String verseReference = '';
  String verseContent = '';
  String verseTopic = '';
  String verseSermon = '';
  Uri? commentaryUrl;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchVerse();
  }

  Future<void> fetchVerse() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    List<String> topics = Lists.topics;
    int randomIndex = Random().nextInt(topics.length);
    String randomTopic = topics[randomIndex];

    final url = 'https://getcontext.xyz/api/api.php?query=$randomTopic';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          verseTopic = data['verse_category'] ?? randomTopic;
          verseReference = data['verse_reference'] ?? 'Unknown Reference';
          verseSermon = data['sermon_content'] ?? 'No sermon available.';
          verseContent = data['verse_content'] ?? 'Verse not available.';

          String commentaryUrlString = data['commentary_url'] ?? '';
          commentaryUrl = commentaryUrlString.isNotEmpty
              ? Uri.tryParse(commentaryUrlString)
              : null;
          isLoading = false;
        });
      } else {
        _handleError('Failed to load verse. Try again later.');
      }
    } catch (e) {
      _handleError('Network error. Default verse loaded.');
    }
  }

  void _handleError(String message) {
    setState(() {
      verseReference = 'Isaiah 60:1';
      verseContent =
          'Arise, shine, for your light has come, and the glory of the Lord rises upon you.';
      isLoading = false;
      hasError = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not launch URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<TokenProvider>(context).token;
    String userName = "Anonymous";
    String userContacts = "";

    if (token != null) {
      try {
        final jwt = JWT.decode(token);
        userName = jwt.payload['user']['name'] ?? 'User';
        userContacts = jwt.payload['user']['phone'] ?? '';
      } catch (e) {
        print('Error decoding token: $e');
      }
    }
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    return BaseScaffold(
      darkModeColor: Colors.black.withOpacity(0.2),
      title: 'Home',
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        userContacts,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Theme.of(context)
                        .appBarTheme
                        .titleTextStyle!
                        .color!
                        .withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display verse topic
                        Text(
                          verseTopic,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Display verse content
                        Text(
                          verseContent,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 10),

                        // Display verse reference
                        Text(
                          verseReference,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Commentary URL button
                            if (commentaryUrl != null)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (commentaryUrl != null) {
                                      _launchUrl(commentaryUrl!);
                                    }
                                  },
                                  child: Text(
                                    "Read more:\n$verseSermon",
                                    softWrap: true,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.blue
                                              : const Color.fromARGB(
                                                  255, 255, 203, 203),
                                        ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            // Refresh Button

                            IconButton(
                              onPressed: fetchVerse,
                              icon: const Icon(Icons.refresh),
                              color: Colors.white.withOpacity(0.8),
                              iconSize: 30,
                              tooltip: 'Refresh for new verse',
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 16.0),
              Container(
                constraints: BoxConstraints(
                    // Remove the maxHeight constraint since IntrinsicHeight will handle this
                    ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.book,
                          title:
                              'King James Version\n(KJV)', // Title with a newline
                          onTap: () {
                            Navigator.pushNamed(context, '/books');
                          },
                          context: context,
                          iconArrangement: Axis
                              .vertical, // Vertical icon and text arrangement
                          iconSize: 35, // Custom icon size
                          textSize: 20, // Custom text size
                          padding: EdgeInsets.symmetric(
                              vertical: 20), // Custom vertical padding
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      _buildMenuItem(
                        icon: Icons.collections_bookmark_rounded,
                        title: 'Explore other\nversions'
                            .toUpperCase(), // Title with uppercase and newline
                        onTap: () {
                          _navigateToTranslationSelectionPage(context);
                        },
                        context: context,
                        iconArrangement:
                            Axis.vertical, // Vertical icon and text arrangement
                        iconSize: 35, // Custom icon size
                        textSize: 15, // Custom text size
                        padding: EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10), // Custom padding
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildMenuItem(
                icon: Icons.music_note,
                title: 'Hymns',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HymnListPage()));
                },
                context: context,
                iconArrangement: Axis.horizontal, // Adjust if needed
                iconSize: 35, // Set custom icon size
                textSize: 18, // Set custom text size
                padding: EdgeInsets.all(16.0), // Custom padding
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.library_music,
                title: 'Tenzi za Rohoni',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => NyimboZaTenzi()));
                },
                context: context,
                iconArrangement: Axis.horizontal, // Adjust if needed
                iconSize: 40, // Set custom icon size
                textSize: 18, // Set custom text size
                padding: EdgeInsets.all(16.0), // Custom padding
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTranslationSelectionPage(BuildContext context) {
    // print(groupedTranslations);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranslationSelectionPage(),
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
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color.fromRGBO(78, 25, 25, 0.9)
              : const Color.fromRGBO(78, 39, 39, 0.6),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: padding, // Apply the custom padding here
        child: iconArrangement == Axis.vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                mainAxisAlignment: MainAxisAlignment.start,
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
