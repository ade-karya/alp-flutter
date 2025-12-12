import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// P2P Sync Client - connects to teacher's sync server
class SyncClient {
  final String host;
  final int port;

  SyncClient({required this.host, this.port = 3000});

  String get baseUrl => 'http://$host:$port';

  /// Check if server is available
  Future<bool> ping() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/ping'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Ping failed: $e');
      return false;
    }
  }

  /// Get class by PIN from teacher's device
  Future<Map<String, dynamic>?> getClassByPin(String pin) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/class/$pin'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Error getting class: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting class by PIN: $e');
      return null;
    }
  }

  /// Enroll student in class on teacher's device
  Future<bool> enrollStudent({
    required int classId,
    required int studentId,
    required String studentName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/enroll'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'class_id': classId,
              'student_id': studentId,
              'student_name': studentName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error enrolling student: $e');
      return false;
    }
  }

  /// Get all classes from teacher
  Future<List<Map<String, dynamic>>> getClasses() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/classes'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting classes: $e');
      return [];
    }
  }

  /// Get assignments for a class
  Future<List<Map<String, dynamic>>> getAssignments(int classId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/assignments/$classId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting assignments: $e');
      return [];
    }
  }

  /// Get questions for an assignment
  Future<List<Map<String, dynamic>>> getAssignmentQuestions(
    int assignmentId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/assignment-questions/$assignmentId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting questions: $e');
      return [];
    }
  }

  /// Submit answers to teacher's device
  Future<int?> submitAnswers({
    required int assignmentId,
    required int studentId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'assignment_id': assignmentId,
              'student_id': studentId,
              'answers': answers,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['submission_id'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Error submitting answers: $e');
      return null;
    }
  }
}
