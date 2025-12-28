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
import '../../../core/theme/wizard_background.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  Future<void> _showPinVerificationDialog(
    BuildContext context,
    User user,
    bool isWizard,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isWizard ? const Color(0xFF1A1A2E) : null,
        title: Text(
          l10n.usEnterPin(user.name),
          style: TextStyle(color: isWizard ? Colors.white : null),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          style: TextStyle(color: isWizard ? Colors.white : null),
          decoration: InputDecoration(
            labelText: l10n.usLabelPin,
            labelStyle: TextStyle(color: isWizard ? Colors.white70 : null),
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
                  context.read<AuthCubit>().selectUser(user.id!);
                }
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.usIncorrectPin)));
                pinController.clear();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isWizard ? Colors.purple : null,
            ),
            child: Text(l10n.usVerify),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );

    final body = FutureBuilder<List<User>>(
      future: DatabaseHelper.instance.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        return SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n, isWizard),
              Expanded(
                child: users.isEmpty
                    ? _buildEmptyState(context, l10n, isWizard)
                    : _buildUserList(context, users, l10n, isWizard),
              ),
              _buildFooter(context, l10n, isWizard),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      body: isWizard ? WizardBackground(child: body) : body,
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isWizard) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildBranding(),
          const SizedBox(height: 24),
          Text(
            l10n.usTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isWizard ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.welcomeMessage,
            style: TextStyle(
              fontSize: 14,
              color: isWizard ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
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
            color: Colors.green[700],
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
    bool isWizard,
  ) {
    // Desktop layout using GridView
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
                    _buildUserCard(context, users[index], isWizard),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: users.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildUserCard(context, users[index], isWizard),
              ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, bool isWizard) {
    final color = user.role == UserRole.teacher
        ? (isWizard ? Colors.purpleAccent : Colors.green)
        : (isWizard ? Colors.amber : Colors.blue);

    return InkWell(
      onTap: () => _showPinVerificationDialog(context, user, isWizard),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWizard ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWizard ? Colors.white24 : Colors.grey[200]!,
          ),
          boxShadow: [
            if (!isWizard)
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(isWizard ? 40 : 20),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isWizard ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    user.identifier ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isWizard ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isWizard ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: isWizard ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.usNoUsers,
            style: TextStyle(color: isWizard ? Colors.white38 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(l10n.usAddUser),
        style: TextButton.styleFrom(
          foregroundColor: isWizard ? Colors.amber : Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
