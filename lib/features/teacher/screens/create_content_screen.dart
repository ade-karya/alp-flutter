import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/services/gemini_openai_service.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/ai_provider.dart';
import '../models/question_model.dart';

enum ContentType { lessonPlan, multipleChoice, essay }

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countController = TextEditingController(
    text: '5',
  );
  final GeminiOpenAIService _geminiService = GeminiOpenAIService();

  ContentType _contentType = ContentType.lessonPlan;
  String _generatedContent = '';
  List<Question> _generatedQuestions = [];
  bool _isLoading = false;

  Future<void> _generateContent() async {
    final l10n = AppLocalizations.of(context)!;
    if (_topicController.text.trim().isEmpty ||
        _gradeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ccSnackBarError)));
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedContent = '';
      _generatedQuestions = [];
    });

    try {
      final settings = context.read<SettingsCubit>().state;
      final provider = settings.activeProvider;
      if (provider.apiKey.isEmpty && provider.type != AIProviderType.ollama) {
        throw Exception(l10n.ccErrorApiKey);
      }

      final count = int.tryParse(_countController.text) ?? 5;
      String prompt;
      String systemPrompt;

      if (_contentType == ContentType.lessonPlan) {
        systemPrompt =
            'You are an expert educational content creator. Create structured and engaging lesson plans.';
        prompt =
            'Create a detailed lesson plan for Grade ${_gradeController.text} students on the topic: "${_topicController.text}". Include learning objectives, activities, and assessment methods.';
      } else if (_contentType == ContentType.multipleChoice) {
        systemPrompt =
            'You are an expert educational assessment creator. Create well-structured multiple choice questions with answer keys and feedback. Always respond with valid JSON only.';
        prompt =
            '''Create $count multiple choice questions for Grade ${_gradeController.text} students on the topic: "${_topicController.text}".

Return ONLY a valid JSON array with this exact structure, no other text:
[
  {
    "question": "Question text here",
    "optionA": "Option A text",
    "optionB": "Option B text",
    "optionC": "Option C text",
    "optionD": "Option D text",
    "correctAnswer": "A",
    "feedback": "Explanation why this answer is correct"
  }
]''';
      } else {
        systemPrompt =
            'You are an expert educational assessment creator. Create well-structured essay questions with scoring rubrics and feedback. Always respond with valid JSON only.';
        prompt =
            '''Create $count essay questions for Grade ${_gradeController.text} students on the topic: "${_topicController.text}".

Return ONLY a valid JSON array with this exact structure, no other text:
[
  {
    "question": "Essay question text here",
    "rubric": "Scoring criteria: 1-2 points for..., 3-4 points for..., 5 points for...",
    "feedback": "Sample answer or key points to look for"
  }
]''';
      }

      final response = await _geminiService.generateContent(
        apiKey: provider.apiKey,
        model: provider.selectedModel ?? provider.type.defaultModel,
        systemPrompt: systemPrompt,
        userMessage: prompt,
        baseUrl: provider.baseUrl,
      );

      if (mounted) {
        if (_contentType == ContentType.lessonPlan) {
          setState(() {
            _generatedContent = response;
            _isLoading = false;
          });
        } else {
          _parseQuestions(response);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMessage = e.toString();
          if (errorMessage.contains('524') ||
              errorMessage.contains('TimeoutException')) {
            errorMessage = l10n.ccErrorTimeout;
          } else {
            errorMessage = l10n.ccErrorGenerating(errorMessage);
          }
          _generatedContent = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  void _parseQuestions(String response) {
    final l10n = AppLocalizations.of(context)!;
    final user = (context.read<AuthCubit>().state as Authenticated).user;

    try {
      String jsonStr = response;
      if (response.contains('```json')) {
        jsonStr = response.split('```json')[1].split('```')[0].trim();
      } else if (response.contains('```')) {
        jsonStr = response.split('```')[1].split('```')[0].trim();
      }

      final List<dynamic> parsed = jsonDecode(jsonStr);
      final questions = <Question>[];

      for (final item in parsed) {
        if (_contentType == ContentType.multipleChoice) {
          questions.add(
            MultipleChoiceQuestion(
              teacherId: user.id!,
              topic: _topicController.text,
              grade: _gradeController.text,
              questionText: item['question'] ?? '',
              optionA: item['optionA'] ?? '',
              optionB: item['optionB'] ?? '',
              optionC: item['optionC'] ?? '',
              optionD: item['optionD'] ?? '',
              correctAnswer: item['correctAnswer'] ?? 'A',
              feedback: item['feedback'] ?? '',
            ),
          );
        } else {
          questions.add(
            EssayQuestion(
              teacherId: user.id!,
              topic: _topicController.text,
              grade: _gradeController.text,
              questionText: item['question'] ?? '',
              rubric: item['rubric'] ?? '',
              feedback: item['feedback'] ?? '',
            ),
          );
        }
      }

      setState(() {
        _generatedQuestions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _generatedContent = '${l10n.ccParseError}\n\nRaw response:\n$response';
        _isLoading = false;
      });
    }
  }

  void _editQuestion(int index) {
    final question = _generatedQuestions[index];
    if (question is MultipleChoiceQuestion) {
      _showEditMCDialog(index, question);
    } else if (question is EssayQuestion) {
      _showEditEssayDialog(index, question);
    }
  }

  void _showEditMCDialog(int index, MultipleChoiceQuestion q) {
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
        title: Text('${l10n.ccEditQuestion} ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(qCtrl, l10n.ccQuestionLabel, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(aCtrl, l10n.ccOptionA),
              const SizedBox(height: 8),
              _buildTextField(bCtrl, l10n.ccOptionB),
              const SizedBox(height: 8),
              _buildTextField(cCtrl, l10n.ccOptionC),
              const SizedBox(height: 8),
              _buildTextField(dCtrl, l10n.ccOptionD),
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
              _buildTextField(fCtrl, l10n.ccFeedback, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _generatedQuestions[index] = q.copyWith(
                  questionText: qCtrl.text,
                  optionA: aCtrl.text,
                  optionB: bCtrl.text,
                  optionC: cCtrl.text,
                  optionD: dCtrl.text,
                  correctAnswer: answer,
                  feedback: fCtrl.text,
                );
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );
  }

  void _showEditEssayDialog(int index, EssayQuestion q) {
    final l10n = AppLocalizations.of(context)!;
    final qCtrl = TextEditingController(text: q.questionText);
    final rCtrl = TextEditingController(text: q.rubric);
    final fCtrl = TextEditingController(text: q.feedback);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${l10n.ccEditQuestion} ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(qCtrl, l10n.ccQuestionLabel, maxLines: 4),
              const SizedBox(height: 12),
              _buildTextField(rCtrl, l10n.ccRubric, maxLines: 4),
              const SizedBox(height: 12),
              _buildTextField(fCtrl, l10n.ccFeedback, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _generatedQuestions[index] = q.copyWith(
                  questionText: qCtrl.text,
                  rubric: rCtrl.text,
                  feedback: fCtrl.text,
                );
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
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

  Future<void> _saveToBank() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final maps = _generatedQuestions
          .map((q) => q.toMap()..remove('id'))
          .toList();
      await DatabaseHelper.instance.createQuestions(maps);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.ccSaved), backgroundColor: Colors.green),
        );
        setState(() {
          _generatedQuestions = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
          l10n.ccTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            _buildHeaderCard(l10n),
            const SizedBox(height: 20),

            // Content Type Selector Card
            _buildContentTypeCard(l10n),
            const SizedBox(height: 20),

            // Input Form Card
            _buildInputFormCard(l10n),
            const SizedBox(height: 20),

            // AI Provider Info
            _buildAIProviderCard(),
            const SizedBox(height: 24),

            // Generate Button
            _buildGenerateButton(l10n),
            const SizedBox(height: 24),

            // Results Section
            if (_contentType == ContentType.lessonPlan)
              _buildLessonPlanResult(l10n)
            else
              _buildQuestionsResult(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buat Konten dengan AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate materi, soal PG, atau essay secara otomatis',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeCard(AppLocalizations l10n) {
    return Container(
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
          Text(
            l10n.ccContentTypeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildContentTypeOption(
                icon: Icons.description,
                label: l10n.ccTypeLessonPlan,
                type: ContentType.lessonPlan,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildContentTypeOption(
                icon: Icons.format_list_numbered,
                label: l10n.ccTypeMultipleChoice,
                type: ContentType.multipleChoice,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildContentTypeOption(
                icon: Icons.edit_note,
                label: l10n.ccTypeEssay,
                type: ContentType.essay,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeOption({
    required IconData icon,
    required String label,
    required ContentType type,
    required Color color,
  }) {
    final isSelected = _contentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _contentType = type;
          _generatedContent = '';
          _generatedQuestions = [];
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFormCard(AppLocalizations l10n) {
    return Container(
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
          const Text(
            'Detail Konten',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              labelText: l10n.ccTopicLabel,
              hintText: l10n.ccTopicHint,
              prefixIcon: const Icon(Icons.topic),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gradeController,
            decoration: InputDecoration(
              labelText: l10n.ccGradeLabel,
              hintText: l10n.ccGradeHint,
              prefixIcon: const Icon(Icons.school),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          if (_contentType != ContentType.lessonPlan) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.ccQuestionCountLabel,
                hintText: l10n.ccQuestionCountHint,
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIProviderCard() {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final provider = state.activeProvider;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withAlpha(50)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.activeProviderType.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (provider.selectedModel != null)
                      Text(
                        provider.selectedModel!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenerateButton(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[700]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateContent,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _contentType == ContentType.lessonPlan
                        ? l10n.ccGenerateButton
                        : l10n.ccGenerateMC,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLessonPlanResult(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 200),
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
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Hasil Generate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            _generatedContent.isEmpty
                ? l10n.ccContentPlaceholder
                : _generatedContent,
            style: TextStyle(
              color: _generatedContent.startsWith('Error')
                  ? Colors.red
                  : Colors.black87,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsResult(AppLocalizations l10n) {
    if (_generatedContent.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withAlpha(50)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _generatedContent,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_generatedQuestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
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
          children: [
            Icon(Icons.quiz, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(l10n.ccNoQuestions, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
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
          Row(
            children: [
              Icon(
                _contentType == ContentType.multipleChoice
                    ? Icons.format_list_numbered
                    : Icons.edit_note,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Soal Dihasilkan (${_generatedQuestions.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _generatedQuestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final q = _generatedQuestions[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          if (q is MultipleChoiceQuestion)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${l10n.ccCorrectAnswer}: ${q.correctAnswer}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.ccTypeEssay,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.purple),
                      onPressed: () => _editQuestion(i),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveToBank,
              icon: const Icon(Icons.save),
              label: Text(l10n.ccSaveToBank),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
