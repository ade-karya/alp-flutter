import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase Sync Client for Students
/// Connects to teacher's data via Firebase (internet connection)
class FirebaseSyncClient {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get class by PIN from Firebase
  Future<Map<String, dynamic>?> getClassByPin(String pin) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting class by PIN: $e');
      return null;
    }
  }

  /// Enroll in class
  Future<bool> enrollStudent({
    required String classId,
    required int studentId,
    required String studentName,
    required String studentIdentifier,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId.toString())
          .set({
        'student_id': studentId,
        'name': studentName,
        'identifier': studentIdentifier,
        'enrolledAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error enrolling student: $e');
      return false;
    }
  }

  /// Get all classes (if needed)
  Future<List<Map<String, dynamic>>> getClasses() async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting classes: $e');
      return [];
    }
  }

  /// Get assignments for a class (real-time stream)
  Stream<List<Map<String, dynamic>>> getAssignments(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get assignment questions
  Future<List<Map<String, dynamic>>> getAssignmentQuestions(
    String classId,
    String assignmentId,
  ) async {
    try {
      final doc = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return (data?['questions'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
      }
      return [];
    } catch (e) {
      debugPrint('Error getting questions: $e');
      return [];
    }
  }

  /// Submit answers
  Future<String?> submitAnswers({
    required String classId,
    required String assignmentId,
    required int studentId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final docRef = await _firestore.collection('submissions').add({
        'class_id': classId,
        'assignment_id': assignmentId,
        'student_id': studentId,
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting answers: $e');
      return null;
    }
  }

  /// Check if teacher is online
  Future<bool> ping() async {
    try {
      // Just check Firebase connection
      await _firestore.collection('_health').doc('check').get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
