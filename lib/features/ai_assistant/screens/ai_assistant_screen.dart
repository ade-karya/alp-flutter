// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/models/ai_provider.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/services/gemini_openai_service.dart';
import '../../../core/widgets/app_drawer.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  AIProviderType? _expandedProvider;
  final GeminiOpenAIService _geminiService = GeminiOpenAIService();
  final Map<AIProviderType, List<String>> _availableModels = {};
  final Map<AIProviderType, bool> _isLoadingModels = {};
  // Local state for form fields - only saved on "Save & Activate"
  final Map<AIProviderType, String> _localSelectedModels = {};
  final Map<AIProviderType, String> _localUrls = {};
  final Map<AIProviderType, String> _localApiKeys = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.aiAssistantTitle,
          style: TextStyle(
            color: isWizard ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: isWizard ? 'Cinzel' : null,
          ),
        ),
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isWizard ? Colors.white : Colors.black87,
        ),
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active Provider Card
              Container(
                decoration: BoxDecoration(
                  gradient: isWizard
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF4A148C),
                            Color(0xFF7B1FA2),
                          ], // Purple wizard
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isWizard
                          ? const Color(0xFFFFD700).withValues(
                              alpha: 0.3,
                            ) // Gold glow
                          : Colors.blue.withAlpha(100),
                      blurRadius: isWizard ? 15 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isWizard
                      ? Border.all(color: Colors.white24, width: 1)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: isWizard
                              ? Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Icon(
                          _getProviderIcon(state.activeProviderType),
                          size: 32,
                          color: isWizard
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.activeProvider,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontFamily: isWizard ? 'Lato' : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.activeProviderType.displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isWizard
                                    ? const Color(0xFFFFD700)
                                    : Colors.white,
                                fontFamily: isWizard ? 'Cinzel' : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.allProviders,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isWizard ? Colors.white : null,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
              const SizedBox(height: 8),
              // Provider List
              ...AIProviderType.values.map(
                (type) =>
                    _buildProviderCard(context, state, type, l10n, isWizard),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    SettingsState state,
    AIProviderType type,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    final provider = state.providers[type]!;
    final isExpanded = _expandedProvider == type;
    final isActive = state.activeProviderType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isWizard ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isWizard
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActive
            ? Border.all(
                color: isWizard
                    ? const Color(0xFFFFD700)
                    : Colors.blue.withAlpha(100),
                width: 2,
              )
            : isWizard
            ? Border.all(color: Colors.white10)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? (isWizard
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : Colors.blue.withAlpha(25))
                    : (isWizard
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withAlpha(15)),
                borderRadius: BorderRadius.circular(10),
                border: isWizard && isActive
                    ? Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      )
                    : null,
              ),
              child: Icon(
                _getProviderIcon(type),
                color: isActive
                    ? (isWizard ? const Color(0xFFFFD700) : Colors.blue)
                    : (isWizard ? Colors.white70 : Colors.grey[600]),
                size: 24,
              ),
            ),
            title: Text(
              type.displayName,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: isWizard ? Colors.white : Colors.black87,
                fontFamily: isWizard ? 'Cinzel' : null,
              ),
            ),
            subtitle: provider.apiKey.isNotEmpty
                ? Text(
                    'API Key: ••••${provider.apiKey.length > 4 ? provider.apiKey.substring(provider.apiKey.length - 4) : ""}',
                    style: TextStyle(
                      color: isWizard ? Colors.white60 : Colors.grey[600],
                    ),
                  )
                : Text(
                    l10n.noApiKey,
                    style: TextStyle(
                      color: isWizard ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isWizard
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: isWizard
                          ? Border.all(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.5),
                            )
                          : null,
                    ),
                    child: Text(
                      l10n.active,
                      style: TextStyle(
                        color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: isWizard ? 'Cinzel' : null,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isWizard ? Colors.white54 : Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedProvider = isExpanded ? null : type;
              });
            },
          ),
          if (isExpanded)
            _buildExpandedContent(context, provider, l10n, isWizard),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AIProvider provider,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    // Initialize local state from provider if not already set
    _localUrls[provider.type] ??= provider.baseUrl;
    _localApiKeys[provider.type] ??= provider.apiKey;

    final urlController = TextEditingController(
      text: _localUrls[provider.type],
    );
    final apiKeyController = TextEditingController(
      text: _localApiKeys[provider.type],
    );

    InputDecoration buildInputDecoration(String label, {Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isWizard ? Colors.white70 : null),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isWizard ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isWizard
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        hintStyle: TextStyle(color: isWizard ? Colors.white30 : null),
        suffixIcon: suffixIcon,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: isWizard ? Colors.white24 : null),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            style: TextStyle(color: isWizard ? Colors.white : Colors.black87),
            decoration: buildInputDecoration(
              l10n.labelBaseUrl,
            ).copyWith(hintText: provider.type.defaultBaseUrl),
            onChanged: (value) => _localUrls[provider.type] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiKeyController,
            style: TextStyle(color: isWizard ? Colors.white : Colors.black87),
            decoration: buildInputDecoration(
              l10n.labelApiKey,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.visibility_off,
                  color: isWizard ? Colors.white54 : null,
                ),
                onPressed: () {},
              ),
            ),
            obscureText: true,
            onChanged: (value) => _localApiKeys[provider.type] = value,
          ),
          const SizedBox(height: 12),
          // Model Selection
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _localSelectedModels[provider.type] ??
                      provider.selectedModel ??
                      provider.type.defaultModel,
                  isExpanded: true,
                  dropdownColor: isWizard
                      ? const Color(0xFF2E004B)
                      : Colors.white,
                  style: TextStyle(
                    color: isWizard ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: buildInputDecoration(l10n.labelModel),
                  items: () {
                    final current =
                        _localSelectedModels[provider.type] ??
                        provider.selectedModel ??
                        provider.type.defaultModel;
                    final available = _availableModels[provider.type];
                    var items = available?.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model, overflow: TextOverflow.ellipsis),
                      );
                    }).toList();

                    if (items == null || items.isEmpty) {
                      return [
                        DropdownMenuItem(
                          value: current,
                          child: Text(current, overflow: TextOverflow.ellipsis),
                        ),
                      ];
                    }

                    // Ensure current value is in the list
                    final hasCurrent = items.any(
                      (item) => item.value == current,
                    );
                    if (!hasCurrent) {
                      items.insert(
                        0,
                        DropdownMenuItem(
                          value: current,
                          child: Text(
                            '$current (Active)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                    return items;
                  }(),
                  onChanged: (value) {
                    if (value != null) {
                      // Store locally instead of updating Bloc immediately
                      setState(() {
                        _localSelectedModels[provider.type] = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_isLoadingModels[provider.type] == true)
                const CircularProgressIndicator()
              else
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isWizard ? const Color(0xFFFFD700) : null,
                  ),
                  tooltip: l10n.fetchModels,
                  onPressed: () => _fetchModels(
                    provider.type,
                    apiKeyController.text,
                    urlController.text,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Reset to default URL
                    _localUrls[provider.type] = provider.type.defaultBaseUrl;
                    urlController.text = provider.type.defaultBaseUrl;
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.resetUrl),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isWizard
                        ? const Color(0xFFFFD700)
                        : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    var finalUrl =
                        _localUrls[provider.type] ?? provider.baseUrl;
                    if (provider.type == AIProviderType.ollama &&
                        finalUrl.isNotEmpty &&
                        !finalUrl.endsWith('/v1')) {
                      finalUrl = '$finalUrl/v1';
                    }

                    final settingsCubit = context.read<SettingsCubit>();
                    await settingsCubit.updateProvider(
                      type: provider.type,
                      baseUrl: finalUrl,
                      apiKey: _localApiKeys[provider.type] ?? provider.apiKey,
                      isEnabled: true,
                      selectedModel: _localSelectedModels[provider.type],
                    );
                    await settingsCubit.setActiveProvider(provider.type);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.providerSaved)),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.saveAndActivate),
                  style: FilledButton.styleFrom(
                    backgroundColor: isWizard
                        ? const Color(0xFF4A148C)
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: isWizard
                        ? const BorderSide(color: Colors.white24)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(AIProviderType type) {
    switch (type) {
      case AIProviderType.gemini:
        return Icons.auto_awesome;
      case AIProviderType.grok:
        return Icons.psychology;
      case AIProviderType.claude:
        return Icons.chat_bubble;
      case AIProviderType.openai:
        return Icons.smart_toy;
      case AIProviderType.ollama:
        return Icons.computer;
      case AIProviderType.openrouter:
        return Icons.router;
    }
  }

  Future<void> _fetchModels(
    AIProviderType type,
    String apiKey,
    String baseUrl,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (apiKey.isEmpty && type != AIProviderType.ollama) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noApiKey)));
      }
      return;
    }

    setState(() {
      _isLoadingModels[type] = true;
    });

    try {
      var finalUrl = baseUrl.isNotEmpty ? baseUrl : null;
      if (finalUrl != null &&
          type == AIProviderType.ollama &&
          !finalUrl.endsWith('/v1')) {
        finalUrl = '$finalUrl/v1';
      }

      final models = await _geminiService.fetchModels(
        apiKey,
        baseUrl: finalUrl,
      );
      if (mounted) {
        setState(() {
          _availableModels[type] = models;
          _isLoadingModels[type] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${models.length} models')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels[type] = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
