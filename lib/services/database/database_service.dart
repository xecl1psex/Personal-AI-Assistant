import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import 'migrations.dart';

/// Singleton wrapper around the local sqflite database.
///
/// All user data (transactions, tasks, chat history, profile) is stored
/// on-device only.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  /// Opens (once) and returns the database.
  Future<Database> get database async {
    if (_db != null) return _db!;
    final String dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, AppConstants.databaseName),
      version: AppConstants.databaseVersion,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );
    return _db!;
  }

  /// Optional warm-up: opens the database ahead of first use.
  Future<void> init() async {
    await database;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  // TODO: реализация — insert через db.insert('transactions', tx.toMap()).
  Future<int?> insertTransaction(Map<String, Object?> transactionMap) async {
    return null;
  }

  // TODO: реализация.
  Future<List<Map<String, Object?>>> queryTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
    int limit = 100,
  }) async {
    return const <Map<String, Object?>>[];
  }

  // TODO: реализация.
  Future<int> updateTransaction(Map<String, Object?> transactionMap) async {
    return 0;
  }

  // TODO: реализация.
  Future<int> deleteTransaction(int id) async {
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  // TODO: реализация.
  Future<int?> insertTask(Map<String, Object?> taskMap) async {
    return null;
  }

  // TODO: реализация.
  Future<List<Map<String, Object?>>> queryTasks({
    bool? completed,
    bool? habitsOnly,
    DateTime? dueOnOrBefore,
    int limit = 200,
  }) async {
    return const <Map<String, Object?>>[];
  }

  // TODO: реализация.
  Future<int> updateTask(Map<String, Object?> taskMap) async {
    return 0;
  }

  // TODO: реализация.
  Future<int> deleteTask(int id) async {
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Chat history
  // ---------------------------------------------------------------------------

  // TODO: реализация.
  Future<int?> insertChatMessage(Map<String, Object?> messageMap) async {
    return null;
  }

  // TODO: реализация.
  Future<List<Map<String, Object?>>> queryChatHistory({int limit = 50}) async {
    return const <Map<String, Object?>>[];
  }

  // TODO: реализация.
  Future<int> clearChatHistory() async {
    return 0;
  }

  // ---------------------------------------------------------------------------
  // User profile (single row, id = 1)
  // ---------------------------------------------------------------------------

  // TODO: реализация.
  Future<Map<String, Object?>?> loadProfile() async {
    return null;
  }

  // TODO: реализация — upsert единственной строки профиля.
  Future<int> saveProfile(Map<String, Object?> profileMap) async {
    return 0;
  }
}
