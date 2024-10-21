import 'package:flutter/material.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/db_helper.dart';
import 'package:frontend/lit_Screens/home.dart';
import 'package:frontend/providers/token_provider.dart';
// import 'package:frontend/lit_Screens/auth/login.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late Logger _logger;
  late AnimationController _controller;
  String _statusMessage = 'Initializing...'; // Status updates
  bool _hasError = false; // Track error state
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _logger = Logger();

    // Animation controller for pulsating effect
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeat animation with reverse effect

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initializeApp();
    });
  }

  Future<void> initializeApp() async {
    // Show initial status and loading state
    _updateStatus('Please be patient\nInitializing the database...',
        isLoading: true);

    try {
      _logger.i('Starting database initialization');

      // Initialize the database
      await DBHelper.initializeDatabase();

      _logger.i('Initialization successful');
      _updateStatus('Initialization successful!', isLoading: false);

      // Delay for displaying the success message
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Check if the user is logged in and navigate accordingly
        await _checkLoggedInStatus();
      }
    } catch (e) {
      _logger.e('Error during initialization: $e');
      _updateStatus('Initialization failed: $e\nTap to retry',
          hasError: true, isLoading: false);
    }
  }

// Function to update status and manage loading and error states
  void _updateStatus(String message,
      {bool isLoading = false, bool hasError = false}) {
    setState(() {
      _statusMessage = message;
      _isLoading = isLoading;
      _hasError = hasError;
    });
  }

// Check if user is logged in and navigate
  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    Widget nextScreen =
        (token != null) ? const HomeScreen() : const LoginScreen();

    // Update the token provider if the token exists
    if (token != null) {
      Provider.of<TokenProvider>(context, listen: false).setToken(token);
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Retry initialization on failure
  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    initializeApp();
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose animation controller when the screen is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    String iconImage =
        isDarkMode ? 'assets/images/iconnn.png' : 'assets/images/icon.png';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsating effect for text using Scale and Opacity animations
            AnimatedBuilder(
              animation: _controller, // Connect the animation controller
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + 0.1 * _controller.value, // Create pulsation effect
                  child: Opacity(
                    opacity: 0.7 +
                        0.3 * _controller.value, // Change opacity over time
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center the content
                      children: [
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width /
                              5, // Adjust radius to be a quarter of screen width
                          backgroundColor: Colors.transparent,
                          child: Image.asset(
                            iconImage,
                            fit: BoxFit.contain, // Ensure the icon fits well
                          ),
                        ),
                        const SizedBox(
                            height: 16), // Space between image and text
                        Text(
                          'E-Pistle Super App',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                            fontSize: 36, // Set custom font size
                            fontWeight: FontWeight.bold, // Bold text
                            shadows: const [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black38, // Shadow color
                                offset: Offset(2, 2), // Shadow offset
                              ),
                            ], // Add shadow effect
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            // Show loading indicator or error icon
            _isLoading
                ? const CircularProgressIndicator()
                : _hasError
                    ? Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          // Retry button if error occurs
                          ElevatedButton(
                            onPressed: _retryInitialization,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              // Add any default style properties here
                              padding:
                                  const EdgeInsets.all(16.0), // example padding
                            ),
                            child: Text('Retry',
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
            const SizedBox(height: 20),
            // Display status message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 16,
                      color: _hasError
                          ? Colors.red
                          : Theme.of(context).textTheme.bodySmall!.color,
                    ),
              ),
            ),
            Text(
              "created by keter titus",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontFamily: 'RaleWay',
                    fontStyle: FontStyle.italic,
                    color: _hasError
                        ? Colors.red
                        : Theme.of(context).textTheme.bodySmall!.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
