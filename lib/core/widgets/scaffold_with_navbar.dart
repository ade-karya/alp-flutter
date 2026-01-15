import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';
import 'fluid_nav_bar/fluid_icon_data.dart';
import '../theme/theme_cubit.dart';
import '../theme/app_themes.dart';
import '../theme/theme_helper.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final isDesktop = _isDesktop(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return ThemeHelper.wrapWithBackground(themeMode, child);
        }

        final isStudent = authState.user.role == UserRole.student;
        _getIcons(isStudent);
        final currentIndex = _calculateSelectedIndex(context, isStudent);

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: ThemeHelper.wrapWithBackground(
              themeMode,
              _buildDesktopLayout(context, currentIndex, isStudent, themeMode),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ThemeHelper.wrapWithBackground(themeMode, child),
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    int selectedIndex,
    bool isStudent,
    AppThemeMode themeMode,
  ) {
    final selectedColor = ThemeHelper.getAccentColor(themeMode);
    const unselectedColor = Colors.white70;

    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _onItemTapped(index, context, isStudent),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: IconThemeData(color: selectedColor),
          unselectedIconTheme: const IconThemeData(color: unselectedColor),
          selectedLabelTextStyle: TextStyle(
            color: selectedColor,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: const TextStyle(color: unselectedColor),
          leading: Column(
            children: [
              const SizedBox(height: 20),
              _buildLogo(themeMode),
              const SizedBox(height: 30),
            ],
          ),
          destinations: _getRailDestinations(isStudent),
        ),
        const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(AppThemeMode themeMode) {
    return Row(
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
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: themeMode == AppThemeMode.forest
                ? const Color(0xFF2E7D32)
                : Colors.green[700],
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
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  List<NavigationRailDestination> _getRailDestinations(bool isStudent) {
    if (isStudent) {
      return const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: Text('AI Tutor'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: Text('Materi'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(Icons.smart_toy),
          label: Text('Bantuan AI'),
        ),
      ];
    } else {
      return const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.note_add_outlined),
          selectedIcon: Icon(Icons.note_add),
          label: Text('Konten'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: Text('Kelas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(Icons.smart_toy),
          label: Text('Bantuan AI'),
        ),
      ];
    }
  }

  List<FluidFillIconData> _getIcons(bool isStudent) {
    if (isStudent) {
      return const [
        FluidFillIcons.dashboard,
        FluidFillIcons.schoolOutlined,
        FluidFillIcons.libraryBooks,
        FluidFillIcons.smartToy,
      ];
    } else {
      return const [
        FluidFillIcons.dashboard,
        FluidFillIcons.noteAddOutlined,
        FluidFillIcons.peopleOutlined,
        FluidFillIcons.smartToy,
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
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isStudent) {
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
