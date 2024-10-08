import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/home.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/lit_Screens/account.dart';
import 'package:frontend/auth/splash.dart';
import 'package:frontend/lit_Screens/book/bookmarks.dart';
import 'package:frontend/lit_Screens/book/books.dart';
import 'package:frontend/lit_Screens/book/highlights.dart';
import 'package:frontend/lit_Screens/error_screen.dart';
import 'package:frontend/lit_Screens/home.dart';
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
        '/error': (context) => const ErrorScreen(),
        '/homeChat': (context) => ChatHomeScreen(),
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
      primaryColor: const Color(0xFFD90B0B), // #D90B0B
      scaffoldBackgroundColor: const Color(0xFFF2F2F2), // #F2F2F2
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFFD91424), // #D91424
        secondary: const Color(0xFFBF364F), // #BF364F
        surface: const Color(0xFFF2F2F2), // #F2F2F2
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
            color: Color(0xFF0D0D0D),
            fontSize: 15,
            fontWeight: FontWeight.bold),
        headlineLarge:
            TextStyle(color: Color.fromARGB(255, 51, 2, 2)), // #D90B0B
        bodyLarge: TextStyle(color: Color(0xFF0D0D0D), fontSize: 18), // #0D0D0D
        bodyMedium: TextStyle(color: Color(0xFF0D0D0D), fontSize: 18),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFFBF364F), // #BF364F
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFBF364F), // #BF364F
        titleTextStyle:
            TextStyle(color: Colors.white, fontSize: 20), // White text
      ),
      iconTheme: const IconThemeData(
        color: Color.fromARGB(255, 146, 16, 27), // #D91424
      ),
    );
  }

  // Dark Theme Configuration
  ThemeData _darkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFF2F2F2), // #F2F2F2
      scaffoldBackgroundColor: const Color(0xFF8C808C), // #8C808C
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFFF2F2F2), // #F2F2F2
        secondary: const Color(0xFFA60311), // #A60311
        surface: const Color(0xFF8C808C), // #8C808C
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
            color: Color(0xFFF2F2F2),
            fontSize: 15,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFF2F2F2)), // #F2F2F2
        bodyLarge: TextStyle(color: Color(0xFFF2F2F2), fontSize: 18), // #F2F2F2
        bodyMedium: TextStyle(color: Color(0xFFF2F2F2), fontSize: 18),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFF010D00), // #010D00
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF010D00), // #010D00
        titleTextStyle:
            TextStyle(color: Colors.white, fontSize: 20), // White text
      ),
      iconTheme: const IconThemeData(
        color: Color.fromARGB(255, 146, 16, 27), // #D91424 // #A60311
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
