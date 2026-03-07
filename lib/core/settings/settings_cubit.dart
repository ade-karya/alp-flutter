import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/database_helper.dart';
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
  final String? firebaseUid;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SettingsCubit({this.firebaseUid}) : super(SettingsState()) {
    if (firebaseUid != null) {
      _loadSettings();
    }
  }

  /// Reload settings from Firestore/SQLite. Call after manual sync.
  Future<void> reload() => _loadSettings();

  Future<void> _loadSettings() async {
    if (firebaseUid == null) return;
    emit(state.copyWith(isLoading: true));

    try {
      // Try loading from Firestore first (cross-device sync)
      if (!kIsWeb) {
        final loaded = await _loadFromFirestore();
        if (loaded) {
          emit(state.copyWith(isLoading: false));
          // Also cache to SQLite for offline access
          _saveToSQLite();
          return;
        }
      }

      // Fall back to local SQLite
      if (!kIsWeb) {
        await _loadFromSQLite();
      }
      emit(state.copyWith(isLoading: false));

      // Push local settings to Firestore if not yet synced
      if (!kIsWeb) {
        _syncToFirestore();
      }
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load settings: $e'),
      );
    }
  }

  /// Load settings from Firestore
  Future<bool> _loadFromFirestore() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUid)
          .collection('settings')
          .doc('ai_providers')
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      return _parseAndEmit(data);
    } catch (e) {
      debugPrint('SettingsCubit: Failed to load from Firestore: $e');
      return false;
    }
  }

  /// Load settings from local SQLite
  Future<void> _loadFromSQLite() async {
    if (firebaseUid == null) return;

    try {
      final row = await _dbHelper.loadAISettings(userUid: firebaseUid!);
      if (row == null) return;

      final data = {
        'locale': row['locale'],
        'active_provider': row['active_provider'],
        'providers': row['providers_json'] != null
            ? jsonDecode(row['providers_json'] as String)
            : null,
      };
      _parseAndEmit(data);
      debugPrint('SettingsCubit: Loaded AI settings from SQLite');
    } catch (e) {
      debugPrint('SettingsCubit: Failed to load from SQLite: $e');
    }
  }

  /// Parse settings data and emit state
  bool _parseAndEmit(Map<String, dynamic> data) {
    final locale = data['locale'] as String? ?? 'id';
    final activeProviderName = data['active_provider'] as String?;
    final providersData = data['providers'];

    Map<AIProviderType, AIProvider> providers;
    if (providersData != null && providersData is Map<String, dynamic>) {
      providers = {};
      for (var type in AIProviderType.values) {
        if (providersData.containsKey(type.name)) {
          providers[type] = AIProvider.fromJson(
            Map<String, dynamic>.from(providersData[type.name]),
          );
        } else {
          providers[type] = AIProvider.defaultConfig(type);
        }
      }
    } else {
      return false;
    }

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
      ),
    );

    return true;
  }

  /// Save current settings to SQLite (fire-and-forget)
  void _saveToSQLite() {
    if (firebaseUid == null || kIsWeb) return;
    () async {
      try {
        final providersMap = _serializeProviders();
        await _dbHelper.saveAISettings(
          userUid: firebaseUid!,
          providersJson: jsonEncode(providersMap),
          activeProvider: state.activeProviderType.name,
          locale: state.locale,
        );
        debugPrint('SettingsCubit: Saved AI settings to SQLite');
      } catch (e) {
        debugPrint('SettingsCubit: Failed to save to SQLite: $e');
      }
    }();
  }

  /// Sync settings to Firestore (fire-and-forget)
  void _syncToFirestore() {
    if (firebaseUid == null) return;
    () async {
      try {
        final providersMap = _serializeProviders();

        await _firestore
            .collection('users')
            .doc(firebaseUid)
            .collection('settings')
            .doc('ai_providers')
            .set({
              'providers': providersMap,
              'active_provider': state.activeProviderType.name,
              'locale': state.locale,
              'updated_at': DateTime.now().toIso8601String(),
            });

        debugPrint('SettingsCubit: Synced AI settings to Firestore');
      } catch (e) {
        debugPrint('SettingsCubit: Failed to sync to Firestore: $e');
      }
    }();
  }

  /// Save settings to both SQLite and Firestore
  void _saveAll() {
    _saveToSQLite();
    _syncToFirestore();
  }

  /// Serialize providers map to JSON-friendly map
  Map<String, dynamic> _serializeProviders() {
    final Map<String, dynamic> providersMap = {};
    for (var entry in state.providers.entries) {
      providersMap[entry.key.name] = entry.value.toJson();
    }
    return providersMap;
  }

  Future<void> setLocale(String locale) async {
    emit(state.copyWith(locale: locale));
    _saveAll();
  }

  Future<void> setActiveProvider(AIProviderType type) async {
    if (firebaseUid == null) return;
    emit(state.copyWith(activeProviderType: type));
    _saveAll();
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
    _saveAll();
  }

  AIProvider getProvider(AIProviderType type) => state.providers[type]!;

  /// Get list of enabled providers
  List<AIProvider> get enabledProviders =>
      state.providers.values.where((p) => p.isEnabled).toList();
}
