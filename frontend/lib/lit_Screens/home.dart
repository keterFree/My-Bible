import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
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
    Color background = isDarkMode
        ? Colors.black.withOpacity(0.25)
        : Colors.black.withOpacity(0.1);
    return BaseScaffold(
      title: 'Home',
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: background),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            userName,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display verse topic
                            Text(
                              verseTopic,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Display verse content
                            Text(
                              verseContent,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Display verse reference
                            Text(
                              verseReference,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.end,
                            ),
                            const SizedBox(height: 16),

                            // Commentary URL button
                            if (commentaryUrl != null)
                              GestureDetector(
                                onTap: () {
                                  if (commentaryUrl != null) {
                                    _launchUrl(commentaryUrl!);
                                  }
                                },
                                child: Text(
                                  "Read more: $verseSermon",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.blue
                                            : Colors.blue[900],
                                      ),
                                ),
                              ),
                          ],
                        ),
                  const SizedBox(height: 20),
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
            ),
          ),
        ],
      ),
    );
  }
}
