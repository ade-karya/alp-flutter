import 'package:flutter/material.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/wizard_background.dart';
import '../../../core/services/gemini_openai_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/settings/settings_cubit.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/models/ai_provider.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiOpenAIService _geminiService = GeminiOpenAIService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Jelaskan tentang fotosintesis',
    'Bantu saya memahami persamaan kuadrat',
    'Apa itu demokrasi?',
    'Tips belajar efektif',
  ];

  Future<void> _sendMessage([String? customMessage]) async {
    final l10n = AppLocalizations.of(context)!;
    final message = customMessage ?? _controller.text;
    if (message.trim().isEmpty) return;

    final userMessage = message;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final settings = context.read<SettingsCubit>().state;
      final provider = settings.activeProvider;
      if (provider.apiKey.isEmpty && provider.type != AIProviderType.ollama) {
        throw Exception(l10n.aiTutorErrorApiKey);
      }

      final response = await _geminiService.generateContent(
        apiKey: provider.apiKey,
        model: provider.selectedModel ?? provider.type.defaultModel,
        systemPrompt: l10n.aiTutorSystemPrompt,
        userMessage: userMessage,
        baseUrl: provider.baseUrl,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': response});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'error',
            'content': l10n.aiTutorError(e.toString()),
          });
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      return Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen(l10n, isWizard)
                : _buildChatList(l10n, isWizard),
          ),
          if (_isLoading) _buildLoadingIndicator(isWizard),
          _buildInputArea(l10n, isWizard),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isWizard ? Colors.white : Colors.black87,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWizard
                      ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                      : [Colors.blue[400]!, Colors.blue[700]!],
                ),
                borderRadius: BorderRadius.circular(10),
                border: isWizard
                    ? Border.all(color: const Color(0xFFFFD700))
                    : null,
              ),
              child: Icon(
                Icons.smart_toy,
                color: isWizard ? const Color(0xFFFFD700) : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.aiTutorTitle,
              style: TextStyle(
                color: isWizard ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: isWizard ? 'Cinzel' : null,
              ),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isWizard ? const Color(0xFFFFD700) : null,
              ),
              tooltip: 'Mulai percakapan baru',
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
              },
            ),
        ],
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }

  Widget _buildWelcomeScreen(AppLocalizations l10n, bool isWizard) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // AI Avatar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWizard
                    ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                    : [Colors.blue[300]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: isWizard
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : null,
              boxShadow: isWizard
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.blue.withAlpha(100),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Icon(
              Icons.smart_toy,
              color: isWizard ? const Color(0xFFFFD700) : Colors.white,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Halo! Saya AI Tutor 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isWizard ? Colors.white : Colors.black87,
              fontFamily: isWizard ? 'Cinzel' : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanyakan apa saja tentang pelajaranmu',
            style: TextStyle(
              fontSize: 16,
              color: isWizard ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          // Quick prompts
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Coba tanyakan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isWizard ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_quickPrompts.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: isWizard ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _sendMessage(_quickPrompts[index]),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isWizard
                          ? Colors.white.withValues(alpha: 0.1)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: isWizard
                          ? Border.all(color: Colors.white24)
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isWizard
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.blue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: isWizard
                                ? const Color(0xFFFFD700)
                                : Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _quickPrompts[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: isWizard ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isWizard ? Colors.white54 : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatList(AppLocalizations l10n, bool isWizard) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['role'] == 'user';
        final isError = message['role'] == 'error';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isError
                          ? [Colors.red[300]!, Colors.red[600]!]
                          : isWizard
                          ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                          : [Colors.blue[300]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: isWizard && !isError
                        ? Border.all(color: const Color(0xFFFFD700))
                        : null,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.smart_toy,
                    color: isWizard && !isError
                        ? const Color(0xFFFFD700)
                        : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isWizard ? const Color(0xFF4A148C) : Colors.blue)
                        : isError
                        ? Colors.red.withAlpha(25)
                        : (isWizard
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: isWizard
                              ? Colors.black26
                              : Colors.grey.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: isError
                        ? Border.all(color: Colors.red.withAlpha(50))
                        : isUser
                        ? (isWizard
                              ? Border.all(color: const Color(0xFFFFD700))
                              : null)
                        : (isWizard
                              ? Border.all(color: Colors.white24)
                              : Border.all(color: Colors.grey.shade200)),
                  ),
                  child: Text(
                    message['content']!,
                    style: TextStyle(
                      color: isUser
                          ? (isWizard ? const Color(0xFFFFD700) : Colors.white)
                          : isError
                          ? Colors.red
                          : (isWizard ? Colors.white : Colors.black87),
                      height: 1.5,
                      fontFamily: isWizard && !isError ? 'Lato' : null,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWizard
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    color: isWizard ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(bool isWizard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWizard
                    ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                    : [Colors.blue[300]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(10),
              border: isWizard
                  ? Border.all(color: const Color(0xFFFFD700))
                  : null,
            ),
            child: Icon(
              Icons.smart_toy,
              color: isWizard ? const Color(0xFFFFD700) : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isWizard
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isWizard
                  ? Border.all(color: Colors.white24)
                  : Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0, isWizard),
                const SizedBox(width: 4),
                _buildTypingDot(1, isWizard),
                const SizedBox(width: 4),
                _buildTypingDot(2, isWizard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index, bool isWizard) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isWizard ? const Color(0xFFFFD700) : Colors.blue).withAlpha(
              (value * 255).toInt(),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea(AppLocalizations l10n, bool isWizard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWizard ? Colors.black26 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isWizard ? Colors.black12 : Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isWizard
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: isWizard ? Border.all(color: Colors.white24) : null,
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: isWizard ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.aiTutorHint,
                    hintStyle: TextStyle(
                      color: isWizard ? Colors.white54 : Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWizard
                      ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                      : [Colors.blue[400]!, Colors.blue[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: isWizard
                    ? Border.all(color: const Color(0xFFFFD700))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isWizard
                        ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                        : Colors.blue.withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: isWizard ? const Color(0xFFFFD700) : Colors.white,
                ),
                onPressed: () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
