import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../models/question_model.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    if (!mounted) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _questionsFuture = DatabaseHelper.instance.getTeacherQuestions(
        authState.user.id!,
      );
    } else {
      _questionsFuture = Future.value([]);
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(l10n.qbDeleteConfirm),
          ],
        ),
        content: const Text('Soal yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await DatabaseHelper.instance.deleteQuestion(id);
      if (mounted) {
        setState(() {
          _loadQuestions();
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.qbDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          l10n.qbTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari soal...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(text: 'Semua'),
                    Tab(text: l10n.ccTypeMultipleChoice),
                    Tab(text: l10n.ccTypeEssay),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final rawData = snapshot.data ?? [];

          if (rawData.isEmpty) {
            return _buildEmptyState(l10n);
          }

          final allQuestions = rawData;
          final mcQuestions = rawData.where((q) => q['type'] == 'mc').toList();
          final essayQuestions = rawData
              .where((q) => q['type'] == 'essay')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildQuestionList(allQuestions, l10n),
              _buildQuestionList(mcQuestions, l10n),
              _buildQuestionList(essayQuestions, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.qbEmpty,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat soal baru dengan AI di menu Buat Konten',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildQuestionList(
    List<Map<String, dynamic>> rawData,
    AppLocalizations l10n,
  ) {
    if (rawData.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // Group by Topic
    final questionsByTopic = <String, List<Question>>{};
    for (final map in rawData) {
      try {
        final q = Question.fromMap(map);
        // Filter by search query
        if (_searchQuery.isNotEmpty &&
            !q.questionText.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) &&
            !q.topic.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
        if (!questionsByTopic.containsKey(q.topic)) {
          questionsByTopic[q.topic] = [];
        }
        questionsByTopic[q.topic]!.add(q);
      } catch (e) {
        // Skip invalid
      }
    }

    if (questionsByTopic.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: questionsByTopic.length,
      itemBuilder: (context, index) {
        final topic = questionsByTopic.keys.elementAt(index);
        final questions = questionsByTopic[topic]!;

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
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder, color: Colors.purple),
              ),
              title: Text(
                topic,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${questions.length} ${l10n.ccQuestionLabel}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              children: [
                const Divider(height: 1),
                ...questions.map((q) => _buildQuestionTile(q, l10n)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionTile(Question q, AppLocalizations l10n) {
    final isMC = q is MultipleChoiceQuestion;
    return InkWell(
      onTap: () => _showQuestionDetails(q, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMC
                    ? Colors.blue.withAlpha(25)
                    : Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isMC ? 'PG' : 'Essay',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isMC ? Colors.blue : Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelas ${q.grade}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blue,
                  onPressed: () => _editQuestion(q),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: () => _deleteQuestion(q.id!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDetails(Question q, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: q is MultipleChoiceQuestion
                          ? Colors.blue.withAlpha(25)
                          : Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q is MultipleChoiceQuestion ? 'Pilihan Ganda' : 'Essay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: q is MultipleChoiceQuestion
                            ? Colors.blue
                            : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (q is MultipleChoiceQuestion) ...[
                      _buildOptionTile('A', q.optionA, q.correctAnswer),
                      const SizedBox(height: 8),
                      _buildOptionTile('B', q.optionB, q.correctAnswer),
                      const SizedBox(height: 8),
                      _buildOptionTile('C', q.optionC, q.correctAnswer),
                      const SizedBox(height: 8),
                      _buildOptionTile('D', q.optionD, q.correctAnswer),
                    ] else if (q is EssayQuestion) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.checklist,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.ccRubric,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(q.rubric, style: const TextStyle(height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.ccFeedback,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(q.feedback, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String label, String text, String correctAnswer) {
    final isCorrect = label == correctAnswer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withAlpha(25) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey.shade300,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green : Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  void _editQuestion(Question q) {
    if (q is MultipleChoiceQuestion) {
      _showEditMCDialog(q);
    } else if (q is EssayQuestion) {
      _showEditEssayDialog(q);
    }
  }

  void _showEditMCDialog(MultipleChoiceQuestion q) {
    final l10n = AppLocalizations.of(context)!;
    final qCtrl = TextEditingController(text: q.questionText);
    final aCtrl = TextEditingController(text: q.optionA);
    final bCtrl = TextEditingController(text: q.optionB);
    final cCtrl = TextEditingController(text: q.optionC);
    final dCtrl = TextEditingController(text: q.optionD);
    final fCtrl = TextEditingController(text: q.feedback);
    String answer = q.correctAnswer;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(l10n.ccEditQuestion),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(qCtrl, l10n.ccQuestionLabel, maxLines: 3),
              const SizedBox(height: 12),
              _buildEditTextField(aCtrl, l10n.ccOptionA),
              const SizedBox(height: 8),
              _buildEditTextField(bCtrl, l10n.ccOptionB),
              const SizedBox(height: 8),
              _buildEditTextField(cCtrl, l10n.ccOptionC),
              const SizedBox(height: 8),
              _buildEditTextField(dCtrl, l10n.ccOptionD),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: answer,
                decoration: InputDecoration(
                  labelText: l10n.ccCorrectAnswer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: ['A', 'B', 'C', 'D']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => answer = v ?? 'A',
              ),
              const SizedBox(height: 12),
              _buildEditTextField(fCtrl, l10n.ccFeedback, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedQ = q.copyWith(
                questionText: qCtrl.text,
                optionA: aCtrl.text,
                optionB: bCtrl.text,
                optionC: cCtrl.text,
                optionD: dCtrl.text,
                correctAnswer: answer,
                feedback: fCtrl.text,
              );

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              await DatabaseHelper.instance.updateQuestion(
                q.id!,
                updatedQ.toMap()..remove('id'),
              );

              if (mounted) {
                navigator.pop();
                _loadQuestions();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.ccSaved),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showEditEssayDialog(EssayQuestion q) {
    final l10n = AppLocalizations.of(context)!;
    final qCtrl = TextEditingController(text: q.questionText);
    final rCtrl = TextEditingController(text: q.rubric);
    final fCtrl = TextEditingController(text: q.feedback);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Text(l10n.ccEditQuestion),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(qCtrl, l10n.ccQuestionLabel, maxLines: 4),
              const SizedBox(height: 12),
              _buildEditTextField(rCtrl, l10n.ccRubric, maxLines: 4),
              const SizedBox(height: 12),
              _buildEditTextField(fCtrl, l10n.ccFeedback, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedQ = q.copyWith(
                questionText: qCtrl.text,
                rubric: rCtrl.text,
                feedback: fCtrl.text,
              );

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              await DatabaseHelper.instance.updateQuestion(
                q.id!,
                updatedQ.toMap()..remove('id'),
              );

              if (mounted) {
                navigator.pop();
                _loadQuestions();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.ccSaved),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
