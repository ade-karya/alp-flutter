import 'dart:convert';

/// Enum representing supported AI providers
enum AIProviderType { gemini, grok, claude, openai, ollama, openrouter }

/// Extension to get display name and default URL for each provider
extension AIProviderTypeExtension on AIProviderType {
  String get displayName {
    switch (this) {
      case AIProviderType.gemini:
        return 'Google Gemini';
      case AIProviderType.grok:
        return 'Grok (xAI)';
      case AIProviderType.claude:
        return 'Claude (Anthropic)';
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.ollama:
        return 'Ollama (Local)';
      case AIProviderType.openrouter:
        return 'OpenRouter';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/openai';
      case AIProviderType.grok:
        return 'https://api.x.ai/v1';
      case AIProviderType.claude:
        return 'https://api.anthropic.com/v1';
      case AIProviderType.openai:
        return 'https://api.openai.com/v1';
      case AIProviderType.ollama:
        return 'http://localhost:11434/v1';
      case AIProviderType.openrouter:
        return 'https://openrouter.ai/api/v1';
    }
  }

  String get defaultModel {
    switch (this) {
      case AIProviderType.gemini:
        return 'gemini-2.0-flash-exp';
      case AIProviderType.grok:
        return 'grok-beta';
      case AIProviderType.claude:
        return 'claude-3-sonnet-20240229';
      case AIProviderType.openai:
        return 'gpt-4o';
      case AIProviderType.ollama:
        return 'llama3';
      case AIProviderType.openrouter:
        return 'google/gemini-2.0-flash-exp:free';
    }
  }

  String get iconName {
    switch (this) {
      case AIProviderType.gemini:
        return 'auto_awesome';
      case AIProviderType.grok:
        return 'psychology';
      case AIProviderType.claude:
        return 'chat_bubble';
      case AIProviderType.openai:
        return 'smart_toy';
      case AIProviderType.ollama:
        return 'computer';
      case AIProviderType.openrouter:
        return 'router';
    }
  }
}

/// Model representing an AI provider configuration
class AIProvider {
  final AIProviderType type;
  final String baseUrl;
  final String apiKey;
  final bool isEnabled;
  final String? selectedModel;

  const AIProvider({
    required this.type,
    required this.baseUrl,
    this.apiKey = '',
    this.isEnabled = false,
    this.selectedModel,
  });

  /// Create a default provider configuration
  factory AIProvider.defaultConfig(AIProviderType type) {
    return AIProvider(
      type: type,
      baseUrl: type.defaultBaseUrl,
      apiKey: '',
      isEnabled: false,
      selectedModel: type.defaultModel,
    );
  }

  AIProvider copyWith({
    String? baseUrl,
    String? apiKey,
    bool? isEnabled,
    String? selectedModel,
  }) {
    return AIProvider(
      type: type,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'isEnabled': isEnabled,
      'selectedModel': selectedModel,
    };
  }

  factory AIProvider.fromJson(Map<String, dynamic> json) {
    final type = AIProviderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AIProviderType.gemini,
    );
    return AIProvider(
      type: type,
      baseUrl: json['baseUrl'] ?? type.defaultBaseUrl,
      apiKey: json['apiKey'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      selectedModel: json['selectedModel'] ?? type.defaultModel,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AIProvider.fromJsonString(String jsonString) {
    return AIProvider.fromJson(jsonDecode(jsonString));
  }
}
