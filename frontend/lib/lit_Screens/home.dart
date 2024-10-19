import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/lit_Screens/baseScaffold.dart';
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
  Uri? commentaryUrl; // Nullable Uri
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVerse();
  }

  Future<void> fetchVerse() async {
    List<String> topics = Lists.topics;
    int randomIndex = Random().nextInt(topics.length);
    String randomTopic = topics[randomIndex];

    // Construct the API URL with the selected topic
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

          // Safely handle commentary URL
          String commentaryUrlString = data['commentary_url'] ?? '';
          if (commentaryUrlString.isNotEmpty) {
            commentaryUrl = Uri.tryParse(commentaryUrlString);
          } else {
            commentaryUrl = null;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          verseReference = 'Error';
          verseContent = 'Failed to load verse.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        verseReference = 'Isaiah 60:1';
        verseContent =
            'Arise,shine,for your light has come, and the glory of the lord rises upon you.';
        isLoading = false;
      });
    }
  }

  void _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the token from TokenProvider
    final token = Provider.of<TokenProvider>(context).token;

    // const Color logoutIconColor = Color(0xFF93B1A6);

    String userName = "Anonymous";
    String userContacts = "";

    if (token != null) {
      // Decode the token and extract the user's name
      try {
        final jwt = JWT.decode(token);
        userName = jwt.payload['user']['name'] ?? 'User';
        userContacts = jwt.payload['user']['phone'] ?? '';
      } catch (e) {
        print('Error decoding token: $e');
      }
    }
    return BaseScaffold(
      title: 'Home',
      body: Center(
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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 16),

                        // Display verse content
                        Text(
                          verseContent,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                          // textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

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
                              " read more:\n $verseSermon",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                              // textAlign: TextAlign.end,
                            ),
                          ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
