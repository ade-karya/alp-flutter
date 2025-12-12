import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import 'package:intl/intl.dart';

class AssignmentResultScreen extends StatefulWidget {
  final int assignmentId;

  const AssignmentResultScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentResultScreen> createState() => _AssignmentResultScreenState();
}

class _AssignmentResultScreenState extends State<AssignmentResultScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _submission;
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _studentAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    final user = (context.read<AuthCubit>().state as Authenticated).user;
    final db = DatabaseHelper.instance;

    final submission = await db.getStudentSubmission(
      widget.assignmentId,
      user.id!,
    );
    final assignmentData = await db.getAssignmentWithDetails(
      widget.assignmentId,
    );

    if (submission == null || assignmentData == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final database = await db.database;
    final answersRes = await database.query(
      'student_answers',
      where: 'submission_id = ?',
      whereArgs: [submission['id']],
    );

    final answersMap = <int, String>{};
    for (final row in answersRes) {
      answersMap[row['question_id'] as int] = row['answer'] as String;
    }

    if (mounted) {
      setState(() {
        _submission = submission;
        _assignment = assignmentData;
        _questions = List<Map<String, dynamic>>.from(
          assignmentData['questions'] as List,
        );
        _studentAnswers = answersMap;
        _isLoading = false;
      });
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
    if (_submission == null) {
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
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Hasil tidak ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final score = _submission!['score'] as double?;
    final feedback = _submission!['feedback'] as String?;

    // Calculate correct answers
    int correctCount = 0;
    int mcCount = 0;
    for (final q in _questions) {
      if (q['type'] == 'mc') {
        mcCount++;
        if (_studentAnswers[q['id']] == q['correct_answer']) {
          correctCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Score Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: score != null
                ? (score >= 80
                      ? Colors.green[700]
                      : score >= 60
                      ? Colors.blue[700]
                      : Colors.orange[700])
                : Colors.grey[700],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: score != null
                        ? (score >= 80
                              ? [Colors.green[400]!, Colors.green[700]!]
                              : score >= 60
                              ? [Colors.blue[400]!, Colors.blue[700]!]
                              : [Colors.orange[400]!, Colors.orange[700]!])
                        : [Colors.grey[400]!, Colors.grey[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          score != null
                              ? (score >= 80
                                    ? Icons.emoji_events
                                    : score >= 60
                                    ? Icons.thumb_up
                                    : Icons.trending_up)
                              : Icons.hourglass_bottom,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (score != null)
                        Text(
                          score.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Text(
                          'Menunggu Nilai',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (score != null)
                        Text(
                          score >= 80
                              ? 'Excellent! 🎉'
                              : score >= 60
                              ? 'Good Job! 👍'
                              : 'Keep Trying! 💪',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (mcCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Benar: $correctCount dari $mcCount PG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        Text(
                          _assignment!['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dikumpulkan: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_submission!['submitted_at']))}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (feedback != null && feedback.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withAlpha(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.feedback,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Feedback',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback,
                                  style: const TextStyle(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Review Section
                  const Text(
                    'Review Jawaban',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Questions List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final q = _questions[index];
              final studentAns = _studentAnswers[q['id']] ?? '';
              final correctAns = q['correct_answer'];
              final isMC = q['type'] == 'mc';
              final isCorrect = isMC && studentAns == correctAns;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMC
                          ? (isCorrect
                                ? Colors.green.withAlpha(100)
                                : studentAns.isEmpty
                                ? Colors.grey.withAlpha(50)
                                : Colors.red.withAlpha(100))
                          : Colors.grey.withAlpha(50),
                      width: 2,
                    ),
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
                      // Question header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMC
                              ? (isCorrect
                                    ? Colors.green.withAlpha(25)
                                    : studentAns.isEmpty
                                    ? Colors.grey.withAlpha(15)
                                    : Colors.red.withAlpha(25))
                              : Colors.indigo.withAlpha(15),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isMC
                                    ? (isCorrect
                                          ? Colors.green
                                          : studentAns.isEmpty
                                          ? Colors.grey
                                          : Colors.red)
                                    : Colors.indigo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMC
                                    ? Colors.blue.withAlpha(25)
                                    : Colors.indigo.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isMC ? 'Pilihan Ganda' : 'Essay',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMC ? Colors.blue : Colors.indigo,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isMC)
                              Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : studentAns.isEmpty
                                    ? Icons.remove_circle
                                    : Icons.cancel,
                                color: isCorrect
                                    ? Colors.green
                                    : studentAns.isEmpty
                                    ? Colors.grey
                                    : Colors.red,
                              ),
                          ],
                        ),
                      ),
                      // Question content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q['question_text'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isMC) ...[
                              _buildAnswerRow(
                                'Jawabanmu',
                                studentAns.isEmpty
                                    ? '(Tidak dijawab)'
                                    : studentAns.toUpperCase(),
                                isCorrect ? Colors.green : Colors.red,
                                isCorrect ? Icons.check : Icons.close,
                              ),
                              if (!isCorrect)
                                _buildAnswerRow(
                                  'Jawaban Benar',
                                  correctAns?.toUpperCase() ?? '-',
                                  Colors.green,
                                  Icons.check_circle,
                                ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jawabanmu:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      studentAns.isEmpty
                                          ? '(Tidak dijawab)'
                                          : studentAns,
                                      style: const TextStyle(height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: score != null
                                      ? Colors.green.withAlpha(25)
                                      : Colors.orange.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      score != null
                                          ? Icons.check_circle
                                          : Icons.hourglass_bottom,
                                      size: 16,
                                      color: score != null
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      score != null
                                          ? 'Sudah Dinilai'
                                          : 'Menunggu Penilaian',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: score != null
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: _questions.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
