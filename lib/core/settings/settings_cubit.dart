import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';

class SettingsState {
  final String locale;
  final Map<AIProviderType, AIProvider> providers;
  final AIProviderType activeProviderType;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.locale = 'id',
    Map<AIProviderType, AIProvider>? providers,
    this.activeProviderType = AIProviderType.gemini,
    this.isLoading = false,
    this.error,
  }) : providers = providers ?? _defaultProviders();

  static Map<AIProviderType, AIProvider> _defaultProviders() {
    return {
      for (var type in AIProviderType.values)
        type: AIProvider.defaultConfig(type),
    };
  }

  AIProvider get activeProvider => providers[activeProviderType]!;

  SettingsState copyWith({
    String? locale,
    Map<AIProviderType, AIProvider>? providers,
    AIProviderType? activeProviderType,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      providers: providers ?? this.providers,
      activeProviderType: activeProviderType ?? this.activeProviderType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  final int? userId;

  SettingsCubit({this.userId}) : super(SettingsState()) {
    if (userId != null) {
      _loadSettings();
    }
  }

  String _getKey(String key) => userId != null ? 'user_${userId}_$key' : key;

  Future<void> _loadSettings() async {
    if (userId == null) return;

    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString(_getKey('locale')) ?? 'id';
      final activeProviderName = prefs.getString(_getKey('active_provider'));
      final providersJson = prefs.getString(_getKey('providers'));

      // Load providers from storage or use defaults
      Map<AIProviderType, AIProvider> providers;
      if (providersJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(providersJson);
        providers = {};
        for (var type in AIProviderType.values) {
          if (decoded.containsKey(type.name)) {
            providers[type] = AIProvider.fromJson(decoded[type.name]);
          } else {
            providers[type] = AIProvider.defaultConfig(type);
          }
        }
      } else {
        providers = SettingsState._defaultProviders();
      }

      // Parse active provider
      AIProviderType activeType = AIProviderType.gemini;
      if (activeProviderName != null) {
        activeType = AIProviderType.values.firstWhere(
          (e) => e.name == activeProviderName,
          orElse: () => AIProviderType.gemini,
        );
      }

      emit(
        state.copyWith(
          locale: locale,
          providers: providers,
          activeProviderType: activeType,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load settings: $e'),
      );
    }
  }

  Future<void> _saveProviders() async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> providersMap = {};
    for (var entry in state.providers.entries) {
      providersMap[entry.key.name] = entry.value.toJson();
    }
    await prefs.setString(_getKey('providers'), jsonEncode(providersMap));
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey('locale'), locale);
    emit(state.copyWith(locale: locale));
  }

  Future<void> setActiveProvider(AIProviderType type) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey('active_provider'), type.name);
    emit(state.copyWith(activeProviderType: type));
  }

  Future<void> updateProvider({
    required AIProviderType type,
    String? baseUrl,
    String? apiKey,
    bool? isEnabled,
    String? selectedModel,
  }) async {
    final currentProvider = state.providers[type]!;
    final updatedProvider = currentProvider.copyWith(
      baseUrl: baseUrl,
      apiKey: apiKey,
      isEnabled: isEnabled,
      selectedModel: selectedModel,
    );

    final updatedProviders = Map<AIProviderType, AIProvider>.from(
      state.providers,
    );
    updatedProviders[type] = updatedProvider;

    emit(state.copyWith(providers: updatedProviders));
    await _saveProviders();
  }

  AIProvider getProvider(AIProviderType type) => state.providers[type]!;

  /// Get list of enabled providers
  List<AIProvider> get enabledProviders =>
      state.providers.values.where((p) => p.isEnabled).toList();
}
