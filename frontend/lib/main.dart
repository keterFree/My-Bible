import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/home.dart';
import 'package:frontend/events/events_list.dart';
import 'package:frontend/lit_Screens/lit_menu.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/lit_Screens/account.dart';
import 'package:frontend/auth/splash.dart';
import 'package:frontend/lit_Screens/book/bookmarks.dart';
import 'package:frontend/lit_Screens/book/books.dart';
import 'package:frontend/lit_Screens/book/highlights.dart';
import 'package:frontend/lit_Screens/error_screen.dart';
import 'package:frontend/lit_Screens/home.dart';
import 'package:frontend/repository/create_service.dart';
import 'package:frontend/repository/show_services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:printing/printing.dart';
// release:
// Clean the project: Run
//flutter clean
// to remove any previous build files and configurations1.

// Generate the release APK: Run
//flutter build apk --release
//This command will create a release APK file in the build/app/outputs/flutter-apk/app-release.apk directory.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/books': (context) => const BooksScreen(),
        '/lit_menu': (context) => const BibleMenuScreen(),
        '/highlights': (context) => const HighlightsScreen(),
        '/bookmarks': (context) => const BookmarksScreen(),
        '/account': (context) => const AccountScreen(),
        '/error': (context) => const ErrorScreen(),
        '/homeChat': (context) => const ChatHomeScreen(),
        '/homeEvents': (context) => const EventListScreen(),
        '/createService': (context) => const CreateServiceScreen(),
        '/showService': (context) => const ServicesScreen()
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
              return const ErrorScreen();
            }
            return screen;
          },
        );
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF8C1127), // #8C1127
      scaffoldBackgroundColor: const Color(0xFFF2F2F2), // #F2F2F2
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFFF2274C), // #F2274C
        secondary: const Color(0xFFA61C41), // #A61C41
        surface: const Color(0xFFF2F2F2), // #F2F2F2
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
            // color: Color(0xFF0D0D0D),
            color: Colors.black,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFF731212)), // #731212
        bodyLarge: TextStyle(
            // color: Color(0xFF0D0D0D),
            color: Colors.white,
            fontWeight: FontWeight.bold), // #0D0D0D
        bodyMedium: TextStyle(
            // color: Color(0xFF0D0D0D),
            color: Colors.white,
            fontWeight: FontWeight.bold),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFFA61C41), // #A61C41
        textTheme: ButtonTextTheme.normal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(158, 218, 119, 145), // #A61C41
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
      ),
      iconTheme: const IconThemeData(
        color: Color.fromARGB(255, 185, 29, 29), // #731212
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFF2F2F2), // #F2F2F2
      // scaffoldBackgroundColor: const Color(0xFF8C808C), // #8C808C

      scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0), // #8C808C
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color.fromARGB(255, 99, 15, 15), // #F2F2F2
        secondary: const Color(0xFF731212), // #731212
        surface: const Color(0xFF8C808C), // #8C808C
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFF2F2F2)), // #F2F2F2
        bodyLarge: TextStyle(
            color: Color(0xFFF2F2F2), fontWeight: FontWeight.bold), // #F2F2F2
        bodyMedium:
            TextStyle(color: Color(0xFFF2F2F2), fontWeight: FontWeight.bold),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: const Color(0xFF010D00), // #010D00
        textTheme: ButtonTextTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF010D00), // #010D00
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFD93030), // #D93030
      ),
    );
  }
}

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
    case '/createService':
      return const CreateServiceScreen();
    case '/showService':
      return const ServicesScreen();
    default:
      return const SplashScreen();
  }
}
