import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/wizard_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );
    final authState = context.watch<AuthCubit>().state;

    // Safety check if user somehow lands here without being in RoleSelectionRequired state
    if (authState is! RoleSelectionRequired) {
      // We can't do much here, the router should handle redirection away from here
      // But we can show a loading or error just in case
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firebaseUser = authState.firebaseUser;

    final body = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Text
              Text(
                'Selamat datang, ${firebaseUser.displayName?.split(' ').first ?? "User"}!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isWizard ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih peran Anda untuk melanjutkan:',
                style: TextStyle(
                  fontSize: 16,
                  color: isWizard ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Roles
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        context: context,
                        role: UserRole.student,
                        label: l10n.roleStudent,
                        icon: Icons.school,
                        color: isWizard ? Colors.amber : Colors.blue,
                        isWizard: isWizard,
                        firebaseUser: firebaseUser,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildRoleCard(
                        context: context,
                        role: UserRole.teacher,
                        label: l10n.roleTeacher,
                        icon: Icons.person,
                        color: isWizard ? Colors.purpleAccent : Colors.green,
                        isWizard: isWizard,
                        firebaseUser: firebaseUser,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      body: isWizard ? WizardBackground(child: body) : body,
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required UserRole role,
    required String label,
    required IconData icon,
    required Color color,
    required bool isWizard,
    required dynamic firebaseUser,
  }) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: InkWell(
        onTap: () {
          context.read<AuthCubit>().completeProfile(
            firebaseUser: firebaseUser,
            role: role,
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isWizard ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isWizard
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isWizard)
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isWizard ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                role == UserRole.student
                    ? 'Akses materi, tugas, dan AI Tutor'
                    : 'Kelola kelas, materi dan siswa',
                style: TextStyle(
                  fontSize: 14,
                  color: isWizard ? Colors.white60 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
