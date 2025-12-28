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

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final isWizard = themeMode == AppThemeMode.wizard;
    final isDesktop = _isDesktop(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return isWizard ? WizardBackground(child: child) : child;
        }

        final isStudent = authState.user.role == UserRole.student;
        final icons = _getIcons(isStudent);
        final currentIndex = _calculateSelectedIndex(context, isStudent);

        if (isDesktop) {
          return Scaffold(
            backgroundColor: isWizard ? Colors.transparent : Colors.white,
            body: isWizard
                ? WizardBackground(
                    child: _buildDesktopLayout(
                      context,
                      currentIndex,
                      isStudent,
                      isWizard,
                    ),
                  )
                : _buildDesktopLayout(
                    context,
                    currentIndex,
                    isStudent,
                    isWizard,
                  ),
          );
        }

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
                  ? const Color(0xFF4A148C)
                  : const Color(0xFF00ACC1),
              gradient: isWizard
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF2E004B),
                        Color(0xFF4A148C),
                        Color(0xFF7B1FA2),
                        Color(0xFFFFD700),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.5, 0.8, 1.0],
                    )
                  : null,
              itemActiveColor: isWizard ? const Color(0xFFFFD700) : null,
              itemInactiveColor: isWizard ? Colors.white38 : null,
              itemBackgroundColor: isWizard
                  ? Colors.black.withValues(alpha: 0.2)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    int selectedIndex,
    bool isStudent,
    bool isWizard,
  ) {
    final railColor = isWizard
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[50];
    final selectedColor = isWizard ? const Color(0xFFFFD700) : Colors.blue;
    final unselectedColor = isWizard ? Colors.white70 : Colors.grey[600];

    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _onItemTapped(index, context, isStudent),
          backgroundColor: railColor,
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: IconThemeData(color: selectedColor),
          unselectedIconTheme: IconThemeData(color: unselectedColor),
          selectedLabelTextStyle: TextStyle(
            color: selectedColor,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: TextStyle(color: unselectedColor),
          leading: Column(
            children: [
              const SizedBox(height: 20),
              _buildLogo(isWizard),
              const SizedBox(height: 30),
            ],
          ),
          destinations: _getRailDestinations(isStudent),
        ),
        VerticalDivider(
          thickness: 1,
          width: 1,
          color: isWizard ? Colors.white10 : Colors.grey[200],
        ),
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

  Widget _buildLogo(bool isWizard) {
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
