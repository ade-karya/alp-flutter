import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_helper.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  Future<void> _showPinVerificationDialog(
    BuildContext context,
    User user,
    AppThemeMode themeMode,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    final secondaryColor = ThemeHelper.getSecondaryAccentColor(themeMode);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ThemeHelper.getDialogColor(themeMode),
        title: Text(
          l10n.usEnterPin(user.name),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.usLabelPin,
            labelStyle: const TextStyle(color: Colors.white70),
            counterText: '',
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (pinController.text == user.pin) {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  context.read<AuthCubit>().selectUser(user.effectiveId);
                }
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.usIncorrectPin)));
                pinController.clear();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: secondaryColor),
            child: Text(l10n.usVerify),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final accentColor = ThemeHelper.getAccentColor(themeMode);

    final body = FutureBuilder<List<User>>(
      future: DatabaseHelper.instance.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        final users = snapshot.data ?? [];

        return SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n, themeMode),
              Expanded(
                child: users.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildUserList(context, users, l10n, themeMode),
              ),
              _buildFooter(context, l10n, themeMode),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemeHelper.wrapWithBackground(themeMode, body),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppThemeMode themeMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildBranding(themeMode),
          const SizedBox(height: 24),
          Text(
            l10n.usTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.welcomeMessage,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding(AppThemeMode themeMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Text(
            'Sikolah',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: themeMode == AppThemeMode.forest
                ? const Color(0xFF2E7D32)
                : Colors.green[700],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: const Text(
            'Apps',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<User> users,
    AppLocalizations l10n,
    AppThemeMode themeMode,
  ) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: isDesktop
            ? GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) =>
                    _buildUserCard(context, users[index], themeMode),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: users.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildUserCard(context, users[index], themeMode),
              ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    User user,
    AppThemeMode themeMode,
  ) {
    final accentColor = ThemeHelper.getAccentColor(themeMode);
    final secondaryColor = ThemeHelper.getSecondaryAccentColor(themeMode);
    final color = user.role == UserRole.teacher ? secondaryColor : accentColor;

    return InkWell(
      onTap: () => _showPinVerificationDialog(context, user, themeMode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeHelper.getBorderColor(themeMode)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(40),
              child: Icon(
                user.role == UserRole.teacher
                    ? Icons.person_outline
                    : Icons.school,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.identifier ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(l10n.usNoUsers, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeMode themeMode,
  ) {
    final accentColor = ThemeHelper.getAccentColor(themeMode);

    return Container(
      padding: const EdgeInsets.all(32),
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(l10n.usAddUser),
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
