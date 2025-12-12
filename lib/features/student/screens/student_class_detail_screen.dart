import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../teacher/models/class_model.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final int classId;

  const StudentClassDetailScreen({super.key, required this.classId});

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  ClassModel? _class;
  String? _teacherName;
  List<Map<String, dynamic>> _assignments = [];
  final Map<int, Map<String, dynamic>> _submissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = (context.read<AuthCubit>().state as Authenticated).user;
    final db = DatabaseHelper.instance;

    final database = await db.database;
    final classRes = await database.query(
      'classes',
      where: 'id = ?',
      whereArgs: [widget.classId],
    );

    if (classRes.isNotEmpty) {
      _class = ClassModel.fromMap(classRes.first);

      // Get teacher name
      final teacherRes = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [_class!.teacherId],
      );
      if (teacherRes.isNotEmpty) {
        _teacherName = teacherRes.first['name'] as String?;
      }

      _assignments = await db.getAssignmentsForClass(widget.classId);

      for (final a in _assignments) {
        final sub = await db.getStudentSubmission(a['id'], user.id!);
        if (sub != null) {
          _submissions[a['id']] = sub;
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }
    if (_class == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Kelas tidak ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final completedCount = _submissions.values
        .where((s) => s['score'] != null)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.teal[700],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[400]!, Colors.teal[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.book,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _class!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_teacherName != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: Colors.white.withAlpha(200),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _teacherName!,
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(200),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.assignment,
                              '${_assignments.length} Tugas',
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              Icons.check_circle,
                              '$completedCount Selesai',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _assignments.isEmpty
            ? _buildEmptyState()
            : _buildAssignmentList(),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, size: 64, color: Colors.teal),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada tugas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Guru belum memberikan tugas untuk kelas ini',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final a = _assignments[index];
          final scheduledAt = DateTime.parse(a['scheduled_at']);
          final duration = a['duration_minutes'];
          final now = DateTime.now();

          final isStarted = now.isAfter(scheduledAt);
          final submission = _submissions[a['id']];
          final isCompleted = submission != null;
          final score = submission?['score'];

          Color statusColor;
          IconData statusIcon;
          String statusText;

          if (isCompleted && score != null) {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Selesai';
          } else if (isCompleted) {
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_bottom;
            statusText = 'Menunggu Nilai';
          } else if (isStarted) {
            statusColor = Colors.blue;
            statusIcon = Icons.play_circle_fill;
            statusText = 'Mulai';
          } else {
            statusColor = Colors.grey;
            statusIcon = Icons.lock_clock;
            statusText = 'Terkunci';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isCompleted) {
                    if (score != null) {
                      context.go(
                        '/student/courses/${widget.classId}/result/${a['id']}',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Sedang dinilai. Harap tunggu.'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } else if (isStarted) {
                    context.go(
                      '/student/courses/${widget.classId}/exam/${a['id']}',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted && score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (score as num).toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            )
                          else if (isStarted && !isCompleted)
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue,
                              size: 18,
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          _buildAssignmentInfo(
                            Icons.calendar_today,
                            DateFormat('dd MMM yyyy').format(scheduledAt),
                          ),
                          const SizedBox(width: 16),
                          _buildAssignmentInfo(
                            Icons.access_time,
                            DateFormat.jm().format(scheduledAt),
                          ),
                          const SizedBox(width: 16),
                          _buildAssignmentInfo(Icons.timer, '$duration menit'),
                        ],
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dikumpulkan: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(submission['submitted_at']))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
