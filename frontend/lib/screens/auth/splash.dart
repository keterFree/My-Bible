import 'package:flutter/material.dart';
import 'package:frontend/db_helper.dart';
import 'package:frontend/screens/auth/login.dart';
import 'package:logger/logger.dart';

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
    setState(() {
      _statusMessage = 'Please be patient\nInitializing the database...';
      _isLoading = true; // Set loading state
      _hasError = false; // Reset error state
    });

    try {
      _logger.i('Starting database initialization');
      // Database initialization
      await DBHelper.initializeDatabase();

      // Update UI after successful initialization
      setState(() {
        _statusMessage = 'Initialization successful!';
        _isLoading = false; // Loading completed
      });

      _logger.i('Initialization successful');

      // Add a slight delay to display success message
      await Future.delayed(const Duration(seconds: 1));

      // Fade-out transition to HomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration:
                const Duration(milliseconds: 500), // Smooth transition
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during initialization: $e');
      setState(() {
        _statusMessage = 'Initialization failed: $e\nTap to retry';
        _hasError = true; // Set error state
        _isLoading = false; // Reset loading state
      });
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsating effect for text using Scale and Opacity animations
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Scale and opacity change over time
                return Transform.scale(
                  scale: 1 + 0.1 * _controller.value, // Scale pulsation
                  child: Opacity(
                    opacity: 0.7 + 0.3 * _controller.value, // Opacity pulsation
                    child: Text(
                      'Bible App',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
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
                            child: Text('Retry',style: Theme.of(context).textTheme.bodySmall),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: _hasError ? Colors.red : Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
