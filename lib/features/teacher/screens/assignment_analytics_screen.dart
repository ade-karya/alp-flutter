import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/gemini_openai_service.dart';

class AssignmentAnalyticsScreen extends StatefulWidget {
  final int assignmentId;

  const AssignmentAnalyticsScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentAnalyticsScreen> createState() =>
      _AssignmentAnalyticsScreenState();
}

class _AssignmentAnalyticsScreenState extends State<AssignmentAnalyticsScreen> {
  bool _isLoading = true;
  bool _isGrading = false;
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _submissions = [];
  final _geminiService = GeminiOpenAIService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final assignmentData = await db.getAssignmentWithDetails(
      widget.assignmentId,
    );
    final submissions = await db.getSubmissionsForAssignment(
      widget.assignmentId,
    );

    if (mounted) {
      setState(() {
        _assignment = assignmentData;
        _submissions = submissions;
        _isLoading = false;
      });
    }
  }

  Future<void> _gradeAllSubmissions() async {
    if (_isGrading) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated || authState.user.apiKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API Key tidak ditemukan. Atur di Pengaturan.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isGrading = true);
    final db = DatabaseHelper.instance;
    int gradedCount = 0;

    try {
      for (final sub in _submissions) {
        final submissionId = sub['id'] as int;

        final answers = await db.getStudentAnswersWithQuestions(submissionId);
        if (answers.isEmpty) continue;

        final StringBuffer prompt = StringBuffer();
        prompt.writeln('Grade the following student submission.');
        prompt.writeln(
          'Return ONLY a JSON object with this format: {"score": <0-100>, "feedback": "<string>"}',
        );
        prompt.writeln('Strictly follow the rubric/correct answer.');

        for (int i = 0; i < answers.length; i++) {
          final a = answers[i];
          prompt.writeln('\nQuestion ${i + 1}: ${a['question_text']}');
          prompt.writeln('Type: ${a['type']}');
          prompt.writeln('Correct Answer: ${a['correct_answer']}');
          if (a['rubric'] != null) prompt.writeln('Rubric: ${a['rubric']}');
          prompt.writeln('Student Answer: ${a['answer']}');
        }

        try {
          final response = await _geminiService.generateContent(
            apiKey: authState.user.apiKey!,
            model: 'gemini-2.0-flash-exp',
            systemPrompt:
                'You are a strict and precise teacher grading an exam. You must output valid JSON.',
            userMessage: prompt.toString(),
          );

          String cleanResponse = response
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final json = jsonDecode(cleanResponse);

          final double score = (json['score'] as num).toDouble();
          final String feedback = json['feedback'] as String;

          await db.updateSubmissionScore(submissionId, score, feedback);
          gradedCount++;
        } catch (e) {
          debugPrint('Error grading submission $submissionId: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$gradedCount submission berhasil dinilai AI.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGrading = false);
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

    if (_assignment == null) {
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
                'Tugas tidak ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final avgScore = _submissions.isNotEmpty
        ? _submissions
                  .where((s) => s['score'] != null)
                  .map((s) => s['score'] as double)
                  .fold(0.0, (a, b) => a + b) /
              _submissions.where((s) => s['score'] != null).length
        : 0.0;

    final gradedCount = _submissions.where((s) => s['score'] != null).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.indigo[700],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[400]!, Colors.indigo[700]!],
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
                                Icons.analytics,
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
                                    _assignment!['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Analitik & Penilaian',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 14,
                                    ),
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
                              Icons.people,
                              '${_submissions.length} Siswa',
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              Icons.check_circle,
                              '$gradedCount Dinilai',
                            ),
                            const SizedBox(width: 12),
                            if (gradedCount > 0)
                              _buildStatChip(
                                Icons.star,
                                'Rata-rata: ${avgScore.toStringAsFixed(1)}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_submissions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: _isGrading ? null : _gradeAllSubmissions,
                    icon: _isGrading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    tooltip: 'Nilai semua dengan AI',
                  ),
                ),
            ],
          ),
        ],
        body: _submissions.isEmpty
            ? _buildEmptyState()
            : _buildSubmissionList(),
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
              color: Colors.indigo.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox, size: 64, color: Colors.indigo),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada submission',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Siswa belum mengumpulkan jawaban',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final sub = _submissions[index];
        final score = sub['score'] as double?;
        final feedback = sub['feedback'] as String?;
        final submittedAt = DateTime.parse(sub['submitted_at']);

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
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (sub['student_name'] as String)[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              title: Text(
                sub['student_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat('dd MMM yyyy, HH:mm').format(submittedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: score != null
                      ? Colors.green.withAlpha(25)
                      : Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score != null ? score.toStringAsFixed(0) : 'Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: score != null ? 18 : 14,
                    color: score != null ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (feedback != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                    Icons.auto_awesome,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Feedback',
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
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: () {
                          context.go(
                            '/teacher/manage-classes/${_assignment!['class_id']}/assignments/${widget.assignmentId}/analytics/grade/${sub['id']}',
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Nilai Manual'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
