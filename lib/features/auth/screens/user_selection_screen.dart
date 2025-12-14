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

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  Future<void> _showPinVerificationDialog(
    BuildContext context,
    User user,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.usEnterPin(user.name)),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.usLabelPin,
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
            child: Text(l10n.usVerify),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetPinDialog(BuildContext context, User user) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.usSetPinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.usSetPinMsg),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: l10n.usLabelPin,
                counterText: '',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: l10n.usConfirmPin,
                counterText: '',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              if (pinController.text.length != 4) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.usPinLength)));
                return;
              }
              if (pinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.usPinMismatch)));
                return;
              }

              // Update user with PIN
              final updatedUser = user.copyWith(pin: pinController.text);
              await context.read<DatabaseHelper>().updateUser(updatedUser);

              if (!context.mounted) return;
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().selectUser(user.id!);
            },
            child: Text(l10n.usSetPinButton),
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

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      appBar: AppBar(
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Sikolah',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Apps',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<List<User>>(
            future: context.read<DatabaseHelper>().getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pilih Pengguna',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isWizard ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan pilih akun untuk masuk',
                          style: TextStyle(
                            fontSize: 16,
                            color: isWizard ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (users.isEmpty)
                          Expanded(
                            child: Center(
                              child: Text(
                                l10n.usNoUsers,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisExtent: 160,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _UserCard(
                                  user: user,
                                  isWizard: isWizard,
                                  onTap: () async {
                                    // Check if user has PIN
                                    if (user.pin == null || user.pin!.isEmpty) {
                                      // Force user to set PIN
                                      if (!context.mounted) return;
                                      await _showSetPinDialog(context, user);
                                    } else {
                                      // Verify PIN
                                      if (!context.mounted) return;
                                      await _showPinVerificationDialog(
                                        context,
                                        user,
                                      );
                                    }
                                  },
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Hapus ${user.name}?',
                                        ), // Fallback l10n
                                        content: const Text(
                                          'Apakah anda yakin ingin menghapus akun ini? Data tidak dapat dikembalikan.',
                                        ), // Fallback l10n
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(l10n.commonCancel),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      context.read<AuthCubit>().deleteUser(
                                        user.id!,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/register'),
                            icon: const Icon(Icons.person_add),
                            label: Text(l10n.usAddUser),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWizard
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : null,
                              foregroundColor: isWizard ? Colors.white : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isWizard
                                    ? const BorderSide(color: Colors.white24)
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isWizard;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onDelete,
    required this.isWizard,
  });

  @override
  Widget build(BuildContext context) {
    final color = user.role == UserRole.student
        ? Colors.blueAccent
        : Colors.purpleAccent;

    return Dismissible(
      key: Key('user_${user.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      child: Card(
        color: isWizard ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        elevation: isWizard ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isWizard
              ? BorderSide(color: Colors.amber.withValues(alpha: 0.3))
              : BorderSide.none,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color,
                  child: Icon(
                    user.role == UserRole.student
                        ? Icons.school
                        : Icons.person_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isWizard ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role == UserRole.student ? 'Student' : 'Teacher',
                        style: TextStyle(
                          fontSize: 14,
                          color: isWizard ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.role == UserRole.student ? 'NISN' : 'NUPTK'}: ${user.maskedIdentifier}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isWizard ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isWizard ? Colors.white24 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
