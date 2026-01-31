import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ai_agent_service.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/ai_provider.dart';
import '../../../core/services/gemini_live_service.dart';
import 'ai_agent_state.dart';

/// AI Agent Cubit using Gemini Live API for real-time conversation
class AIAgentCubit extends Cubit<AIAgentState> {
  final AIAgentService _agentService;
  final SettingsCubit _settingsCubit;
  final AuthCubit _authCubit;
  final DatabaseHelper _databaseHelper;

  // Gemini Live service (cloud)
  final GeminiLiveService _geminiLive = GeminiLiveService();

  // Subscriptions
  StreamSubscription? _geminiEventSubscription;

  List<Map<String, String>> _messages = [];
  bool _isGeminiLiveConnected = false;
  String _accumulatedResponse = '';

  AIAgentCubit({
    required AIAgentService agentService,
    required SettingsCubit settingsCubit,
    required AuthCubit authCubit,
    required DatabaseHelper databaseHelper,
  }) : _agentService = agentService,
       _settingsCubit = settingsCubit,
       _authCubit = authCubit,
       _databaseHelper = databaseHelper,
       super(AIAgentInitial()) {
    _setupGeminiEventListener();
  }

  /// Setup listener for Gemini Live events
  void _setupGeminiEventListener() {
    _geminiEventSubscription = _geminiLive.events.listen(_handleGeminiEvent);
  }

  /// Handle events from Gemini Live API
  void _handleGeminiEvent(GeminiLiveEvent event) {
    switch (event) {
      case GeminiLiveConnected():
        debugPrint('AIAgentCubit: Gemini Live connected');
        _isGeminiLiveConnected = true;

      case GeminiLiveDisconnected():
        debugPrint('AIAgentCubit: Gemini Live disconnected');
        _isGeminiLiveConnected = false;
        if (state is AIAgentSuccess) {
          emit(
            (state as AIAgentSuccess).copyWith(
              status: AIAgentStatus.idle,
              isGeminiLiveConnected: false,
            ),
          );
        }

      case GeminiLiveTextResponse(:final text, :final isFinal):
        debugPrint('AIAgentCubit: Text response: "$text" (final: $isFinal)');
        _accumulatedResponse += text;

        if (isFinal && _accumulatedResponse.isNotEmpty) {
          _messages.add({'role': 'ai', 'content': _accumulatedResponse});
          emit(
            AIAgentSuccess(
              messages: List.from(_messages),
              status: AIAgentStatus.idle,
              isGeminiLiveConnected: _isGeminiLiveConnected,
            ),
          );
          _accumulatedResponse = '';
        }

      case GeminiLiveTranscription(:final text):
        debugPrint(
          'AIAgentCubit: Transcription (ignored in hybrid mode): $text',
        );
      // We ignore this in hybrid mode since we use speech_to_text

      case GeminiLiveAudioResponse(:final audioData):
        debugPrint(
          'AIAgentCubit: Audio response received: ${audioData.length} bytes',
        );

      case GeminiLiveError(:final message):
        debugPrint('AIAgentCubit: Gemini Live Error: $message');
        _messages.add({
          'role': 'error',
          'content': 'Gemini Live Error: $message',
        });
        emit(
          AIAgentSuccess(
            messages: List.from(_messages),
            status: AIAgentStatus.idle,
            isGeminiLiveConnected: _isGeminiLiveConnected,
          ),
        );
    }
  }

  /// Connect to Gemini Live API
  Future<bool> _connectToGeminiLive() async {
    if (_isGeminiLiveConnected) return true;

    final settings = _settingsCubit.state;
    final provider = settings.activeProvider;

    if (provider.type != AIProviderType.gemini) {
      debugPrint('Gemini Live only available with Gemini provider');
      return false;
    }

    if (provider.apiKey.isEmpty) {
      _messages.add({
        'role': 'error',
        'content':
            'API Key Gemini tidak ditemukan. Silakan atur di pengaturan.',
      });
      emit(
        AIAgentSuccess(
          messages: List.from(_messages),
          status: AIAgentStatus.idle,
        ),
      );
      return false;
    }

    try {
      await _geminiLive.connect(
        apiKey: provider.apiKey,
        systemInstruction: '''
Anda adalah Asisten AI Sikolah yang membantu guru mengelola kelas dan menganalisa hasil belajar siswa.
Anda dapat:
1. Membuat kelas baru dengan nama dan deskripsi
2. Menganalisa hasil belajar siswa
3. Menjawab pertanyaan terkait pendidikan

Jawab dalam Bahasa Indonesia dengan ramah dan profesional.
Jika diminta membuat kelas, ekstrak nama kelas dan kembalikan JSON: {"action": "CREATE_CLASS", "params": {"name": "...", "description": "..."}}
Jika diminta analisis, kembalikan JSON: {"action": "ANALYZE_LEARNING", "params": {"class": "..."}}
Untuk pertanyaan umum, jawab langsung dengan teks biasa.
''',
      );

      return true;
    } catch (e) {
      debugPrint('AIAgentCubit: Failed to connect to Gemini Live: $e');
      return false;
    }
  }

