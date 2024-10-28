import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:io'; // For File and Directory access

final Logger _logger = Logger(level: Level.debug);

class DBHelper {
  static Database? _db;

  /// **Get Database Instance (Lazy Loading)**
  static Future<Database?> get database async {
    if (_db != null) return _db;
    await initializeDatabase();
    return _db;
  }

  /// **Initialize Database (Copy from Assets if Needed)**
  static Future<void> initializeDatabase() async {
    _logger.i("Initializing database...");

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'bibledb.db');

      if (!await databaseExists(path)) {
        _logger.i("Database not found. Copying from assets...");
        await copyDatabaseFromAssets(path);
      } else {
        _logger.i("Database already exists.");
      }

      _db = await openDatabase(path);
      _logger.i('Database opened successfully at $path');

      await _createTables(); // Ensure required tables exist
    } catch (e, stackTrace) {
      _logger.e('Error initializing database: $e\n$stackTrace');
    }
  }

  /// **Copy Prebuilt Database from Assets to Local Path**
  static Future<void> copyDatabaseFromAssets(String path) async {
    try {
      ByteData data = await rootBundle.load('assets/sql/bibledb.db');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      _logger.i('Database copied to $path');
    } catch (e) {
      _logger.e('Error copying database: $e');
    }
  }

  /// **Create Additional Tables (Highlights, Bookmarks)**
  static Future<void> _createTables() async {
    try {
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

      _logger.i('Required tables created successfully.');
    } catch (e) {
      _logger.e('Error creating tables: $e');
    }
  }

  /// **Close Database**
  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _logger.i('Database closed.');
    }
  }

  /// **Fetch Distinct Books from the Bible Table**
  static Future<List<int>> fetchBooks() async {
    Database? db = await database;
    if (db == null) {
      _logger.e('Database not initialized.');
      return [];
    }

    try {
      final List<Map<String, dynamic>> books =
          await db.rawQuery('SELECT DISTINCT Book FROM bible');
      _logger.i('Fetched ${books.length} books.');
      return books.map((book) => book['Book'] as int).toList();
    } catch (e) {
      _logger.e('Error fetching books: $e');
      return [];
    }
  }

  /// **Get Chapter Count for a Specific Book**
  static Future<int> getChapterCount(int bookId) async {
    try {
      Database? db = await database;
      final result = await db!.rawQuery(
        'SELECT COUNT(DISTINCT Chapter) as chapter_count FROM bible WHERE Book = ?',
        [bookId],
      );
      return result.first['chapter_count'] as int;
    } catch (e) {
      _logger.e('Error fetching chapter count: $e');
      return 0;
    }
  }

  /// **Get Verse Count for a Specific Chapter**
  static Future<int> getVerseCount(int bookId, int chapter) async {
    try {
      Database? db = await database;
      final result = await db!.rawQuery(
        'SELECT COUNT(Versecount) as verse_count FROM bible WHERE Book = ? AND Chapter = ?',
        [bookId, chapter],
      );
      return result.first['verse_count'] as int;
    } catch (e) {
      _logger.e('Error fetching verse count: $e');
      return 0;
    }
  }
}
