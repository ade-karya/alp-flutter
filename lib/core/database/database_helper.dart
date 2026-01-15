import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/models/user_model.dart';

class DatabaseHelper {
  // Stream to notify listeners about class data changes (members, assignments, etc.)
  // Emits the classId that was updated.
  final _classUpdateController = StreamController<int>.broadcast();
  Stream<int> get onClassUpdate => _classUpdateController.stream;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on Web. Use Firestore paths.',
      );
    }
    if (_database != null) return _database!;
    _database = await _initDB('alp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        role TEXT NOT NULL,
        pin TEXT,
        apiKey TEXT,
        selectedModel TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        class_pin TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE class_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        joined_at TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(class_id, student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL,
        class_id INTEGER,
        type TEXT NOT NULL,
        topic TEXT NOT NULL,
        grade TEXT NOT NULL,
        question_text TEXT NOT NULL,
        option_a TEXT,
        option_b TEXT,
        option_c TEXT,
        option_d TEXT,
        correct_answer TEXT,
        rubric TEXT,
        feedback TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
        CREATE TABLE assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_id INTEGER NOT NULL,
          class_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          scheduled_at TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          is_published INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE assignment_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assignment_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          FOREIGN KEY (assignment_id) REFERENCES assignments (id) ON DELETE CASCADE,
          FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE submissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assignment_id INTEGER NOT NULL,
          student_id INTEGER NOT NULL,
          submitted_at TEXT NOT NULL,
          score REAL,
          feedback TEXT,
          FOREIGN KEY (assignment_id) REFERENCES assignments (id) ON DELETE CASCADE,
          FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE student_answers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          submission_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          answer TEXT,
          FOREIGN KEY (submission_id) REFERENCES submissions (id) ON DELETE CASCADE,
          FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
        )
      ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN pin TEXT');
    }
    if (oldVersion < 3) {
      // Version 3: Class Management
      await db.execute('''
        CREATE TABLE classes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          class_pin TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE class_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          student_id INTEGER NOT NULL,
          joined_at TEXT NOT NULL,
          FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
          FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE,
          UNIQUE(class_id, student_id)
        )
      ''');
    }
    if (oldVersion < 4) {
      // Version 4: Question Bank
      await db.execute('''
        CREATE TABLE questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_id INTEGER NOT NULL,
          class_id INTEGER,
          type TEXT NOT NULL,
          topic TEXT NOT NULL,
          grade TEXT NOT NULL,
          question_text TEXT NOT NULL,
          option_a TEXT,
          option_b TEXT,
          option_c TEXT,
          option_d TEXT,
          correct_answer TEXT,
          rubric TEXT,
          feedback TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Version 5: Scheduled Exams & Assignments
      await db.execute('''
        CREATE TABLE assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_id INTEGER NOT NULL,
          class_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          scheduled_at TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          is_published INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (teacher_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE assignment_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assignment_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          FOREIGN KEY (assignment_id) REFERENCES assignments (id) ON DELETE CASCADE,
          FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE submissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assignment_id INTEGER NOT NULL,
          student_id INTEGER NOT NULL,
          submitted_at TEXT NOT NULL,
          score REAL,
          feedback TEXT,
          FOREIGN KEY (assignment_id) REFERENCES assignments (id) ON DELETE CASCADE,
          FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE student_answers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          submission_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          answer TEXT,
          FOREIGN KEY (submission_id) REFERENCES submissions (id) ON DELETE CASCADE,
          FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      // Version 6: Add is_published to assignments if not exists
      try {
        await db.execute(
          'ALTER TABLE assignments ADD COLUMN is_published INTEGER DEFAULT 1',
        );
      } catch (e) {
        // Column might already exist
      }
    }
  }

  Future<User?> getUserByIdentifier(String identifier) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('users')
          .where('identifier', isEqualTo: identifier)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      var user = User.fromFirestore(snapshot.docs.first);
      // Ensure local ID is populated if stored in Firestore
      final data = snapshot.docs.first.data();
      if (data.containsKey('id')) {
        user = user.copyWith(id: data['id'] as int?);
      }
      return user;
    }
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'identifier = ?',
      whereArgs: [identifier],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      var user = User.fromFirestore(snapshot.docs.first);
      final data = snapshot.docs.first.data();
      if (data.containsKey('id')) {
        user = user.copyWith(id: data['id'] as int?);
      }
      return user;
    }
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllUsers() async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        var user = User.fromFirestore(doc);
        final data = doc.data();
        if (data.containsKey('id')) {
          user = user.copyWith(id: data['id'] as int?);
        }
        return user;
      }).toList();
    }
    final db = await database;
    final maps = await db.query('users', orderBy: 'createdAt DESC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<bool> hasAnyUser() async {
    if (kIsWeb) {
      final snapshot = await _firestore.collection('users').limit(1).get();
      return snapshot.docs.isNotEmpty;
    }
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty;
  }

  Future<int> createUser(User user) async {
    if (kIsWeb) {
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final data = user.toFirestore();
      data['id'] = newId; // Store local ID mapping
      // Use standard auto-ID for document, but map 'id' field
      await _firestore.collection('users').add(data);
      return newId;
    }
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: user.id)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        final data = user.toFirestore();
        // keep existing ID
        data['id'] = user.id;
        await doc.reference.update(data);
        count++;
      }
      return count;
    }
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: id)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        count++;
      }
      return count;
    }
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Class Management Methods ---

  Future<int> createClass({
    required int teacherId,
    required String name,
    required String description,
    required String pin,
  }) async {
    if (kIsWeb) {
      final int newId = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('classes').add({
        'id': newId,
        'teacher_id': teacherId,
        'name': name,
        'description': description,
        'class_pin': pin,
        'created_at': DateTime.now().toIso8601String(),
      });
      return newId;
    }
    final db = await database;
    return await db.insert('classes', {
      'teacher_id': teacherId,
      'name': name,
      'description': description,
      'class_pin': pin,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTeacherClasses(int teacherId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('classes')
          .where('teacher_id', isEqualTo: teacherId)
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    }
    final db = await database;
    return await db.query(
      'classes',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getClassByPin(String pin) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('classes')
          .where('class_pin', isEqualTo: pin)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    }
    final db = await database;
    final maps = await db.query(
      'classes',
      where: 'class_pin = ?',
      whereArgs: [pin],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> joinClass(int studentId, int classId) async {
    if (kIsWeb) {
      await _firestore.collection('class_members').add({
        'class_id': classId,
        'student_id': studentId,
        'joined_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await database;
    await db.insert('class_members', {
      'class_id': classId,
      'student_id': studentId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isStudentEnrolled(int studentId, int classId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('class_members')
          .where('class_id', isEqualTo: classId)
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    }
    final db = await database;
    final result = await db.query(
      'class_members',
      where: 'class_id = ? AND student_id = ?',
      whereArgs: [classId, studentId],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getStudentClasses(int studentId) async {
    if (kIsWeb) {
      // 1. Get class IDs (without orderBy to avoid composite index requirement)
      final memberSnapshot = await _firestore
          .collection('class_members')
          .where('student_id', isEqualTo: studentId)
          .get();

      final classes = <Map<String, dynamic>>[];
      for (final memberDoc in memberSnapshot.docs) {
        final classId = memberDoc.data()['class_id'] as int;
        final joinedAt = memberDoc.data()['joined_at'] as String?;

        // 2. Get Class
        final classSnapshot = await _firestore
            .collection('classes')
            .where('id', isEqualTo: classId)
            .limit(1)
            .get();

        if (classSnapshot.docs.isNotEmpty) {
          final classData = Map<String, dynamic>.from(
            classSnapshot.docs.first.data(),
          );
          classData['joined_at'] = joinedAt;

          // 3. Get Teacher Name
          final teacherId = classData['teacher_id'] as int;
          final userSnapshot = await _firestore
              .collection('users')
              .where('id', isEqualTo: teacherId)
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            classData['teacher_name'] = userSnapshot.docs.first.data()['name'];
          } else {
            classData['teacher_name'] = 'Unknown';
          }
          classes.add(classData);
        }
      }

      // Sort by joined_at descending (manual sort to avoid composite index)
      classes.sort((a, b) {
        final aDate = a['joined_at'] as String? ?? '';
        final bDate = b['joined_at'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

      return classes;
    }
    final db = await database;
    // Join classes with users (teacher) to get teacher name
    return await db.rawQuery(
      '''
      SELECT c.*, u.name as teacher_name 
      FROM classes c
      INNER JOIN class_members cm ON c.id = cm.class_id
      INNER JOIN users u ON c.teacher_id = u.id
      WHERE cm.student_id = ?
      ORDER BY cm.joined_at DESC
    ''',
      [studentId],
    );
  }

  Future<List<Map<String, dynamic>>> getClassMembers(int classId) async {
    if (kIsWeb) {
      final memberSnapshot = await _firestore
          .collection('class_members')
          .where('class_id', isEqualTo: classId)
          .orderBy('joined_at', descending: true)
          .get();

      final members = <Map<String, dynamic>>[];
      for (final memberDoc in memberSnapshot.docs) {
        final studentId = memberDoc.data()['student_id'] as int;
        final joinedAt = memberDoc.data()['joined_at'];

        final userSnapshot = await _firestore
            .collection('users')
            .where('id', isEqualTo: studentId)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first.data();
          userData['joined_at'] = joinedAt;
          members.add(userData);
        }
      }
      return members;
    }
    final db = await database;
    // Join users to get student details
    return await db.rawQuery(
      '''
      SELECT u.*, cm.joined_at
      FROM users u
      INNER JOIN class_members cm ON u.id = cm.student_id
      WHERE cm.class_id = ?
      ORDER BY cm.joined_at DESC
    ''',
      [classId],
    );
  }

  // --- Question Bank Methods ---

  Future<int> createQuestion(Map<String, dynamic> question) async {
    if (kIsWeb) {
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final data = Map<String, dynamic>.from(question);
      data['id'] = newId;
      await _firestore.collection('questions').add(data);
      return newId;
    }
    final db = await database;
    return await db.insert('questions', question);
  }

  Future<List<int>> createQuestions(
    List<Map<String, dynamic>> questions,
  ) async {
    if (kIsWeb) {
      final ids = <int>[];
      final batch = _firestore.batch();
      for (final q in questions) {
        final int newId =
            DateTime.now().millisecondsSinceEpoch + ids.length; // Ensure unique
        final data = Map<String, dynamic>.from(q);
        data['id'] = newId;
        final docRef = _firestore.collection('questions').doc(); // Auto-ID doc
        batch.set(docRef, data);
        ids.add(newId);
      }
      await batch.commit();
      return ids;
    }
    final db = await database;
    final ids = <int>[];
    for (final q in questions) {
      final id = await db.insert('questions', q);
      ids.add(id);
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> getTeacherQuestions(
    int teacherId, {
    String? type,
  }) async {
    if (kIsWeb) {
      Query query = _firestore
          .collection('questions')
          .where('teacher_id', isEqualTo: teacherId);
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      final snapshot = await query
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
    }
    final db = await database;
    if (type != null) {
      return await db.query(
        'questions',
        where: 'teacher_id = ? AND type = ?',
        whereArgs: [teacherId, type],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query(
      'questions',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateQuestion(int id, Map<String, dynamic> question) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('questions')
          .where('id', isEqualTo: id)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.update(question);
        count++;
      }
      return count;
    }
    final db = await database;
    return await db.update(
      'questions',
      question,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('questions')
          .where('id', isEqualTo: id)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        count++;
      }
      return count;
    }
    final db = await database;
    return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Assignment Methods ---

  Future<int> createAssignment({
    required int teacherId,
    required int classId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required int durationMinutes,
    required List<int> questionIds,
  }) async {
    if (kIsWeb) {
      final int assignmentId = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('assignments').add({
        'id': assignmentId,
        'teacher_id': teacherId,
        'class_id': classId,
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'created_at': DateTime.now().toIso8601String(),
        'is_published': 1,
      });

      for (final qId in questionIds) {
        await _firestore.collection('assignment_questions').add({
          'assignment_id': assignmentId,
          'question_id': qId,
        });
      }
      _classUpdateController.add(classId);
      return assignmentId;
    }
    final db = await database;
    final result = await db.transaction((txn) async {
      final assignmentId = await txn.insert('assignments', {
        'teacher_id': teacherId,
        'class_id': classId,
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final qId in questionIds) {
        await txn.insert('assignment_questions', {
          'assignment_id': assignmentId,
          'question_id': qId,
        });
      }
      return assignmentId;
    });

    // Notify listeners
    _classUpdateController.add(classId);

    return result;
  }

  Future<List<Map<String, dynamic>>> getAssignmentsForClass(int classId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('assignments')
          .where('class_id', isEqualTo: classId)
          .orderBy('scheduled_at', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    }
    final db = await database;
    return await db.query(
      'assignments',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'scheduled_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getAssignmentWithDetails(
    int assignmentId,
  ) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('assignments')
          .where('id', isEqualTo: assignmentId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final assignment = snapshot.docs.first.data();

      // Get assignment_questions
      final linkSnapshot = await _firestore
          .collection('assignment_questions')
          .where('assignment_id', isEqualTo: assignmentId)
          .get();

      final questions = <Map<String, dynamic>>[];
      for (final linkDoc in linkSnapshot.docs) {
        final qId = linkDoc.data()['question_id'] as int;
        final qSnapshot = await _firestore
            .collection('questions')
            .where('id', isEqualTo: qId)
            .limit(1)
            .get();
        if (qSnapshot.docs.isNotEmpty) {
          questions.add(qSnapshot.docs.first.data());
        }
      }
      return {...assignment, 'questions': questions};
    }
    final db = await database;
    final assignments = await db.query(
      'assignments',
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
    if (assignments.isEmpty) return null;

    final assignment = assignments.first;

    // Get questions
    final questions = await db.rawQuery(
      '''
      SELECT q.* 
      FROM questions q
      INNER JOIN assignment_questions aq ON q.id = aq.question_id
      WHERE aq.assignment_id = ?
    ''',
      [assignmentId],
    );

    return {...assignment, 'questions': questions};
  }

  Future<int> createSubmission({
    required int assignmentId,
    required int studentId,
    required Map<int, String> answers, // questionId -> answer
    double? initialScore,
  }) async {
    if (kIsWeb) {
      final int submissionId = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('submissions').add({
        'id': submissionId,
        'assignment_id': assignmentId,
        'student_id': studentId,
        'submitted_at': DateTime.now().toIso8601String(),
        'score': initialScore,
      });

      for (final entry in answers.entries) {
        await _firestore.collection('student_answers').add({
          'submission_id': submissionId,
          'question_id': entry.key,
          'answer': entry.value,
        });
      }
      return submissionId;
    }
    final db = await database;
    return await db.transaction((txn) async {
      final submissionId = await txn.insert('submissions', {
        'assignment_id': assignmentId,
        'student_id': studentId,
        'submitted_at': DateTime.now().toIso8601String(),
        'score': initialScore,
      });

      for (final entry in answers.entries) {
        await txn.insert('student_answers', {
          'submission_id': submissionId,
          'question_id': entry.key,
          'answer': entry.value,
        });
      }
      return submissionId;
    });
  }

  Future<Map<String, dynamic>?> getStudentSubmission(
    int assignmentId,
    int studentId,
  ) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('submissions')
          .where('assignment_id', isEqualTo: assignmentId)
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    }
    final db = await database;
    final submissions = await db.query(
      'submissions',
      where: 'assignment_id = ? AND student_id = ?',
      whereArgs: [assignmentId, studentId],
    );
    if (submissions.isEmpty) return null;
    return submissions.first;
  }

  Future<List<Map<String, dynamic>>> getSubmissionsForAssignment(
    int assignmentId,
  ) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('submissions')
          .where('assignment_id', isEqualTo: assignmentId)
          .orderBy('submitted_at', descending: true)
          .get();

      final result = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final studentId = data['student_id'] as int;

        final userSnapshot = await _firestore
            .collection('users')
            .where('id', isEqualTo: studentId)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first.data();
          data['student_name'] = userData['name'];
          data['student_identifier'] = userData['identifier'];
          result.add(data);
        }
      }
      return result;
    }
    final db = await database;
    // Join with users to get student names
    return await db.rawQuery(
      '''
      SELECT s.*, u.name as student_name, u.identifier as student_identifier
      FROM submissions s
      INNER JOIN users u ON s.student_id = u.id
      WHERE s.assignment_id = ?
      ORDER BY s.submitted_at DESC
    ''',
      [assignmentId],
    );
  }

  Future<List<Map<String, dynamic>>> getStudentAnswersWithQuestions(
    int submissionId,
  ) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('student_answers')
          .where('submission_id', isEqualTo: submissionId)
          .get();

      final result = <Map<String, dynamic>>[];
      for (final ansDoc in snapshot.docs) {
        final ansData = ansDoc.data();
        final qId = ansData['question_id'] as int;

        final qSnapshot = await _firestore
            .collection('questions')
            .where('id', isEqualTo: qId)
            .limit(1)
            .get();

        if (qSnapshot.docs.isNotEmpty) {
          final qData = qSnapshot.docs.first.data();
          result.add({'answer': ansData['answer'], ...qData});
        }
      }
      return result;
    }
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT sa.answer, q.question_text, q.type, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_answer, q.rubric, q.topic
      FROM student_answers sa
      INNER JOIN questions q ON sa.question_id = q.id
      WHERE sa.submission_id = ?
    ''',
      [submissionId],
    );
  }

  Future<int> updateSubmissionScore(
    int submissionId,
    double score,
    String feedback,
  ) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('submissions')
          .where('id', isEqualTo: submissionId)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.update({'score': score, 'feedback': feedback});
        count++;
      }
      return count;
    }
    final db = await database;
    return await db.update(
      'submissions',
      {'score': score, 'feedback': feedback},
      where: 'id = ?',
      whereArgs: [submissionId],
    );
  }

  Future<int> deleteAssignment(int assignmentId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('assignments')
          .where('id', isEqualTo: assignmentId)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        count++;
      }
      return count;
    }
    final db = await database;
    // CASCADE will handle assignment_questions, submissions, student_answers
    return await db.delete(
      'assignments',
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }

  Future<int> deleteClass(int classId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('classes')
          .where('id', isEqualTo: classId)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        count++;
      }
      return count;
    }
    final db = await database;
    // CASCADE will handle enrollments, assignments, and their child records
    return await db.delete('classes', where: 'id = ?', whereArgs: [classId]);
  }

  // --- P2P Sync Methods ---

  /// Sync enrollment from remote student (P2P)
  Future<void> syncEnrollment({
    required int classId,
    required int studentId,
    required String studentName,
    String? studentIdentifier,
  }) async {
    if (kIsWeb) return; // P2P not supported on Web
    final db = await database;
    int localStudentId = studentId;

    // 1. Resolve Student ID locally using Identifier (to avoid ID conflicts)
    if (studentIdentifier != null) {
      final existingUser = await getUserByIdentifier(studentIdentifier);
      if (existingUser != null) {
        if (existingUser.id != null) {
          localStudentId = existingUser.id!;
        }
      } else {
        // Create new remote student record
        localStudentId = await db.insert('users', {
          'name': studentName,
          'identifier': studentIdentifier,
          'role': 'student',
          'dateOfBirth': DateTime.now().toIso8601String(), // Default
          'apiKey': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } else {
      // Fallback: Check if ID exists, if not create dummy
      final student = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [studentId],
      );

      if (student.isEmpty) {
        // Create a placeholder remote student record
        await db.insert('users', {
          'id': studentId,
          'name': studentName,
          'identifier': 'remote_$studentId',
          'role': 'student',
          'dateOfBirth': DateTime.now().toIso8601String(),
          'apiKey': '',
          'createdAt': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Check if enrollment already exists with LOCAL ID
    final existing = await db.query(
      'class_members',
      where: 'class_id = ? AND student_id = ?',
      whereArgs: [classId, localStudentId],
    );

    if (existing.isEmpty) {
      // Create enrollment
      await db.insert('class_members', {
        'class_id': classId,
        'student_id': localStudentId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Notify listeners
      _classUpdateController.add(classId);
    }
  }

  Future<void> removeStudentFromClass(int classId, int studentId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('class_members')
          .where('class_id', isEqualTo: classId)
          .where('student_id', isEqualTo: studentId)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return;
    }
    final db = await database;
    await db.delete(
      'class_members',
      where: 'class_id = ? AND student_id = ?',
      whereArgs: [classId, studentId],
    );
    _classUpdateController.add(classId);
  }

  /// Get all assignments for a class (for P2P sync)
  Future<List<Map<String, dynamic>>> getClassAssignments(int classId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('assignments')
          .where('class_id', isEqualTo: classId)
          .orderBy('scheduled_at', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    }
    final db = await database;
    return await db.query(
      'assignments',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'scheduled_at DESC',
    );
  }

  /// Get questions linked to an assignment (for P2P sync)
  Future<List<Map<String, dynamic>>> getAssignmentQuestions(
    int assignmentId,
  ) async {
    if (kIsWeb) {
      final linkSnapshot = await _firestore
          .collection('assignment_questions')
          .where('assignment_id', isEqualTo: assignmentId)
          .get();

      final questions = <Map<String, dynamic>>[];
      for (final linkDoc in linkSnapshot.docs) {
        final qId = linkDoc.data()['question_id'] as int;
        final qSnapshot = await _firestore
            .collection('questions')
            .where('id', isEqualTo: qId)
            .limit(1)
            .get();
        if (qSnapshot.docs.isNotEmpty) {
          questions.add(qSnapshot.docs.first.data());
        }
      }
      return questions;
    }
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT q.* FROM questions q
      INNER JOIN assignment_questions aq ON q.id = aq.question_id
      WHERE aq.assignment_id = ?
      ORDER BY q.id
    ''',
      [assignmentId],
    );
  }

  /// Save a student answer (for P2P sync)
  Future<int> saveStudentAnswer({
    required int submissionId,
    required int questionId,
    required String answer,
  }) async {
    if (kIsWeb) {
      await _firestore.collection('student_answers').add({
        'submission_id': submissionId,
        'question_id': questionId,
        'answer': answer,
      });
      return 1;
    }
    final db = await database;
    return await db.insert('student_answers', {
      'submission_id': submissionId,
      'question_id': questionId,
      'answer': answer,
    });
  }

  /// Create a simple submission record without answers (for P2P sync)
  Future<int> createSimpleSubmission({
    required int assignmentId,
    required int studentId,
  }) async {
    if (kIsWeb) {
      final int submissionId = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('submissions').add({
        'id': submissionId,
        'assignment_id': assignmentId,
        'student_id': studentId,
        'submitted_at': DateTime.now().toIso8601String(),
        'score': null,
        'feedback': null,
      });
      return submissionId;
    }
    final db = await database;
    return await db.insert('submissions', {
      'assignment_id': assignmentId,
      'student_id': studentId,
      'submitted_at': DateTime.now().toIso8601String(),
      'score': null,
      'feedback': null,
    });
  }

  /// Save remote class locally and enroll student (for P2P sync - student side)
  /// This creates a local copy of the class for offline access
  Future<void> saveRemoteClassAndEnroll({
    required Map<String, dynamic> remoteClass,
    required int studentId,
    String? teacherName,
  }) async {
    if (kIsWeb) return; // P2P Not supported
    final db = await database;

    final classId = remoteClass['id'] as int;
    final teacherId = remoteClass['teacher_id'] as int;

    // Check if class already exists locally
    final existing = await db.query(
      'classes',
      where: 'id = ?',
      whereArgs: [classId],
    );

    if (existing.isEmpty) {
      // First, ensure teacher exists in users table (as remote reference)
      final teacherExists = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [teacherId],
      );

      if (teacherExists.isEmpty) {
        await db.insert('users', {
          'id': teacherId,
          'name': teacherName ?? 'Guru (Remote)',
          'identifier': 'remote_teacher_$teacherId',
          'role': 'teacher',
          'dateOfBirth': '', // Placeholder
          'apiKey': '',
          'createdAt': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // Save the class locally
      await db.insert('classes', {
        'id': classId,
        'teacher_id': teacherId,
        'name': remoteClass['name'] ?? 'Unknown Class',
        'description': remoteClass['description'] ?? '',
        'class_pin': remoteClass['class_pin'] ?? '',
        'created_at':
            remoteClass['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Check if already enrolled in class_members
    final enrolled = await db.query(
      'class_members',
      where: 'class_id = ? AND student_id = ?',
      whereArgs: [classId, studentId],
    );

    if (enrolled.isEmpty) {
      await db.insert('class_members', {
        'class_id': classId,
        'student_id': studentId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Save remote assignments with questions locally (for P2P sync - student side)
  Future<void> saveRemoteAssignmentsWithQuestions({
    required List<Map<String, dynamic>> assignments,
    required Future<List<Map<String, dynamic>>> Function(int) getQuestions,
  }) async {
    if (kIsWeb) return; // P2P Not supported
    final db = await database;

    for (final assignment in assignments) {
      final assignmentId = assignment['id'] as int;

      // Check if assignment already exists
      final existing = await db.query(
        'assignments',
        where: 'id = ?',
        whereArgs: [assignmentId],
      );

      if (existing.isEmpty) {
        // Save assignment
        await db.insert('assignments', {
          'id': assignmentId,
          'teacher_id': assignment['teacher_id'],
          'class_id': assignment['class_id'],
          'title': assignment['title'],
          'description': assignment['description'],
          'scheduled_at': assignment['scheduled_at'],
          'duration_minutes': assignment['duration_minutes'],
          'is_published': assignment['is_published'] ?? 1,
          'created_at':
              assignment['created_at'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Fetch and save questions for this assignment
        final questions = await getQuestions(assignmentId);
        for (final question in questions) {
          final questionId = question['id'] as int;

          final qExists = await db.query(
            'questions',
            where: 'id = ?',
            whereArgs: [questionId],
          );

          if (qExists.isEmpty) {
            await db.insert('questions', {
              'id': questionId,
              'teacher_id': question['teacher_id'],
              'class_id': question['class_id'],
              'type': question['type'],
              'topic': question['topic'] ?? '',
              'grade': question['grade'] ?? '',
              'question_text': question['question_text'],
              'option_a': question['option_a'],
              'option_b': question['option_b'],
              'option_c': question['option_c'],
              'option_d': question['option_d'],
              'correct_answer': question['correct_answer'],
              'rubric': question['rubric'],
              'feedback': question['feedback'],
              'created_at':
                  question['created_at'] ?? DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }

        // Save assignment-question links
        for (final question in questions) {
          await db.insert('assignment_questions', {
            'assignment_id': assignmentId,
            'question_id': question['id'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }
  }
}
