// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.aiAssistantTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(100),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProviderIcon(state.activeProviderType),
                          size: 32,
                          color: Colors.white,
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
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.activeProviderType.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Provider List
              ...AIProviderType.values.map(
                (type) => _buildProviderCard(context, state, type, l10n),
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
  ) {
    final provider = state.providers[type]!;
    final isExpanded = _expandedProvider == type;
    final isActive = state.activeProviderType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActive
            ? Border.all(color: Colors.blue.withAlpha(100), width: 2)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.blue.withAlpha(25)
                    : Colors.grey.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getProviderIcon(type),
                color: isActive ? Colors.blue : Colors.grey[600],
                size: 24,
              ),
            ),
            title: Text(
              type.displayName,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            subtitle: provider.apiKey.isNotEmpty
                ? Text(
                    'API Key: ••••${provider.apiKey.length > 4 ? provider.apiKey.substring(provider.apiKey.length - 4) : ""}',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                : Text(
                    l10n.noApiKey,
                    style: TextStyle(color: Colors.grey[500]),
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
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.active,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedProvider = isExpanded ? null : type;
              });
            },
          ),
          if (isExpanded) _buildExpandedContent(context, provider, l10n),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AIProvider provider,
    AppLocalizations l10n,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: l10n.labelBaseUrl,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: provider.type.defaultBaseUrl,
            ),
            onChanged: (value) => _localUrls[provider.type] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: l10n.labelApiKey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility_off),
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
                  decoration: InputDecoration(
                    labelText: l10n.labelModel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
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
                  icon: const Icon(Icons.refresh),
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
                    // Reset to default URL - update local state and controller
                    _localUrls[provider.type] = provider.type.defaultBaseUrl;
                    urlController.text = provider.type.defaultBaseUrl;
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.resetUrl),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
