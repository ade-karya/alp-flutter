import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';

/// Redirect screen for backward compatibility - redirects /profile to /ai-assistant
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect to AI Assistant after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/ai-assistant');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiAssistantTitle)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
