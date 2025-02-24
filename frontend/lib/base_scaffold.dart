import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/create_group.dart';
import 'package:frontend/lit_Screens/account.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions; // Optional actions for the AppBar
  final Widget? floatingActionButton; // Optional floating action button
  final Color? darkModeColor; // Optional color for dark mode
  final Color? lightModeColor; // Optional color for light mode

  const BaseScaffold({
    required this.title,
    required this.body,
    this.appBarActions,
    this.floatingActionButton,
    this.darkModeColor, // Add optional dark mode color
    this.lightModeColor, // Add optional light mode color
    super.key,
  });

  // Handle menu item selection
  void _handleMenuItemClick(String value, BuildContext context) {
    switch (value) {
      case 'Create Group':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateGroupPage()),
        );
        break;
      case 'View Account Details':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AccountScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    // Default colors if not provided
    Color darkColor = darkModeColor ?? Colors.black.withOpacity(0.2);
    Color lightColor = lightModeColor ?? Colors.black.withOpacity(0.2);

    String backgroundImage = isDarkMode
        ? 'assets/images/groupBackgroundd.jpg'
        : 'assets/images/groupBackgroundl.jpg';

    return Stack(
      children: [
        // Background Image with opacity filter
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                isDarkMode ? darkColor : lightColor,
                BlendMode.darken,
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: isDarkMode
              ? darkModeColor ?? Colors.transparent
              : lightModeColor ??
                  Colors.transparent, // Background remains visible
          appBar: AppBar(
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              title,
              style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
              overflow: TextOverflow.ellipsis,
            ),
            // centerTitle: true,
            actions: appBarActions ??
                _buildDefaultActions(context), // Use custom actions if provided
          ),
          body: body,
          bottomNavigationBar: BottomAppBar(
            color: const Color.fromARGB(200, 4, 13, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavIcon(context, Icons.home, 'Home', '/home'),
                _buildNavIcon(context, Icons.book, 'Bible', '/books'),
                // _buildNavIcon(context, Icons.add_home_outlined, 'Add service',
                //     '/createService'),
                _buildNavIcon(context, Icons.add_home_outlined, 'show service',
                    '/showService'),
                _buildNavIcon(
                    //     context, Icons.bookmark, 'Bookmarks', '/bookmarks'),
                    // _buildNavIcon(
                    context,
                    Icons.event_rounded,
                    'My Events',
                    '/homeEvents'),
                _buildNavIcon(
                    context, Icons.account_circle, 'My Account', '/account'),
              ],
            ),
          ),
          floatingActionButton: floatingActionButton ??
              _buildDefaultFAB(
                  context, isDarkMode), // Use custom FAB if provided
        ),
      ],
    );
  }

  // Build the default actions if none are provided
  List<Widget> _buildDefaultActions(BuildContext context) {
    return [
      PopupMenuButton<String>(
        onSelected: (value) => _handleMenuItemClick(value, context),
        itemBuilder: (BuildContext context) {
          return {'Create Group', 'View Account Details'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
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
    ];
  }

  // Build the default floating action button
  FloatingActionButton _buildDefaultFAB(BuildContext context, bool isDarkMode) {
    return FloatingActionButton(
      backgroundColor: isDarkMode
          ? Colors.white.withOpacity(0.9)
          : Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
      onPressed: () => Navigator.pushNamed(context, '/homeChat'),
      tooltip: 'Chat',
      child: const Icon(Icons.chat),
    );
  }

  // Helper method to create reusable navigation icons
  IconButton _buildNavIcon(
      BuildContext context, IconData icon, String tooltip, String route) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }

  // Show a confirmation dialog for logging out
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
