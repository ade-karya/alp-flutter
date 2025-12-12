import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../core/database/database_helper.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usTitle),
        automaticallyImplyLeading: false,
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

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _UserCard(
                              user: user,
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/register'),
                      icon: const Icon(Icons.person_add),
                      label: Text(l10n.usAddUser),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
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

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onDelete,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role == UserRole.student ? 'Student' : 'Teacher',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.role == UserRole.student ? 'NISN' : 'NUPTK'}: ${user.maskedIdentifier}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
