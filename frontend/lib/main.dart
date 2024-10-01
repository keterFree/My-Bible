import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/screens/account.dart';
import 'package:frontend/screens/auth/splash.dart';
import 'package:frontend/screens/book/bookmarks.dart';
import 'package:frontend/screens/book/books.dart';
import 'package:frontend/screens/book/highlights.dart';
import 'package:frontend/screens/error_screen.dart';
import 'package:frontend/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the appropriate database factory based on the platform
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Use sqflite_ffi for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: providers,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bible App',
      themeMode:
          ThemeMode.system, // Automatically switch between light/dark mode
      theme: _lightTheme(), // Light theme
      darkTheme: _darkTheme(), // Dark theme
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/books': (context) => const BooksScreen(),
        '/highlights': (context) => const HighlightsScreen(),
        '/bookmarks': (context) => const BookmarksScreen(),
        '/account': (context) => const AccountScreen(),
        '/error': (context) => const ErrorScreen(), // Added error screen
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            if (settings.name == null) {
              return const SplashScreen();
            }
            Widget screen = screenFactory(settings.name!);
            if (screen is SplashScreen && settings.name != '/') {
              debugPrint('Unknown route: ${settings.name}');
              return const ErrorScreen(); // Use error screen for unknown routes
            }
            return screen;
          },
        );
      },
    );
  }

  // Light Theme Configuration
  ThemeData _lightTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF12372A), // #12372A
      scaffoldBackgroundColor: const Color(0xFFFBFADA), // #FBFADA
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFF12372A), // #12372A
        secondary: const Color(0xFF436850), // #436850
        surface: const Color(0xFFFBFADA), // #FBFADA
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
            color: Color.fromARGB(255, 61, 68, 59),
            fontSize: 15,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFF12372A)), // #12372A
        bodyLarge: TextStyle(color: Color(0xFF436850), fontSize: 18), // #436850
        bodyMedium: TextStyle(color: Color(0xFF12372A), fontSize: 18),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFFADBC9F), // #ADBC9F
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12372A), // #12372A
        titleTextStyle:
            TextStyle(color: Color(0xFFFBFADA), fontSize: 20), // #FBFADA
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF436850), // #436850
      ),
    );
  }

  // Dark Theme Configuration
  ThemeData _darkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFFBFADA), // #FBFADA
      scaffoldBackgroundColor: const Color(0xFF12372A), // #12372A
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFFFBFADA), // #FBFADA
        secondary: const Color(0xFFADBC9F), // #ADBC9F
        surface: const Color(0xFF12372A), // #12372A
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
            color: Color.fromARGB(255, 68, 68, 59),
            fontSize: 15,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFFBFADA)), // #FBFADA
        bodyLarge: TextStyle(color: Color(0xFFADBC9F), fontSize: 18), // #ADBC9F
        bodyMedium:
            TextStyle(color: Color.fromARGB(255, 228, 248, 207), fontSize: 18),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFF436850), // #436850
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12372A), // #12372A
        titleTextStyle:
            TextStyle(color: Color(0xFFFBFADA), fontSize: 20), // #FBFADA
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFADBC9F), // #ADBC9F
      ),
    );
  }
}

// Factory Pattern for screen creation
Widget screenFactory(String routeName) {
  switch (routeName) {
    case '/home':
      return const HomeScreen();
    case '/books':
      return const BooksScreen();
    case '/highlights':
      return const HighlightsScreen();
    case '/bookmarks':
      return const BookmarksScreen();
    case '/account':
      return const AccountScreen();
    default:
      return const SplashScreen(); // Fallback to the splash screen for unknown routes
  }
}
