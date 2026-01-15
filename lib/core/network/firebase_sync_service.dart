import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/models/user_model.dart';

/// Firebase-based sync service for internet connectivity
/// Replaces local P2P when devices are not on same network
class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Create a sync session (Teacher)
  Future<String> createSession({
    required User teacher,
    required Map<String, dynamic> classData,
  }) async {
    try {
      // Generate unique session code (6 digits)
      final sessionCode = _generateSessionCode();
      
      final sessionData = {
        'sessionCode': sessionCode,
        'teacherId': teacher.id,
        'teacherName': teacher.name,
        'teacherIdentifier': teacher.identifier,
        'classData': classData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'connectedStudents': <String, dynamic>{},
      };
      
      await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .set(sessionData);
      
      debugPrint('Firebase Session created: $sessionCode');
      return sessionCode;
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }
  
  /// Join a sync session (Student)
  Future<Map<String, dynamic>?> joinSession({
    required String sessionCode,
    required User student,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('sync_sessions')
          .doc(sessionCode);
      
      final sessionDoc = await sessionRef.get();
      
      if (!sessionDoc.exists) {
        debugPrint('Session not found: $sessionCode');
        return null;
      }
      
      final sessionData = sessionDoc.data()!;
      
      if (!(sessionData['isActive'] as bool? ?? false)) {
        debugPrint('Session is no longer active');
        return null;
      }
      
      // Add student to connected students
      await sessionRef.update({
        'connectedStudents.${student.id}': {
          'name': student.name,
          'identifier': student.identifier,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      });
      
      debugPrint('Student joined session: $sessionCode');
      return sessionData;
    } catch (e) {
      debugPrint('Error joining session: $e');
      return null;
    }
  }
  
  /// Get class data from session (Student)
  Future<Map<String, dynamic>?> getClassData(String sessionCode) async {
    try {
      final sessionDoc = await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .get();
      
      if (!sessionDoc.exists) return null;
      
      final data = sessionDoc.data()!;
      return data['classData'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting class data: $e');
      return null;
    }
  }
  
  /// Sync assignments to session (Teacher)
  Future<void> syncAssignments({
    required String sessionCode,
    required List<Map<String, dynamic>> assignments,
  }) async {
    try {
      await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .update({
        'assignments': assignments,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Assignments synced to session');
    } catch (e) {
      debugPrint('Error syncing assignments: $e');
      rethrow;
    }
  }
  
  /// Get assignments from session (Student)
  Future<List<Map<String, dynamic>>> getAssignments(
    String sessionCode,
  ) async {
    try {
      final sessionDoc = await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .get();
      
      if (!sessionDoc.exists) return [];
      
      final data = sessionDoc.data()!;
      final assignments = data['assignments'] as List?;
      
      if (assignments == null) return [];
      
      return assignments.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting assignments: $e');
      return [];
    }
  }
  
  /// Submit student answer (Student)
  Future<bool> submitAnswer({
    required String sessionCode,
    required int studentId,
    required int assignmentId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final submissionId = '${studentId}_${assignmentId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .collection('submissions')
          .doc(submissionId)
          .set({
        'studentId': studentId,
        'assignmentId': assignmentId,
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Answer submitted: $submissionId');
      return true;
    } catch (e) {
      debugPrint('Error submitting answer: $e');
      return false;
    }
  }
  
  /// Listen to submissions (Teacher)
  Stream<List<Map<String, dynamic>>> listenToSubmissions(
    String sessionCode,
  ) {
    return _firestore
        .collection('sync_sessions')
        .doc(sessionCode)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  
  /// Listen to connected students (Teacher)
  Stream<Map<String, dynamic>> listenToConnectedStudents(
    String sessionCode,
  ) {
    return _firestore
        .collection('sync_sessions')
        .doc(sessionCode)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String, dynamic>{};
      
      final data = doc.data()!;
      return data['connectedStudents'] as Map<String, dynamic>? ?? {};
    });
  }
  
  /// Close session (Teacher)
  Future<void> closeSession(String sessionCode) async {
    try {
      await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .update({
        'isActive': false,
        'closedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Session closed: $sessionCode');
    } catch (e) {
      debugPrint('Error closing session: $e');
    }
  }
  
  /// Leave session (Student)
  Future<void> leaveSession({
    required String sessionCode,
    required int studentId,
  }) async {
    try {
      await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .update({
        'connectedStudents.$studentId': FieldValue.delete(),
      });
      
      debugPrint('Student left session');
    } catch (e) {
      debugPrint('Error leaving session: $e');
    }
  }
  
  /// Generate 6-digit session code
  String _generateSessionCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }
  
  /// Check if session exists and is active
  Future<bool> isSessionActive(String sessionCode) async {
    try {
      final doc = await _firestore
          .collection('sync_sessions')
          .doc(sessionCode)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      return data['isActive'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
