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

      // 2. Check P2P Network (if not found locally)
      if (cls == null) {
        final teacherPeers = networkCubit.getTeacherPeers();
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
                          getQuestions: (id) =>
                              client.getAssignmentQuestions(id),
                        );
                  }

                  cls = remoteCls;
                  break; // Stop searching
                }
              }
            }
          }
        }
      }

      if (cls == null) {
        emit(const JoinClassFailure('Class not found. Check PIN.'));
        return;
      }

      // 3. Local Enrollment Check (if class found or existed locally)
      final isEnrolled = await DatabaseHelper.instance.isStudentEnrolled(
        user.id!,
        cls['id'],
      );

      if (isEnrolled && cls['teacher_name'] != 'Teacher (QR)') {
        // Allow re-join for QR updates if needed, but standard flow prevents duplicates
        emit(const JoinClassFailure('You are already enrolled in this class.'));
        return;
      }

      if (!isEnrolled) {
        await DatabaseHelper.instance.joinClass(user.id!, cls['id']);
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
