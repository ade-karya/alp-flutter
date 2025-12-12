import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';
import '../settings/settings_cubit.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
              backgroundColor: Colors.white,
              children: [
                // Custom Header matching Dashboard
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 50, 28, 20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sikolah Apps Logo
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                      const SizedBox(height: 24),
                      // User Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: color.withAlpha(25),
                            child: Icon(
                              user.role == UserRole.student
                                  ? Icons.school
                                  : Icons.person_outline,
                              size: 20,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${user.role == UserRole.student ? l10n.roleStudent : l10n.roleTeacher} • ${user.maskedIdentifier}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 10),
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
                // Network Settings (Teacher only or both?)
                // Requirement says "tambahkan halaman di pengaturan", implies general or teacher.
                // Assuming mostly for Teacher since they control server, but Student might need to select Interface too?
                // Student only needs to "connect", usually via QR. Teacher needs to "serve".
                // But user requested "memilih ip yang digunakan qr" (Teacher feature).
                // "menghidupkan atau mematikan server" (Teacher feature).
                // So let's show it for everyone or maybe just Teacher?
                // User didn't specify restricted, but "Manage Class" is teacher only.
                // I'll show it for everyone for now as "Status Jaringan" was there for everyone.
                const NavigationDrawerDestination(
                  icon: Icon(Icons.settings_ethernet),
                  label: Text('Pengaturan Network'),
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
                    context.push('/settings/change-pin');
                    break;
                  case 3: // Network Settings
                    context.push('/settings/network');
                    break;
                  case 4: // Switch User
                    context.read<AuthCubit>().logout();
                    break;
                  case 5: // Logout
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
