import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../services/ai_agent_service.dart';
import '../cubit/ai_agent_cubit.dart';
import '../cubit/ai_agent_state.dart';
import 'dart:convert';
import '../../../core/services/gemini_openai_service.dart';
import '../widgets/ai_agent_chart.dart';
import '../widgets/ai_agent_character.dart';

class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
    return BlocProvider(
      create: (context) => AIAgentCubit(
        agentService: AIAgentService(context.read<GeminiOpenAIService>()),
        settingsCubit: context.read<SettingsCubit>(),
        authCubit: context.read<AuthCubit>(),
        databaseHelper: context.read<DatabaseHelper>(),
      )..startConversation(),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final themeMode = context.watch<ThemeCubit>().state;
          final isForest = themeMode == AppThemeMode.forest;
          const isWizard = true; // Both themes are dark magical
          final accentColor = ThemeHelper.getAccentColor(themeMode);
          final secondaryColor = ThemeHelper.getSecondaryAccentColor(themeMode);

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: accentColor),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondaryColor, secondaryColor.withAlpha(150)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor),
                    ),
                    child: Icon(
                      Icons.support_agent,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Agent Guru',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(isForest ? Icons.forest : Icons.auto_awesome),
                  tooltip: 'Ganti Tema',
                  color: accentColor,
                  onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: accentColor),
                  tooltip: 'Bersihkan percakapan',
                  onPressed: () => context.read<AIAgentCubit>().clearHistory(),
                ),
              ],
            ),
            body: ThemeHelper.wrapWithBackground(
              themeMode,
              _buildChatBody(context, l10n, isWizard, themeMode),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBody(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
    AppThemeMode themeMode,
  ) {
    return BlocConsumer<AIAgentCubit, AIAgentState>(
      listener: (context, state) {
        if (state is AIAgentSuccess) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        List<Map<String, String>> messages = [];
        bool isLoading = state is AIAgentLoading;

        if (state is AIAgentSuccess) {
          messages = state.messages;
        } else if (state is AIAgentError) {
          messages = state.messages;
        }

        return Column(
          children: [
            // Character Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AIAgentCharacter(
                status: state is AIAgentSuccess
                    ? state.status
                    : AIAgentStatus.idle,
                isWizard: isWizard,
                soundLevel: state is AIAgentSuccess ? state.soundLevel : 0.0,
              ),
            ),
            Expanded(
              child: messages.isEmpty && !isLoading
                  ? _buildEmptyState(l10n, isWizard)
                  : _buildChatList(messages, isWizard),
            ),
            if (isLoading) _buildLoadingIndicator(isWizard),
            _buildInputArea(
              context,
              l10n,
              isWizard,
              state is AIAgentSuccess ? state.status : AIAgentStatus.idle,
              state is AIAgentSuccess ? state.activeMicrophone : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isWizard) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isWizard ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Mulai percakapan dengan Agent',
            style: TextStyle(
              color: isWizard ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<Map<String, String>> messages, bool isWizard) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final role = message['role'];
        final isUser = role == 'user';
        final isError = role == 'error';
        final isProcess = role == 'process';

        if (isProcess) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 48, right: 48),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 14,
                  color: isWizard ? Colors.white38 : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['content']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'monospace',
                      color: isWizard ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

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
                          : [Colors.green[400]!, Colors.green[700]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: isWizard && !isError
                        ? Border.all(color: const Color(0xFFFFD700))
                        : null,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.support_agent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content']!,
                        style: TextStyle(
                          color: isUser
                              ? (isWizard
                                    ? const Color(0xFFFFD700)
                                    : Colors.white)
                              : isError
                              ? Colors.red
                              : (isWizard ? Colors.white : Colors.black87),
                          height: 1.5,
                          fontFamily: isWizard && !isError ? 'Lato' : null,
                        ),
                      ),
                      if (message['type'] == 'chart' &&
                          message['data'] != null) ...[
                        const SizedBox(height: 12),
                        AIAgentChart(
                          data: List<Map<String, dynamic>>.from(
                            jsonDecode(message['data']!),
                          ),
                          isWizard: isWizard,
                        ),
                      ],
                    ],
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
                    : [Colors.green[400]!, Colors.green[700]!],
              ),
              borderRadius: BorderRadius.circular(10),
              border: isWizard
                  ? Border.all(color: const Color(0xFFFFD700))
                  : null,
            ),
            child: Icon(
              Icons.support_agent,
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
            child: const Text(
              '...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
    AIAgentStatus status,
    String? activeMicrophone,
  ) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == AIAgentStatus.listening &&
                activeMicrophone != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 14,
                      color: isWizard ? const Color(0xFFFFD700) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktif: $activeMicrophone',
                      style: TextStyle(
                        fontSize: 11,
                        color: isWizard ? Colors.white70 : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                // Voice Command Button
                Container(
                  decoration: BoxDecoration(
                    color: status == AIAgentStatus.listening
                        ? Colors.red
                        : (isWizard
                              ? const Color(0xFF4A148C)
                              : Colors.grey[100]),
                    shape: BoxShape.circle,
                    border: isWizard && status != AIAgentStatus.listening
                        ? Border.all(color: const Color(0xFFFFD700))
                        : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      status == AIAgentStatus.listening
                          ? Icons.stop
                          : Icons.mic,
                      color: status == AIAgentStatus.listening
                          ? Colors.white
                          : (isWizard
                                ? const Color(0xFFFFD700)
                                : Colors.grey[700]),
                    ),
                    onPressed: () {
                      final cubit = context.read<AIAgentCubit>();
                      if (status == AIAgentStatus.listening) {
                        cubit.stopListening();
                      } else {
                        cubit.startListening();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isWizard
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: isWizard
                          ? Border.all(color: Colors.white24)
                          : null,
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: isWizard ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: status == AIAgentStatus.listening
                            ? 'Mendengarkan...'
                            : 'Tanyakan sesuatu atau beri perintah...',
                        hintStyle: TextStyle(
                          color: isWizard ? Colors.white54 : Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (val) {
                        context.read<AIAgentCubit>().sendMessage(val);
                        _controller.clear();
                      },
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
                          : [Colors.green[400]!, Colors.green[700]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: isWizard
                        ? Border.all(color: const Color(0xFFFFD700))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isWizard
                            ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                            : Colors.green.withAlpha(100),
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
                    onPressed: () {
                      context.read<AIAgentCubit>().sendMessage(
                        _controller.text,
                      );
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
