import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Manages bidirectional sync between local SQLite and Cloud Firestore.
///
/// Strategy:
/// - **Write-through**: After every local SQLite write, push to Firestore (fire-and-forget)
/// - **Pull on login**: Download all data from Firestore into SQLite on auth
/// - **Conflict resolution**: Last-write-wins based on `updated_at` timestamp
///
/// Firestore structure:  users/{uid}/{table}/{syncId}
class FirestoreSyncManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tables that participate in sync
  static const List<String> syncTables = [
    'classes',
    'class_members',
    'questions',
    'assignments',
    'assignment_questions',
    'submissions',
    'student_answers',
  ];

  // ─── PUSH (Local → Firestore) ───

  /// Push a single record to Firestore after a local SQLite write.
  /// Called in fire-and-forget mode — errors are logged but not thrown.
  void pushRecord({
    required String table,
    required Map<String, dynamic> data,
    required String uid,
    String? syncId,
  }) {
    // Run in background, don't await
    _pushRecordAsync(table: table, data: data, uid: uid, syncId: syncId);
  }

  Future<void> _pushRecordAsync({
    required String table,
    required Map<String, dynamic> data,
    required String uid,
    String? syncId,
  }) async {
    try {
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection(table);

      // Clean data: remove SQLite-only fields
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('sync_id'); // Don't store sync_id in Firestore

      // Ensure updated_at is set
      cleanData['updated_at'] ??= DateTime.now().toIso8601String();

      if (syncId != null && syncId.isNotEmpty) {
        // Update existing document
        await collection.doc(syncId).set(cleanData, SetOptions(merge: true));
      } else {
        // Create new document with auto-ID
        await collection.add(cleanData);
      }
    } catch (e) {
      debugPrint('FirestoreSyncManager: Push failed for $table: $e');
    }
  }

  /// Push a record and return the Firestore document ID (sync_id).
  /// Used when we need to update the local record with the sync_id.
  Future<String?> pushRecordAndGetSyncId({
    required String table,
    required Map<String, dynamic> data,
    required String uid,
    String? syncId,
  }) async {
    try {
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection(table);

      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('sync_id');
      cleanData['updated_at'] ??= DateTime.now().toIso8601String();

      if (syncId != null && syncId.isNotEmpty) {
        await collection.doc(syncId).set(cleanData, SetOptions(merge: true));
        return syncId;
      } else {
        final docRef = await collection.add(cleanData);
        return docRef.id;
      }
    } catch (e) {
      debugPrint('FirestoreSyncManager: Push failed for $table: $e');
      return null;
    }
  }

  /// Delete a record from Firestore.
  void deleteRecord({
    required String table,
    required String uid,
    required String syncId,
  }) {
    _deleteRecordAsync(table: table, uid: uid, syncId: syncId);
  }

  Future<void> _deleteRecordAsync({
    required String table,
    required String uid,
    required String syncId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection(table)
          .doc(syncId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreSyncManager: Delete failed for $table/$syncId: $e');
    }
  }

  // ─── PULL (Firestore → Local SQLite) ───

  /// Pull all data from Firestore into local SQLite.
  /// Called on login/app start.
  Future<void> pullAll({required String uid, required Database db}) async {
    debugPrint('FirestoreSyncManager: Starting full pull for UID=$uid');

    for (final table in syncTables) {
      try {
        await _pullTable(table: table, uid: uid, db: db);
      } catch (e) {
        debugPrint('FirestoreSyncManager: Error pulling $table: $e');
      }
    }

    debugPrint('FirestoreSyncManager: Full pull completed');
  }

  /// Pull a single table from Firestore into SQLite.
  Future<void> _pullTable({
    required String table,
    required String uid,
    required Database db,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(table)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('FirestoreSyncManager: No data in cloud for $table');
      return;
    }

    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    for (final doc in snapshot.docs) {
      final syncId = doc.id;
      final cloudData = doc.data();
      final cloudUpdatedAt = cloudData['updated_at'] as String?;

      // Check if record exists locally by sync_id
      final existing = await db.query(
        table,
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );

      if (existing.isEmpty) {
        // Record doesn't exist locally — also check by local id to avoid dupes
        final localId = cloudData['id'];
        List<Map<String, dynamic>> existingById = [];
        if (localId != null) {
          existingById = await db.query(
            table,
            where: 'id = ?',
            whereArgs: [localId],
          );
        }

        if (existingById.isNotEmpty) {
          // Same ID exists locally — update it with sync_id
          final localUpdatedAt = existingById.first['updated_at'] as String?;
          if (_shouldOverwrite(localUpdatedAt, cloudUpdatedAt)) {
            final updateData = _prepareLocalData(cloudData, syncId);
            updateData.remove('id'); // Don't overwrite local ID
            await db.update(
              table,
              updateData,
              where: 'id = ?',
              whereArgs: [localId],
            );
            updated++;
          } else {
            skipped++;
          }
        } else {
          // Truly new record — insert
          final insertData = _prepareLocalData(cloudData, syncId);
          // Remove auto-increment id so SQLite assigns a new one
          insertData.remove('id');
          try {
            await db.insert(
              table,
              insertData,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            inserted++;
          } catch (e) {
            debugPrint('FirestoreSyncManager: Insert failed for $table: $e');
          }
        }
      } else {
        // Record exists locally — check if cloud is newer
        final localUpdatedAt = existing.first['updated_at'] as String?;
        if (_shouldOverwrite(localUpdatedAt, cloudUpdatedAt)) {
          final updateData = _prepareLocalData(cloudData, syncId);
          updateData.remove('id');
          await db.update(
            table,
            updateData,
            where: 'sync_id = ?',
            whereArgs: [syncId],
          );
          updated++;
        } else {
          skipped++;
        }
      }
    }

    debugPrint(
      'FirestoreSyncManager: $table - inserted: $inserted, updated: $updated, skipped: $skipped',
    );
  }

  /// Push all local unsynced records to Firestore.
  /// Records without a sync_id are considered unsynced.
  Future<void> pushAll({required String uid, required Database db}) async {
    debugPrint('FirestoreSyncManager: Starting full push for UID=$uid');

    for (final table in syncTables) {
      try {
        await _pushTable(table: table, uid: uid, db: db);
      } catch (e) {
        debugPrint('FirestoreSyncManager: Error pushing $table: $e');
      }
    }

    debugPrint('FirestoreSyncManager: Full push completed');
  }

  /// Push all unsynced records from a table to Firestore.
  Future<void> _pushTable({
    required String table,
    required String uid,
    required Database db,
  }) async {
    // Get records that haven't been synced yet
    final unsynced = await db.query(table, where: 'sync_id IS NULL');

    int pushed = 0;

    for (final record in unsynced) {
      final data = Map<String, dynamic>.from(record);
      final localId = data['id'];

      // Set updated_at if missing
      data['updated_at'] ??= DateTime.now().toIso8601String();

      final newSyncId = await pushRecordAndGetSyncId(
        table: table,
        data: data,
        uid: uid,
      );

      if (newSyncId != null && localId != null) {
        // Update local record with the sync_id
        await db.update(
          table,
          {'sync_id': newSyncId},
          where: 'id = ?',
          whereArgs: [localId],
        );
        pushed++;
      }
    }

    if (pushed > 0) {
      debugPrint(
        'FirestoreSyncManager: Pushed $pushed unsynced records from $table',
      );
    }
  }

  // ─── Helpers ───

  /// Check if cloud data should overwrite local data.
  bool _shouldOverwrite(String? localUpdatedAt, String? cloudUpdatedAt) {
    if (localUpdatedAt == null) {
      return true; // Local has no timestamp, cloud wins
    }
    if (cloudUpdatedAt == null) {
      return false; // Cloud has no timestamp, keep local
    }
    return cloudUpdatedAt.compareTo(localUpdatedAt) > 0; // Cloud is newer
  }

  /// Prepare Firestore data for local SQLite insertion.
  Map<String, dynamic> _prepareLocalData(
    Map<String, dynamic> cloudData,
    String syncId,
  ) {
    final localData = Map<String, dynamic>.from(cloudData);
    localData['sync_id'] = syncId;

    // Convert Firestore Timestamps to ISO8601 strings
    for (final key in localData.keys.toList()) {
      if (localData[key] is Timestamp) {
        localData[key] = (localData[key] as Timestamp)
            .toDate()
            .toIso8601String();
      }
    }

    return localData;
  }
}
