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
      appBar: AppBar(title: Text(l10n.aiAssistantTitle)),
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
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getProviderIcon(state.activeProviderType),
                        size: 32,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.activeProvider,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              state.activeProviderType.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _getProviderIcon(type),
              color: isActive ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(
              type.displayName,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: provider.apiKey.isNotEmpty
                ? Text(
                    'API Key: ••••${provider.apiKey.length > 4 ? provider.apiKey.substring(provider.apiKey.length - 4) : ""}',
                  )
                : Text(l10n.noApiKey),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Chip(
                    label: Text(l10n.active),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedProvider = isExpanded ? null : type;
                    });
                  },
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
              border: const OutlineInputBorder(),
              hintText: provider.type.defaultBaseUrl,
            ),
            onChanged: (value) => _localUrls[provider.type] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: l10n.labelApiKey,
              border: const OutlineInputBorder(),
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
                    border: const OutlineInputBorder(),
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
