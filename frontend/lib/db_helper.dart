import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:io'; // For File and Directory access

// Create a logger with customized log level
final Logger _logger = Logger(level: Level.debug);

class DBHelper {
  static Database? _db;

  // Getter for the database
  static Future<Database?> get database async {
    if (_db != null) return _db;
    await initializeDatabase();
    return _db;
  }

  // Initialize SQLite Database by copying prebuilt database from assets
  static Future<void> initializeDatabase() async {
    _logger.i("Initializing database...");

    try {
      // Get the database path
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'bibledb.db');

      // Check if the database exists
      if (!await databaseExists(path)) {
        _logger.i("Database does not exist, copying from assets...");
        await copyDatabaseFromAssets(path);
      } else {
        _logger.i("Database already exists.");
      }

      // Open the database
      _db = await openDatabase(path);
      _logger.i('Database opened successfully at $path');

      // Create the Highlights table if it doesn't exist
      await _db!.execute('''
      CREATE TABLE IF NOT EXISTS Highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        book INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        color TEXT DEFAULT 'yellow',
        isSynced INTEGER NOT NULL DEFAULT 0,
        dateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(id)
      );
    ''');

      // Create the Bookmarks table if it doesn't exist
      await _db!.execute('''
     CREATE TABLE IF NOT EXISTS Bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        book INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        note TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        dateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(id)
      );
    ''');

      _logger.i('Database initialized successfully at $path');
    } catch (e, stackTrace) {
      _logger.e('Error during database initialization: $e\n\n\n: $stackTrace');
    }
  }

  // Function to copy the prebuilt database from assets to the database directory
  static Future<void> copyDatabaseFromAssets(String path) async {
    try {
      // Load the database from the assets
      ByteData data = await rootBundle.load('assets/sql/bibledb.db');

      // Write the database to the local file
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);

      _logger.i('Database copied from assets to $path');
    } catch (e) {
      _logger.e('Error copying database from assets: $e');
    }
  }

  // Optional: Function to close the database
  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _logger.i('Database closed successfully');
    }
  }

  // Function to fetch all books from the Bible database
  static Future<List<int>> fetchBooks() async {
    Database? db = await database;
    if (db == null) {
      _logger.e('Database is not initialized');
      return [];
    }

    try {
      final List<Map<String, dynamic>> books =
          await db.rawQuery('SELECT DISTINCT Book FROM bible');

      _logger.i('Fetched ${books.length} distinct books from "bible" table');
      return books.map((book) => book['Book'] as int).toList();
    } catch (e) {
      _logger.e('Error fetching books: $e');
      return [];
    }
  }
}
