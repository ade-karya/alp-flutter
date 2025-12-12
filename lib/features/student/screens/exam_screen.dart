// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/network_cubit.dart';
import '../../../core/network/sync_client.dart';

class ExamScreen extends StatefulWidget {
  final int assignmentId;

  const ExamScreen({super.key, required this.assignmentId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _questions = [];
  final Map<int, String> _answers = {};

  bool _isLoading = true;
  DateTime? _endTime;
  int _currentIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    final db = DatabaseHelper.instance;
    final assignmentData = await db.getAssignmentWithDetails(
      widget.assignmentId,
    );

    if (assignmentData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ujian tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    final scheduledAt = DateTime.parse(assignmentData['scheduled_at']);
    final durationMin = assignmentData['duration_minutes'] as int;
    final endTime = scheduledAt.add(Duration(minutes: durationMin));
    final now = DateTime.now();

    if (now.isAfter(endTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu ujian sudah berakhir'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    final questions = List<Map<String, dynamic>>.from(
      assignmentData['questions'] as List,
    );

    if (mounted) {
      setState(() {
        _assignment = assignmentData;
        _questions = questions;
        _endTime = endTime;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitExam({bool auto = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = (context.read<AuthCubit>().state as Authenticated).user;
    final db = DatabaseHelper.instance;

    double score = 0;
    int totalScoreable = 0;

    for (final q in _questions) {
      if (q['type'] == 'mc') {
        totalScoreable++;
        final givenAnswer = _answers[q['id']];
        if (givenAnswer == q['correct_answer']) {
          score++;
        }
      }
    }

    final finalScore = totalScoreable > 0
        ? (score / totalScoreable) * 100
        : 0.0;

    try {
      // 1. Save to Local Database (Always do this first for safety)
      await db.createSubmission(
        assignmentId: widget.assignmentId,
        studentId: user.id!,
        answers: _answers,
        initialScore: finalScore,
      );

      // 2. Attempt to Sync with Teacher (P2P)
      bool synced = false;
      String feedbackMessage = 'Disimpan di HP saja (Offline).';

      if (mounted) {
        final networkCubit = context.read<NetworkCubit>();
        final teacherPeers = networkCubit.getTeacherPeers();

        for (final peer in teacherPeers) {
          final host = peer['host'];
          if (host != null) {
            final client = SyncClient(host: host, port: 3000);
            if (await client.ping()) {
              // Prepare answers list for API
              final answersList = _answers.entries
                  .map((e) => {'question_id': e.key, 'answer': e.value})
                  .toList();

              final remoteId = await client.submitAnswers(
                assignmentId: widget.assignmentId,
                studentId: user.id!,
                answers: answersList,
              );

              if (remoteId != null) {
                synced = true;
                feedbackMessage = 'Berhasil dikirim ke Guru!';
                break; // Stop after first successful upload
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auto
                  ? 'Waktu habis! $feedbackMessage'
                  : 'Selesai! $feedbackMessage',
            ),
            backgroundColor: synced ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        final classId = _assignment!['class_id'];
        context.go('/student/courses/$classId/result/${widget.assignmentId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

    final q = _questions[_currentIndex];
    final isMC = q['type'] == 'mc';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _assignment!['title'],
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ExamTimer(
              endTime: _endTime!,
              onTimeUp: () => _submitExam(auto: true),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soal ${_currentIndex + 1} dari ${_questions.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_answers.length} dijawab',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Question navigation chips
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isAnswered = _answers.containsKey(
                  _questions[index]['id'],
                );
                final isCurrent = index == _currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.blue
                            : isAnswered
                            ? Colors.green.withAlpha(25)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? Colors.blue
                              : isAnswered
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : isAnswered
                                ? Colors.green
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Question Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isMC
                                ? Colors.blue.withAlpha(25)
                                : Colors.indigo.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMC ? 'Pilihan Ganda' : 'Essay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMC ? Colors.blue : Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question Text
                    Text(
                      q['question_text'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Answer Options
                    if (isMC)
                      ...['a', 'b', 'c', 'd'].map((option) {
                        final text = q['option_$option'];
                        if (text == null || text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final isSelected = _answers[q['id']] == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: isSelected
                                ? Colors.blue.withAlpha(25)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                setState(() => _answers[q['id']] = option);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          option.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                    else
                      TextField(
                        key: ValueKey(q['id']),
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Ketik jawaban di sini...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (val) {
                          _answers[q['id']] = val;
                        },
                        controller: TextEditingController(
                          text: _answers[q['id']],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _currentIndex--),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Sebelumnya'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _currentIndex < _questions.length - 1
                        ? ElevatedButton.icon(
                            onPressed: () => setState(() => _currentIndex++),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Selanjutnya'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitExam(),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Kumpulkan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExamTimer extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback onTimeUp;

  const ExamTimer({super.key, required this.endTime, required this.onTimeUp});

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final left = widget.endTime.difference(now);
    if (left.inSeconds <= 0) {
      _timer.cancel();
      widget.onTimeUp();
      if (mounted) setState(() => _remaining = Duration.zero);
    } else {
      if (mounted) setState(() => _remaining = left);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = _remaining.inMinutes < 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.withAlpha(25) : Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: isLowTime ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_remaining),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLowTime ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }
}
