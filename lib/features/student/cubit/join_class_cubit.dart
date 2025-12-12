import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/auth/models/user_model.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/network/sync_client.dart';
import 'join_class_state.dart';

class JoinClassCubit extends Cubit<JoinClassState> {
  final NetworkCubit networkCubit;
  final User user;

  JoinClassCubit({required this.networkCubit, required this.user})
    : super(JoinClassInitial());

  Future<void> joinClass({required String pin}) async {
    if (state is JoinClassLoading) return;
    emit(JoinClassLoading());

    try {
      // 1. Check Local DB
      var cls = await DatabaseHelper.instance.getClassByPin(pin);

      // 2. Always try to Sync with P2P Network first (to get latest data)
      // Even if we have it locally, we might need new assignments.
      final teacherPeers = networkCubit.getTeacherPeers();
      bool synced = false;

      for (final peer in teacherPeers) {
        final host = peer['host'];
        if (host != null) {
          final client = SyncClient(host: host, port: 3000); // Default port

          // Ping first
          if (await client.ping()) {
            final remoteCls = await client.getClassByPin(pin);
            if (remoteCls != null) {
              // Found on peer! Enroll
              final enrolled = await client.enrollStudent(
                classId: remoteCls['id'] as int,
                studentId: user.id!,
                studentName: user.name,
                studentIdentifier: user.identifier,
              );

              if (enrolled) {
                // Save locally
                await DatabaseHelper.instance.saveRemoteClassAndEnroll(
                  remoteClass: remoteCls,
                  studentId: user.id!,
                  teacherName: peer['name'] ?? 'Unknown Teacher',
                );

                // Sync assignments
                final assignments = await client.getAssignments(
                  remoteCls['id'] as int,
                );
                if (assignments.isNotEmpty) {
                  await DatabaseHelper.instance
                      .saveRemoteAssignmentsWithQuestions(
                        assignments: assignments,
                        getQuestions: (id) => client.getAssignmentQuestions(id),
                      );
                }

                cls = remoteCls;
                synced = true;
                break; // Stop searching if found and synced
              }
            }
          }
        }
      }

      // 3. Final Verification
      if (cls == null) {
        emit(const JoinClassFailure('Class not found. Check PIN.'));
        return;
      }

      // Ensure local enrollment record exists
      final isEnrolled = await DatabaseHelper.instance.isStudentEnrolled(
        user.id!,
        cls['id'],
      );

      if (!isEnrolled) {
        await DatabaseHelper.instance.joinClass(user.id!, cls['id']);
      } else if (!synced && cls['teacher_name'] != 'Teacher (QR)') {
        // Only warn if we didn't just sync and it looks like a manual re-entry without connection
        // But generally, we want to allow "refreshing" via PIN without error
        // So we can just silently succeed here, taking the user to the class
      }

      emit(JoinClassSuccess(classId: cls['id'], className: cls['name']));
    } catch (e) {
      debugPrint('Join Class Error: $e');
      emit(JoinClassFailure(e.toString()));
    }
  }

  Future<void> joinClassViaQr({
    required String host,
    required int port,
    required String pin,
  }) async {
    if (state is JoinClassLoading) return;
    emit(JoinClassLoading());

    try {
      // Check connectivity first
      final client = SyncClient(host: host, port: port);
      final isAlive = await client.ping();

      if (!isAlive) {
        emit(
          const JoinClassFailure('Could not connect to Teacher. Check WiFi.'),
        );
        return;
      }

      final cls = await client.getClassByPin(pin);
      if (cls == null) {
        emit(const JoinClassFailure('Class not found on Teacher device.'));
        return;
      }

      final enrolled = await client.enrollStudent(
        classId: cls['id'] as int,
        studentId: user.id!,
        studentName: user.name,
        studentIdentifier: user.identifier,
      );

      if (!enrolled) {
        emit(const JoinClassFailure('Enrollment rejected by Teacher.'));
        return;
      }

      // Success - Save Local
      await DatabaseHelper.instance.saveRemoteClassAndEnroll(
        remoteClass: cls,
        studentId: user.id!,
        teacherName: 'Teacher (QR)',
      );

      // FORCE SYNC ASSIGNMENTS
      // Previously this was inside an if block or potentially skipped
      // Now we ensure we always try to fetch them upon join/scan

      final assignments = await client.getAssignments(cls['id'] as int);
      if (assignments.isNotEmpty) {
        await DatabaseHelper.instance.saveRemoteAssignmentsWithQuestions(
          assignments: assignments,
          getQuestions: (id) => client.getAssignmentQuestions(id),
        );
      }

      emit(JoinClassSuccess(classId: cls['id'], className: cls['name']));
    } catch (e) {
      debugPrint('QR Join Error: $e');
      emit(JoinClassFailure(e.toString()));
    }
  }
}
