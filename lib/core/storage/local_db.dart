import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';

/// SQLite database — local message cache and metadata.
class LocalDb {
  LocalDb._();
  static final LocalDb _instance = LocalDb._();
  factory LocalDb() => _instance;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'slink.db');
    AppLogger.info('Initializing local SQLite database at: $path', tag: 'Database');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        AppLogger.info('Creating database tables for version $version', tag: 'Database');
        await db.execute('''
          CREATE TABLE messages (
            id          TEXT PRIMARY KEY,
            chatId      TEXT NOT NULL,
            senderId    TEXT NOT NULL,
            recipientId TEXT,
            content     TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'SENT',
            createdAt   TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_chatId ON messages(chatId)
        ''');

        await db.execute('''
          CREATE TABLE conversations (
            chatId          TEXT PRIMARY KEY,
            participantId   TEXT NOT NULL,
            participantName TEXT NOT NULL,
            lastMessage     TEXT,
            lastMessageTime TEXT,
            unreadCount     INTEGER NOT NULL DEFAULT 0,
            isGroup         INTEGER NOT NULL DEFAULT 0,
            communityId     TEXT,
            communityName   TEXT,
            groupTitle      TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.info('Upgrading database from $oldVersion to $newVersion', tag: 'Database');
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE conversations ADD COLUMN isGroup INTEGER NOT NULL DEFAULT 0');
            await db.execute('ALTER TABLE conversations ADD COLUMN communityId TEXT');
            await db.execute('ALTER TABLE conversations ADD COLUMN communityName TEXT');
            await db.execute('ALTER TABLE conversations ADD COLUMN groupTitle TEXT');
          } catch (e) {
            // Ignore if columns already exist
          }
        }
      },
    );
  }

  // ─── Messages ───────────────────────────────────────────────────
  Future<void> insertMessage(Map<String, dynamic> row) async {
    try {
      final db = await database;
      AppLogger.debug('Inserting/replacing message: ${row['id']} in chat ${row['chatId']}', tag: 'Database');
      await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, st) {
      AppLogger.error('Failed to insert message', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final db = await database;
      AppLogger.debug('Fetching cached messages for chat: $chatId', tag: 'Database');
      final results = await db.query(
        'messages',
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'createdAt ASC',
      );
      AppLogger.debug('Found ${results.length} messages in cache for chat: $chatId', tag: 'Database');
      return results;
    } catch (e, st) {
      AppLogger.error('Failed to fetch messages for chat: $chatId', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      final db = await database;
      AppLogger.debug('Updating status of message: $messageId to $status', tag: 'Database');
      await db.update(
        'messages',
        {'status': status},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e, st) {
      AppLogger.error('Failed to update message status', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final db = await database;
      AppLogger.debug('Deleting message from cache: $messageId', tag: 'Database');
      await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
    } catch (e, st) {
      AppLogger.error('Failed to delete message: $messageId', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Conversations ──────────────────────────────────────────────
  Future<void> upsertConversation(Map<String, dynamic> row) async {
    try {
      final db = await database;
      AppLogger.debug('Upserting conversation in cache: ${row['chatId']}', tag: 'Database');
      await db.insert('conversations', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, st) {
      AppLogger.error('Failed to upsert conversation', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final db = await database;
      AppLogger.debug('Fetching all cached conversations', tag: 'Database');
      final results = await db.query('conversations', orderBy: 'lastMessageTime DESC');
      AppLogger.debug('Found ${results.length} conversations in local cache', tag: 'Database');
      return results;
    } catch (e, st) {
      AppLogger.error('Failed to fetch conversations', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> clearConversations() async {
    try {
      final db = await database;
      AppLogger.info('Clearing all conversations from cache', tag: 'Database');
      await db.delete('conversations');
    } catch (e, st) {
      AppLogger.error('Failed to clear conversations', tag: 'Database', error: e, stackTrace: st);
      rethrow;
    }
  }
}

