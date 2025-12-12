import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';
import '../settings/settings_cubit.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showChangePinDialog(BuildContext context, AppLocalizations l10n) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Capture references before showing dialog to avoid deactivated context issues
    final authCubit = context.read<AuthCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changePinTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPinController,
                decoration: InputDecoration(
                  labelText: l10n.changePinCurrentLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.changePinErrorEmpty;
                  }
                  if (value.length != 4) {
                    return l10n.errorPINLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                decoration: InputDecoration(
                  labelText: l10n.changePinNewLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.changePinErrorEmpty;
                  }
                  if (value.length != 4) {
                    return l10n.errorPINLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                decoration: InputDecoration(
                  labelText: l10n.changePinConfirmLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.changePinErrorEmpty;
                  }
                  if (value != newPinController.text) {
                    return l10n.errorMatchPIN;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await authCubit.updatePin(
                  currentPinController.text,
                  newPinController.text,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.changePinSuccess
                          : l10n.changePinErrorCurrent,
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.buttonOK),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final color = user.role == UserRole.student
            ? Colors.blueAccent
            : Colors.purpleAccent;

        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final l10n = AppLocalizations.of(context)!;

            return NavigationDrawer(
              children: [
                // User Header
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      user.role == UserRole.student
                          ? Icons.school
                          : Icons.person_outline,
                      size: 32,
                      color: color,
                    ),
                  ),
                  accountName: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(
                    '${user.role == UserRole.student ? l10n.roleStudent : l10n.roleTeacher} • ${user.role == UserRole.student ? l10n.labelNISN : l10n.labelNUPTK}: ${user.maskedIdentifier}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Dashboard
                NavigationDrawerDestination(
                  icon: const Icon(Icons.dashboard),
                  label: Text(l10n.navDashboard),
                ),
                // Edit Profile
                NavigationDrawerDestination(
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.navEditProfile),
                ),
                NavigationDrawerDestination(
                  icon: const Icon(Icons.pin),
                  label: Text(l10n.navChangePin),
                ),
                // Network Status
                const NavigationDrawerDestination(
                  icon: Icon(Icons.wifi),
                  label: Text('Status Jaringan'),
                ),
                // P2P Connection
                const NavigationDrawerDestination(
                  icon: Icon(Icons.sync_alt),
                  label: Text('Koneksi P2P'),
                ),
                const Divider(),
                // Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.navLanguage,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 32,
                        ),
                        isSelected: [
                          settingsState.locale == 'id',
                          settingsState.locale == 'en',
                          settingsState.locale == 'ar',
                        ],
                        onPressed: (index) {
                          String newLocale;
                          if (index == 0) {
                            newLocale = 'id';
                          } else if (index == 1) {
                            newLocale = 'en';
                          } else {
                            newLocale = 'ar';
                          }
                          context.read<SettingsCubit>().setLocale(newLocale);
                        },
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text('ID'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text('EN'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text('AR'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Switch User
                NavigationDrawerDestination(
                  icon: const Icon(Icons.people),
                  label: Text(l10n.navSwitchUser),
                ),
                // Logout
                NavigationDrawerDestination(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.navLogout),
                ),
              ],
              onDestinationSelected: (index) {
                Navigator.pop(context); // Close drawer

                switch (index) {
                  case 0: // Dashboard
                    if (user.role == UserRole.student) {
                      context.go('/student/dashboard');
                    } else {
                      context.go('/teacher/dashboard');
                    }
                    break;
                  case 1: // Edit Profile
                    context.push('/edit-profile');
                    break;
                  case 2: // Change PIN
                    _showChangePinDialog(context, l10n);
                    break;
                  case 3: // Network Status
                    context.push('/network-status');
                    break;
                  case 4: // P2P Connection
                    context.push('/p2p-connection');
                    break;
                  case 5: // Switch User - logout first, router will redirect to user-selection
                    context.read<AuthCubit>().logout();
                    break;
                  case 6: // Logout
                    context.read<AuthCubit>().logout();
                    break;
                }
              },
            );
          },
        );
      },
    );
  }
}
