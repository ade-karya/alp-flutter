import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
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
        final isPlayful = context.select(
          (ThemeCubit cubit) => cubit.state == AppThemeMode.playful,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome, ${user.name}'),
            actions: [
              // Theme toggle
              Row(
                children: [
                  Icon(
                    isPlayful
                        ? Icons.sentiment_very_satisfied
                        : Icons.business_center,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isPlayful,
                    onChanged: (value) {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                    activeTrackColor: Colors.orangeAccent,
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
          body: Container(
            decoration: isPlayful
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFEF9E7), Color(0xFFF2C94C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: user.role == UserRole.student
                        ? Colors.blueAccent
                        : Colors.purpleAccent,
                    child: Icon(
                      user.role == UserRole.student
                          ? Icons.school
                          : Icons.person_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == UserRole.student ? 'Student' : 'Teacher',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Redirecting to dashboard...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
