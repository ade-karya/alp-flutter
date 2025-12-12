import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/scaffold_with_navbar.dart';

import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/ai_tutor_screen.dart';
import '../../features/student/screens/my_courses_screen.dart';
import '../../features/student/screens/student_class_detail_screen.dart';
import '../../features/student/screens/exam_screen.dart';
import '../../features/student/screens/assignment_result_screen.dart';

import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/create_content_screen.dart';
import '../../features/teacher/screens/manage_class_screen.dart';
import '../../features/teacher/screens/class_detail_screen.dart';
import '../../features/teacher/screens/create_assignment_screen.dart';
import '../../features/teacher/screens/assignment_analytics_screen.dart';
import '../../features/teacher/screens/manual_grading_screen.dart';
import '../../features/teacher/screens/question_bank_screen.dart';

import '../../features/network/screens/network_status_screen.dart';
import '../../features/network/screens/p2p_connection_screen.dart';

import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/settings/screens/network_settings_screen.dart';

import '../../features/auth/screens/registration_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/user_selection_screen.dart';
import '../../features/profile/screens/change_pin_screen.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

import '../auth/auth_cubit.dart';
import '../auth/models/user_model.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;

      final path = state.matchedLocation;

      final goingLogin = path == '/login';
      final goingRegister = path == '/register';
      final goingUserSelection = path == '/user-selection';
      final goingOnboarding = path == '/onboarding';
      final goingSplash = path == '/splash';

      // If still loading, error, or registration success → don't redirect
      // RegistrationSuccess: let the registration screen handle showing the dialog
      if (authState is AuthInitial ||
          authState is AuthLoading ||
          authState is AuthError ||
          authState is RegistrationSuccess) {
        return null; // Stay on current screen
      }

      // ONBOARDING HANDLING
      if (authState is OnboardingRequired) {
        if (goingLogin || goingRegister) return null;
        return goingOnboarding ? null : '/onboarding';
      }

      // If user tries to open onboarding even though not needed
      if (goingOnboarding && authState is! OnboardingRequired) {
        return '/login';
      }

      // UNAUTHENTICATED AREA
      if (authState is Unauthenticated) {
        // allowed routes
        if (goingLogin || goingRegister || goingUserSelection) return null;

        // If there are existing users, go to user-selection (PIN login)
        // Otherwise go to login screen
        if (authState.hasUsers) {
          return '/user-selection';
        }
        return '/login';
      }

      // AUTHENTICATED AREA
      if (authState is Authenticated) {
        final user = authState.user;

        // If we are on splash, we must move to dashboard
        if (goingSplash) {
          return user.role == UserRole.student
              ? '/student/dashboard'
              : '/teacher/dashboard';
        }

        // prevent authenticated user from accessing register
        if (goingRegister) {
          return user.role == UserRole.student
              ? '/student/dashboard'
              : '/teacher/dashboard';
        }

        // prevent going back to auth screens
        if (goingLogin || goingOnboarding || goingUserSelection) {
          return user.role == UserRole.student
              ? '/student/dashboard'
              : '/teacher/dashboard';
        }

        // ROLE-BASED PROTECTION
        if (user.role == UserRole.student && path.startsWith('/teacher')) {
          return '/student/dashboard';
        }

        if (user.role == UserRole.teacher && path.startsWith('/student')) {
          return '/teacher/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/user-selection',
        builder: (context, state) => const UserSelectionScreen(),
      ),

      // AUTHENTICATED SHELL ROUTE
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // STUDENT ROUTES
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/ai-tutor',
            builder: (context, state) => const AiTutorScreen(),
          ),
          GoRoute(
            path: '/student/courses',
            builder: (context, state) => const MyCoursesScreen(),
            routes: [
              GoRoute(
                path: ':courseId',
                builder: (context, state) {
                  final courseId = int.parse(state.pathParameters['courseId']!);
                  return StudentClassDetailScreen(classId: courseId);
                },
                routes: [
                  GoRoute(
                    path: 'exam/:assignmentId',
                    builder: (context, state) {
                      final assignmentId = int.parse(
                        state.pathParameters['assignmentId']!,
                      );
                      return ExamScreen(assignmentId: assignmentId);
                    },
                  ),
                  GoRoute(
                    path: 'result/:assignmentId',
                    builder: (context, state) {
                      final assignmentId = int.parse(
                        state.pathParameters['assignmentId']!,
                      );
                      return AssignmentResultScreen(assignmentId: assignmentId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // TEACHER ROUTES
          GoRoute(
            path: '/teacher/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/create-content',
            builder: (context, state) => const CreateContentScreen(),
          ),
          GoRoute(
            path: '/teacher/manage-classes',
            builder: (context, state) => const ManageClassScreen(),
            routes: [
              GoRoute(
                path: ':classId',
                builder: (context, state) {
                  final classId = int.parse(state.pathParameters['classId']!);
                  return ClassDetailScreen(classId: classId);
                },
                routes: [
                  GoRoute(
                    path: 'assignments/create',
                    builder: (context, state) {
                      final classId = int.parse(
                        state.pathParameters['classId']!,
                      );
                      return CreateAssignmentScreen(classId: classId);
                    },
                  ),
                  GoRoute(
                    path: 'assignments/:assignmentId/analytics',
                    builder: (context, state) {
                      final assignmentId = int.parse(
                        state.pathParameters['assignmentId']!,
                      );
                      return AssignmentAnalyticsScreen(
                        assignmentId: assignmentId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'grade/:submissionId',
                        builder: (context, state) => ManualGradingScreen(
                          assignmentId: int.parse(
                            state.pathParameters['assignmentId']!,
                          ),
                          submissionId: int.parse(
                            state.pathParameters['submissionId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // PROFILE
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/settings/network',
            builder: (context, state) => const NetworkSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/change-pin',
            builder: (context, state) => const ChangePinScreen(),
          ),
          // AI ASSISTANT
          GoRoute(
            path: '/ai-assistant',
            builder: (context, state) => const AIAssistantScreen(),
          ),
          // QUESTION BANK
          GoRoute(
            path: '/teacher/question-bank',
            builder: (context, state) => const QuestionBankScreen(),
          ),
          // NETWORK STATUS
          GoRoute(
            path: '/network-status',
            builder: (context, state) => const NetworkStatusScreen(),
          ),
          // P2P CONNECTION
          GoRoute(
            path: '/p2p-connection',
            builder: (context, state) => const P2PConnectionScreen(),
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
