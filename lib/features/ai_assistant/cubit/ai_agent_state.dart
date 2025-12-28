import 'package:equatable/equatable.dart';

enum AIAgentStatus { idle, listening, thinking, speaking }

abstract class AIAgentState extends Equatable {
  const AIAgentState();

  @override
  List<Object?> get props => [];
}

class AIAgentInitial extends AIAgentState {}

class AIAgentLoading extends AIAgentState {}

class AIAgentSuccess extends AIAgentState {
  final List<Map<String, String>> messages;
  final String? lastExecutedAction;
  final AIAgentStatus status;
  final double soundLevel;
  final String? activeMicrophone;
  final bool isGeminiLiveConnected;

  const AIAgentSuccess({
    required this.messages,
    this.lastExecutedAction,
    this.status = AIAgentStatus.idle,
    this.soundLevel = 0.0,
    this.activeMicrophone,
    this.isGeminiLiveConnected = false,
  });

  @override
  List<Object?> get props => [
    messages,
    lastExecutedAction,
    status,
    soundLevel,
    activeMicrophone,
    isGeminiLiveConnected,
  ];

  AIAgentSuccess copyWith({
    List<Map<String, String>>? messages,
    String? lastExecutedAction,
    AIAgentStatus? status,
    double? soundLevel,
    String? activeMicrophone,
    bool? isGeminiLiveConnected,
  }) {
    return AIAgentSuccess(
      messages: messages ?? this.messages,
      lastExecutedAction: lastExecutedAction ?? this.lastExecutedAction,
      status: status ?? this.status,
      soundLevel: soundLevel ?? this.soundLevel,
      activeMicrophone: activeMicrophone ?? this.activeMicrophone,
      isGeminiLiveConnected:
          isGeminiLiveConnected ?? this.isGeminiLiveConnected,
    );
  }
}

class AIAgentError extends AIAgentState {
  final String message;
  final List<Map<String, String>> messages;

  const AIAgentError({required this.message, required this.messages});

  @override
  List<Object?> get props => [message, messages];
}
