import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const BaseScaffold({required this.title, required this.body, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirmation = await showConfirmationDialog(context);
              if (confirmation) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                Provider.of<TokenProvider>(context, listen: false).setToken("");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(100, 4, 13, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Home',
              onPressed: () => Navigator.pushNamed(context, '/home'),
            ),
            IconButton(
              icon: const Icon(Icons.book),
              tooltip: 'Bible',
              onPressed: () => Navigator.pushNamed(context, '/books'),
            ),
            IconButton(
              icon: const Icon(Icons.star),
              tooltip: 'Highlights',
              onPressed: () => Navigator.pushNamed(context, '/highlights'),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark),
              tooltip: 'Bookmarks',
              onPressed: () => Navigator.pushNamed(context, '/bookmarks'),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'My Account',
              onPressed: () => Navigator.pushNamed(context, '/account'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () => Navigator.pushNamed(context, '/homeChat'),
        tooltip: 'Chat',
        child: Icon(Icons.chat, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
