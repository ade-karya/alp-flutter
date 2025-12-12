import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

/// P2P Sync Server - runs on teacher device to serve class data
class SyncServer {
  HttpServer? _server;
  final int port;
  final int teacherId;

  SyncServer({required this.teacherId, this.port = 3000});

  bool get isRunning => _server != null;

  Future<String?> start() async {
    if (_server != null) return null;

    final router = Router();

    // GET /api/ping - Health check
    router.get('/api/ping', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'role': 'teacher', 'teacherId': teacherId}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // GET /api/class/:pin - Get class by PIN (for students to join)
    router.get('/api/class/<pin>', (Request request, String pin) async {
      try {
        final classData = await DatabaseHelper.instance.getClassByPin(pin);
        if (classData == null) {
          return Response.notFound(
            jsonEncode({'error': 'Class not found'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.ok(
          jsonEncode(classData),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // POST /api/enroll - Enroll student in class
    router.post('/api/enroll', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final classId = data['class_id'] as int;
        final studentId = data['student_id'] as int;
        final studentName = data['student_name'] as String;

        // Create or sync enrollment
        await DatabaseHelper.instance.syncEnrollment(
          classId: classId,
          studentId: studentId,
          studentName: studentName,
        );

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // GET /api/classes - List teacher's classes
    router.get('/api/classes', (Request request) async {
      try {
        final classes = await DatabaseHelper.instance.getTeacherClasses(
          teacherId,
        );
        return Response.ok(
          jsonEncode(classes),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // GET /api/assignments/:classId - Get assignments for a class
    router.get('/api/assignments/<classId>', (
      Request request,
      String classId,
    ) async {
      try {
        final assignments = await DatabaseHelper.instance.getClassAssignments(
          int.parse(classId),
        );
        return Response.ok(
          jsonEncode(assignments),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // GET /api/assignment-questions/:assignmentId - Get questions for assignment
    router.get('/api/assignment-questions/<assignmentId>', (
      Request request,
      String assignmentId,
    ) async {
      try {
        final questions = await DatabaseHelper.instance.getAssignmentQuestions(
          int.parse(assignmentId),
        );
        return Response.ok(
          jsonEncode(questions),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // POST /api/submit - Submit student answers
    router.post('/api/submit', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final assignmentId = data['assignment_id'] as int;
        final studentId = data['student_id'] as int;
        final answers = (data['answers'] as List).cast<Map<String, dynamic>>();

        // Create submission
        final submissionId = await DatabaseHelper.instance
            .createSimpleSubmission(
              assignmentId: assignmentId,
              studentId: studentId,
            );

        // Save answers
        for (final answer in answers) {
          await DatabaseHelper.instance.saveStudentAnswer(
            submissionId: submissionId,
            questionId: answer['question_id'] as int,
            answer: answer['answer'] as String,
          );
        }

        return Response.ok(
          jsonEncode({'success': true, 'submission_id': submissionId}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Add CORS and logging
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    try {
      debugPrint('SyncServer: Attempting to bind to 0.0.0.0:$port...');
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      debugPrint(
        'SyncServer: Successfully bound to ${_server!.address.address}:${_server!.port}',
      );
      final ip = await _getLocalIp();
      debugPrint('P2P Sync Server running on http://$ip:$port');
      return ip;
    } catch (e, stack) {
      debugPrint('SyncServer: Failed to bind to anyIPv4: $e');
      debugPrint('Stack: $stack');

      // Try binding to localhost as fallback
      try {
        debugPrint('SyncServer: Trying fallback to localhost...');
        _server = await shelf_io.serve(handler, 'localhost', port);
        debugPrint(
          'SyncServer: Bound to localhost:$port (limited to local access only)',
        );
        return 'localhost';
      } catch (e2) {
        debugPrint('SyncServer: Localhost fallback also failed: $e2');

        // Try different port
        try {
          debugPrint('SyncServer: Trying port 8080...');
          _server = await shelf_io.serve(
            handler,
            InternetAddress.anyIPv4,
            8080,
          );
          final ip = await _getLocalIp();
          debugPrint('SyncServer: Bound to $ip:8080');
          return ip;
        } catch (e3) {
          debugPrint('SyncServer: All binding attempts failed: $e3');
          return null;
        }
      }
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    debugPrint('P2P Sync Server stopped');
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type',
  };

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final validInterfaces = <Map<String, dynamic>>[];

      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();

        // Skip VPNs and Virtual Adapters
        if (name.contains('virtual') ||
            name.contains('vmware') ||
            name.contains('vbox') ||
            name.contains('tailscale') ||
            name.contains('zerotier')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (addr.isLoopback ||
              addr.address == '127.0.0.1' ||
              addr.address == '::1') {
            continue;
          }

          // Score detection
          int score = 0;

          // 1. Highest priority: Hotspot (name or default Windows Hotspot IP)
          if (name.contains('hotspot') || addr.address == '192.168.137.1') {
            score += 200;
          }

          // 2. High priority: Wi-Fi names
          if (name.contains('wi-fi') ||
              name.contains('wifi') ||
              name.contains('wlan') ||
              name.contains('wireless')) {
            score += 100;
          }

          // 3. Medium priority: Local Area Connection or Ethernet
          if (name.contains('local area connection') ||
              name.contains('ethernet')) {
            score += 50;
          }

          // 4. Score based on IP subnet (prefer common LAN)
          if (addr.address.startsWith('192.168.')) {
            score += 20;
          }
          if (addr.address.startsWith('10.')) {
            score += 10; // Could be VPN/Enterprise, lower score
          }
          if (addr.address.startsWith('172.')) {
            score += 10;
          }

          validInterfaces.add({
            'ip': addr.address,
            'score': score,
            'name': interface.name,
          });
        }
      }

      // Sort by score descending
      validInterfaces.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int),
      );

      if (validInterfaces.isNotEmpty) {
        final best = validInterfaces.first;
        debugPrint(
          'Best IP found: ${best['ip']} (Score: ${best['score']} on ${best['name']})',
        );
        return best['ip'] as String;
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return '127.0.0.1';
  }
}
