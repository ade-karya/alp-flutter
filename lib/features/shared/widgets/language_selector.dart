import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../../core/settings/settings_cubit.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: l10n.languageSelectorTooltip,
          onSelected: (String newValue) {
            context.read<SettingsCubit>().setLocale(newValue);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  Text('EN', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text('English'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'id',
              child: Row(
                children: [
                  Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text('Bahasa Indonesia'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'ar',
              child: Row(
                children: [
                  Text('AR', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text('العربية'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
