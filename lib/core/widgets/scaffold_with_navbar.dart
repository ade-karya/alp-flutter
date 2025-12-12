import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';
import '../theme/theme_cubit.dart';
import '../theme/app_themes.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlayful = context.select(
      (ThemeCubit c) => c.state == AppThemeMode.playful,
    );

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return child;

        final isStudent = state.user.role == UserRole.student;
        final tabs = _getTabs(context, isStudent, l10n);
        final currentIndex = _calculateSelectedIndex(context, isStudent);

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) => _onItemTapped(index, context, isStudent),
            items: tabs,
            selectedItemColor: isPlayful
                ? Colors.deepPurple
                : Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getTabs(
    BuildContext context,
    bool isStudent,
    AppLocalizations l10n,
  ) {
    if (isStudent) {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.navDashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.school),
          label: l10n.tileAITutor,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.book),
          label: l10n.tileMyCourses,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.smart_toy),
          label: l10n.tileAIAssistant,
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.navDashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.note_add),
          label: l10n.tileCreateContent,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: l10n.tileManageClass,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.smart_toy),
          label: l10n.tileAIAssistant,
        ),
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
  }
}
