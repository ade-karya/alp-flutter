import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';
import 'fluid_nav_bar/fluid_nav_bar.dart';
import 'fluid_nav_bar/fluid_icon_data.dart';
import '../theme/theme_cubit.dart';
import '../theme/app_themes.dart';
import '../theme/wizard_background.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, themeMode) {
        final isWizard = themeMode == AppThemeMode.wizard;

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is! Authenticated) {
              return isWizard ? WizardBackground(child: child) : child;
            }

            final isStudent = authState.user.role == UserRole.student;
            final icons = _getIcons(isStudent);
            final currentIndex = _calculateSelectedIndex(context, isStudent);

            return Scaffold(
              backgroundColor: isWizard ? Colors.transparent : Colors.white,
              extendBody: true,
              body: isWizard ? WizardBackground(child: child) : child,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isWizard
                          ? const Color(0xFF9C27B0).withValues(alpha: 0.3)
                          : Colors.grey.withAlpha(30),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: FluidNavBar(
                  icons: icons,
                  selectedIndex: currentIndex,
                  onChange: (index) => _onItemTapped(index, context, isStudent),
                  backgroundColor: isWizard
                      ? const Color(
                          0xFF4A148C,
                        ) // Deep Purple for Wizard fallback
                      : const Color(0xFF00ACC1), // Biru air laut
                  gradient: isWizard
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF2E004B), // Dark text/bg
                            Color(0xFF4A148C), // Mystical Purple
                            Color(0xFF7B1FA2), // Lighter Purple
                            Color(0xFFFFD700), // Gold Accent (lower edge)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.5, 0.8, 1.0],
                        )
                      : null,
                  itemActiveColor: isWizard
                      ? const Color(0xFFFFD700)
                      : null, // Gold
                  itemInactiveColor: isWizard ? Colors.white38 : null,
                  itemBackgroundColor: isWizard
                      ? Colors.black.withValues(alpha: 0.2)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<FluidFillIconData> _getIcons(bool isStudent) {
    if (isStudent) {
      return const [
        FluidFillIcons.dashboard, // Dashboard - seperti di dashboard
        FluidFillIcons.schoolOutlined, // AI Tutor
        FluidFillIcons.libraryBooks, // Courses
        FluidFillIcons.smartToy, // AI Assistant
      ];
    } else {
      return const [
        FluidFillIcons.dashboard, // Dashboard
        FluidFillIcons.noteAddOutlined, // Buat Konten - seperti di dashboard
        FluidFillIcons.peopleOutlined, // Kelola Kelas - seperti di dashboard
        FluidFillIcons.smartToy, // AI Assistant - seperti di dashboard
      ];
    }
  }

  int _calculateSelectedIndex(BuildContext context, bool isStudent) {
    final location = GoRouterState.of(context).uri.path;

    if (isStudent) {
      if (location.startsWith('/student/dashboard')) return 0;
      if (location.startsWith('/student/ai-tutor')) return 1;
      if (location.startsWith('/student/courses')) return 2;
      if (location.startsWith('/ai-assistant')) return 3;
    } else {
      if (location.startsWith('/teacher/dashboard')) return 0;
      if (location.startsWith('/teacher/create-content')) return 1;
      if (location.startsWith('/teacher/manage-classes') ||
          location.startsWith('/teacher/question-bank')) {
        return 2;
      }
      if (location.startsWith('/ai-assistant')) return 3;
    }
    return 0; // Default to home
  }

  void _onItemTapped(int index, BuildContext context, bool isStudent) {
    // Gunakan addPostFrameCallback untuk menghindari error "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (isStudent) {
        switch (index) {
          case 0:
            context.go('/student/dashboard');
            break;
          case 1:
            context.go('/student/ai-tutor');
            break;
          case 2:
            context.go('/student/courses');
            break;
          case 3:
            context.go('/ai-assistant');
            break;
        }
      } else {
        switch (index) {
          case 0:
            context.go('/teacher/dashboard');
            break;
          case 1:
            context.go('/teacher/create-content');
            break;
          case 2:
            context.go('/teacher/manage-classes');
            break;
          case 3:
            context.go('/ai-assistant');
            break;
        }
      }
    });
  }
}