  void startConversation() {
    _messages = [
      {
        'role': 'ai',
        'content':
            'Halo! Saya Asisten AI Sikolah dengan Gemini Live. Tekan ikon mikrofon untuk berbicara atau ketik pesan Anda.',
      },
    ];
    emit(
      AIAgentSuccess(
        messages: List.from(_messages),
        status: AIAgentStatus.idle,
        isGeminiLiveConnected: _isGeminiLiveConnected,
      ),
    );

    // Try to connect to Gemini Live in background
    _connectToGeminiLive();
  }

  /// Send text message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add({'role': 'user', 'content': text});
    emit(
      AIAgentSuccess(
        messages: List.from(_messages),
        status: AIAgentStatus.thinking,
        isGeminiLiveConnected: _isGeminiLiveConnected,
      ),
    );

    // Try Gemini Live first, fallback to regular API
    if (_isGeminiLiveConnected) {
      _accumulatedResponse = '';
      _geminiLive.sendText(text);
    } else {
      await _sendMessageViaRegularApi(text);
    }
  }

  /// Fallback to regular API
  Future<void> _sendMessageViaRegularApi(String text) async {
    final settings = _settingsCubit.state;
    final provider = settings.activeProvider;
    final authState = _authCubit.state;

    if (authState is! Authenticated) {
      _messages.add({
        'role': 'error',
        'content': 'Anda harus login untuk menggunakan fitur ini.',
      });
      emit(
        AIAgentSuccess(
          messages: List.from(_messages),
          status: AIAgentStatus.idle,
        ),
      );
      return;
    }

    try {
      final response = await _agentService.processCommand(
        apiKey: provider.apiKey,
        model: provider.selectedModel ?? provider.type.defaultModel,
        userMessage: text,
        baseUrl: provider.baseUrl,
      );

      if (response is Map<String, dynamic> && response.containsKey('action')) {
        await _handleAction(response, authState.user.id!);
      } else if (response is String) {
        _messages.add({'role': 'ai', 'content': response});
        emit(
          AIAgentSuccess(
            messages: List.from(_messages),
            status: AIAgentStatus.idle,
          ),
        );
      }
    } catch (e) {
      _messages.add({'role': 'error', 'content': 'Error: ${e.toString()}'});
      emit(
        AIAgentSuccess(
          messages: List.from(_messages),
          status: AIAgentStatus.idle,
        ),
      );
    }
  }

  Future<void> _handleAction(
    Map<String, dynamic> actionMap,
    int teacherId,
  ) async {
    final action = actionMap['action'];
    final params = actionMap['params'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'CREATE_CLASS':
        final name = params['name'] as String?;
        if (name == null || name.isEmpty) {
          _messages.add({
            'role': 'ai',
            'content': 'Nama kelas harus diisi. Apa nama kelasnya?',
          });
        } else {
          final description = params['description'] as String? ?? '';
          final rng = math.Random();
          String pin = List.generate(
            6,
            (_) => rng.nextInt(10).toString(),
          ).join();

          try {
            await _databaseHelper.createClass(
              teacherId: teacherId,
              name: name,
              description: description,
              pin: pin,
            );
            final content = 'Kelas "$name" berhasil dibuat dengan PIN: $pin';
            _messages.add({'role': 'ai', 'content': content});
          } catch (e) {
            _messages.add({
              'role': 'error',
              'content': 'Gagal membuat kelas: $e',
            });
          }
        }
        break;

      case 'ANALYZE_LEARNING':
        final targetClass = params['class'] as String? ?? 'Semua Kelas';
        final List<Map<String, dynamic>> dummyData = [
          {'name': 'Budi Santoso', 'score': 85},
          {'name': 'Siti Aminah', 'score': 92},
          {'name': 'Rian Perkasa', 'score': 78},
        ];
        final content = 'Hasil belajar kelas "$targetClass": Rata-rata 85.';
        _messages.add({
          'role': 'ai',
          'content': content,
          'type': 'chart',
          'data': jsonEncode(dummyData),
        });
        break;

      default:
        _messages.add({
          'role': 'ai',
          'content': 'Fitur belum diimplementasikan.',
        });
    }

    emit(
      AIAgentSuccess(
        messages: List.from(_messages),
        lastExecutedAction: action,
        status: AIAgentStatus.idle,
        isGeminiLiveConnected: _isGeminiLiveConnected,
      ),
    );
  }

  void clearHistory() {
    _messages.clear();
    startConversation();
  }

  @override
  Future<void> close() {
    _geminiEventSubscription?.cancel();
    _geminiLive.dispose();
    return super.close();
  }
}
