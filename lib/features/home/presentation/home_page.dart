import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        // Auto-redirect to dashboard based on role
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user.role == UserRole.student) {
            context.go('/student/dashboard');
          } else {
            context.go('/teacher/dashboard');
          }
        });

        // Watch the theme state to rebuild when it changes
        final themeMode = context.select((ThemeCubit cubit) => cubit.state);
        final isForest = themeMode == AppThemeMode.forest;
        final accentColor = ThemeHelper.getAccentColor(themeMode);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Welcome, ${user.name}'),
            actions: [
              // Theme toggle
              Row(
                children: [
                  Icon(
                    isForest ? Icons.forest : Icons.auto_awesome,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isForest,
                    onChanged: (value) {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                    activeTrackColor: const Color(0xFF4CAF50),
                    inactiveTrackColor: const Color(0xFF9C27B0),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              // Switch User button
              IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'Switch User',
                onPressed: () => context.push('/user-selection'),
              ),
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () {
                  context.read<AuthCubit>().logout();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ThemeHelper.wrapWithBackground(
            themeMode,
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: user.role == UserRole.student
                        ? accentColor.withAlpha(50)
                        : ThemeHelper.getSecondaryAccentColor(
                            themeMode,
                          ).withAlpha(50),
                    child: Icon(
                      user.role == UserRole.student
                          ? Icons.school
                          : Icons.person_outline,
                      size: 50,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == UserRole.student ? 'Student' : 'Teacher',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Redirecting to dashboard...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
