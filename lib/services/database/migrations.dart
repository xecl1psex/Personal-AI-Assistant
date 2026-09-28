import 'package:sqflite/sqflite.dart';

/// Schema creation and version migrations for the local database.
class Migrations {
  Migrations._();

  /// Table names.
  static const String tableTransactions = 'transactions';
  static const String tableTasks = 'tasks';
  static const String tableChatMessages = 'chat_messages';
  static const String tableProfile = 'user_profile';

  /// Called on first database creation (version 1).
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL DEFAULT 'expense',
        amount INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        due_date TEXT,
        is_habit INTEGER NOT NULL DEFAULT 0,
        habit_streak INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableChatMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        error INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProfile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT '',
        bio TEXT NOT NULL DEFAULT '',
        avatar_path TEXT,
        currency TEXT NOT NULL DEFAULT 'RUB',
        language_code TEXT NOT NULL DEFAULT 'ru',
        goal_of_day TEXT NOT NULL DEFAULT '',
        birthday TEXT,
        created_at TEXT
      )
    ''');

    // Indexes for common queries.
    await db.execute(
      'CREATE INDEX idx_tx_created ON $tableTransactions (created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_due ON $tableTasks (due_date, completed)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_created ON $tableChatMessages (created_at)',
    );
  }

  /// Incremental migrations between schema versions.
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // TODO: реализация — последовательные миграции:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
    // Пока версия 1 — миграций нет.
  }
}
