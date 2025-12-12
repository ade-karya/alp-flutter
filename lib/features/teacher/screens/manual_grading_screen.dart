import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_helper.dart';

class ManualGradingScreen extends StatefulWidget {
  final int assignmentId;
  final int submissionId;

  const ManualGradingScreen({
    super.key,
    required this.assignmentId,
    required this.submissionId,
  });

  @override
  State<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends State<ManualGradingScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _submission;
  List<Map<String, dynamic>> _answers = [];

  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;

    final submissions = await db.getSubmissionsForAssignment(
      widget.assignmentId,
    );
    final submission = submissions.firstWhere(
      (s) => s['id'] == widget.submissionId,
      orElse: () => {},
    );

    if (submission.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    final answers = await db.getStudentAnswersWithQuestions(
      widget.submissionId,
    );

    if (mounted) {
      setState(() {
        _submission = submission;
        _answers = answers;
        _scoreController.text =
            (submission['score'] as double?)?.toString() ?? '';
        _feedbackController.text = (submission['feedback'] as String?) ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGrading() async {
    if (_isSaving) return;

    final scoreText = _scoreController.text.trim();
    final double? score = double.tryParse(scoreText);

    if (score == null || score < 0 || score > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nilai yang valid (0-100)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = DatabaseHelper.instance;
      await db.updateSubmissionScore(
        widget.submissionId,
        score,
        _feedbackController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nilai berhasil disimpan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penilaian Manual',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _submission!['student_name'],
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grading Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[400]!, Colors.indigo[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grade, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nilai & Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Score Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _scoreController,
                      decoration: InputDecoration(
                        labelText: 'Nilai (0-100)',
                        prefixIcon: const Icon(
                          Icons.star,
                          color: Colors.orange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Feedback Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: 'Feedback untuk Siswa',
                        hintText: 'Berikan komentar atau saran...',
                        prefixIcon: const Icon(
                          Icons.feedback,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveGrading,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.indigo,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Nilai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Answers Review Section
            const Text(
              'Review Jawaban Siswa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_answers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('Tidak ada jawaban tercatat')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _answers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final a = _answers[index];
                  final isMC = a['type'] == 'mc';

                  return Container(
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
                        // Question Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isMC
                                ? Colors.blue.withAlpha(15)
                                : Colors.purple.withAlpha(15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isMC ? Colors.blue : Colors.purple,
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
                                      : Colors.purple.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isMC ? 'Pilihan Ganda' : 'Essay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isMC ? Colors.blue : Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Question Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['question_text'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (isMC) ...[
                                _buildMCOptions(a),
                              ] else ...[
                                _buildEssayAnswer(a),
                              ],

                              const SizedBox(height: 16),
                              // Teacher Reference
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.indigo.withAlpha(30),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.key,
                                          size: 16,
                                          color: Colors.indigo[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Kunci Jawaban',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (isMC)
                                      Text(
                                        'Jawaban Benar: ${a['correct_answer']?.toUpperCase() ?? '-'}',
                                        style: const TextStyle(height: 1.5),
                                      )
                                    else ...[
                                      if (a['correct_answer'] != null &&
                                          a['correct_answer']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          'Jawaban Model: ${a['correct_answer']}',
                                          style: const TextStyle(height: 1.5),
                                        ),
                                      if (a['rubric'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Rubrik: ${a['rubric']}',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCOptions(Map<String, dynamic> answerData) {
    List<MapEntry<String, String>> options = [];

    if (answerData['option_a'] != null) {
      options.add(MapEntry('A', answerData['option_a'].toString()));
    }
    if (answerData['option_b'] != null) {
      options.add(MapEntry('B', answerData['option_b'].toString()));
    }
    if (answerData['option_c'] != null) {
      options.add(MapEntry('C', answerData['option_c'].toString()));
    }
    if (answerData['option_d'] != null) {
      options.add(MapEntry('D', answerData['option_d'].toString()));
    }

    if (options.isEmpty && answerData['options'] != null) {
      try {
        final raw = answerData['options'] as String;
        final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
        final letters = ['A', 'B', 'C', 'D'];
        for (int i = 0; i < jsonList.length && i < 4; i++) {
          options.add(MapEntry(letters[i], jsonList[i].toString()));
        }
      } catch (e) {
        // ignore
      }
    }

    final String studentAnswer = (answerData['answer'] ?? '')
        .toString()
        .toLowerCase();
    final String correctAnswer = (answerData['correct_answer'] ?? '')
        .toString()
        .toLowerCase();

    return Column(
      children: options.map((entry) {
        final optionLetter = entry.key.toLowerCase();
        final optionText = entry.value;

        final isCorrectOption = optionLetter == correctAnswer;
        final isSelectedByStudent = optionLetter == studentAnswer;

        Color bgColor = Colors.grey[100]!;
        Color borderColor = Colors.grey.shade300;
        Color textColor = Colors.grey[800]!;
        IconData? icon;

        if (isCorrectOption) {
          bgColor = Colors.green.withAlpha(25);
          borderColor = Colors.green;
          textColor = Colors.green[800]!;
          icon = Icons.check_circle;
        } else if (isSelectedByStudent && !isCorrectOption) {
          bgColor = Colors.red.withAlpha(25);
          borderColor = Colors.red;
          textColor = Colors.red[800]!;
          icon = Icons.cancel;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: (isSelectedByStudent || isCorrectOption) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCorrectOption
                      ? Colors.green
                      : isSelectedByStudent
                      ? Colors.red
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: (isCorrectOption || isSelectedByStudent)
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
                  optionText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: (isSelectedByStudent || isCorrectOption)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: isCorrectOption ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEssayAnswer(Map<String, dynamic> answerData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Jawaban Siswa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answerData['answer'] ?? '(Tidak dijawab)',
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
