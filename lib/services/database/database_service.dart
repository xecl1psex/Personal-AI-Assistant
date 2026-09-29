import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../shared/models/chat_message.dart';
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
      onConfigure: (Database db) async {
        // Required for ON DELETE CASCADE on the messages table.
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
  // Chat history (legacy single-table API — kept for compatibility)
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
  // Conversations: chats + messages
  // ---------------------------------------------------------------------------

  /// Create a new conversation and return its row id.
  Future<int> createChat({String title = 'Новый чат'}) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    return db.insert(Migrations.tableChats, <String, Object?>{
      'title': title,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// All conversations, most recently updated first.
  Future<List<Map<String, dynamic>>> getAllChats() async {
    final Database db = await database;
    return db.query(
      Migrations.tableChats,
      orderBy: 'updated_at DESC',
    );
  }

  /// Delete a conversation and (via FK cascade) all of its messages.
  Future<void> deleteChat(int chatId) async {
    final Database db = await database;
    await db.delete(
      Migrations.tableMessages,
      where: 'chat_id = ?',
      whereArgs: <Object?>[chatId],
    );
    await db.delete(
      Migrations.tableChats,
      where: 'id = ?',
      whereArgs: <Object?>[chatId],
    );
  }

  /// Insert a message into its chat and bump the chat's `updated_at`.
  /// Returns the new message row id.
  Future<int> insertMessage(ChatMessage msg) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final ChatMessage toSave = msg.copyWith(createdAt: msg.createdAt ?? DateTime.now());

    final int messageId =
        await db.insert(Migrations.tableMessages, toSave.toMap());

    if (toSave.chatId != null) {
      await db.update(
        Migrations.tableChats,
        <String, Object?>{'updated_at': now},
        where: 'id = ?',
        whereArgs: <Object?>[toSave.chatId],
      );
    }
    return messageId;
  }

  /// Messages of a chat in chronological order.
  Future<List<ChatMessage>> getMessages(int chatId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      Migrations.tableMessages,
      where: 'chat_id = ?',
      whereArgs: <Object?>[chatId],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows
        .map((Map<String, Object?> row) => ChatMessage.fromMap(row))
        .toList(growable: false);
  }

  /// Rename a conversation.
  Future<void> updateChatTitle(int chatId, String title) async {
    final Database db = await database;
    await db.update(
      Migrations.tableChats,
      <String, Object?>{
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[chatId],
    );
  }

  /// Delete all messages of a chat (the chat itself is kept).
  Future<void> clearChat(int chatId) async {
    final Database db = await database;
    await db.delete(
      Migrations.tableMessages,
      where: 'chat_id = ?',
      whereArgs: <Object?>[chatId],
    );
    await db.update(
      Migrations.tableChats,
      <String, Object?>{'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: <Object?>[chatId],
    );
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
