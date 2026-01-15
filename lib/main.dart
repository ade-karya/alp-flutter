import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_cubit.dart';
import 'core/settings/settings_cubit.dart';
import 'core/services/gemini_openai_service.dart';
import 'core/auth/auth_cubit.dart';
import 'core/auth/firebase_auth_service.dart';
import 'core/database/database_helper.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import 'core/network/network_discovery_service.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'core/network/network_cubit.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'; // For platform checks
import 'core/services/db_initializer.dart'; // Conditional import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database (FFI for Desktop, No-op for Web)
  await initializeDatabase();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handle Flutter Errors (UI)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _handleGlobalError();
  };

  // Handle Async Errors (Futures, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error caught: $error');
    debugPrint(stack.toString());
    _handleGlobalError();
    return true; // handled
  };

  runApp(const MyApp());
}

bool _isHandlingError = false;

void _handleGlobalError() {
  if (_isHandlingError) return;
  _isHandlingError = true;

  // Small delay to ensure frame is ready for navigation
  Future.delayed(const Duration(milliseconds: 500), () {
    _isHandlingError = false;
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      try {
        context.go('/user-selection');
      } catch (e) {
        // Fallback if route not found
        context.go('/login');
      }
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => GeminiOpenAIService()),
        RepositoryProvider(create: (context) => DatabaseHelper.instance),
        RepositoryProvider(create: (context) => FirebaseAuthService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) => AuthCubit(
              context.read<DatabaseHelper>(),
              context.read<FirebaseAuthService>(),
            ),
          ),
          BlocProvider(
            create: (context) => NetworkCubit(NetworkDiscoveryService()),
          ),
        ],
        child: Builder(
          builder: (context) {
            // Create router once and cache it
            _router ??= createAppRouter(context.read<AuthCubit>());

            return BlocListener<AuthCubit, AuthState>(
              listener: (context, authState) {
                final networkCubit = context.read<NetworkCubit>();
                if (authState is Authenticated) {
                  networkCubit.start(authState.user);
                } else if (authState is Unauthenticated) {
                  networkCubit.stop();
                }
              },
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final userId = authState is Authenticated
                      ? authState.user.id
                      : null;

                  return BlocProvider(
                    key: ValueKey(userId),
                    create: (context) => SettingsCubit(userId: userId),
                    child: BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        return BlocBuilder<ThemeCubit, AppThemeMode>(
                          builder: (context, themeMode) {
                            return MaterialApp.router(
                              onGenerateTitle: (context) =>
                                  AppLocalizations.of(context)!.appTitle,
                              theme: AppThemes.getTheme(themeMode),
                              locale: Locale(settingsState.locale),
                              localizationsDelegates:
                                  AppLocalizations.localizationsDelegates,
                              supportedLocales:
                                  AppLocalizations.supportedLocales,
                              routerConfig: _router!,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
