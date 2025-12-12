import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_cubit.dart';
import 'core/settings/settings_cubit.dart';
import 'core/services/gemini_openai_service.dart';
import 'core/auth/auth_cubit.dart';
import 'core/database/database_helper.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import 'core/network/network_discovery_service.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'core/network/network_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => GeminiOpenAIService()),
        RepositoryProvider(create: (context) => DatabaseHelper.instance),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) => AuthCubit(context.read<DatabaseHelper>()),
          ),
          BlocProvider(
            create: (context) => NetworkCubit(NetworkDiscoveryService()),
          ),
        ],
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, authState) {
            final networkCubit = context.read<NetworkCubit>();
            if (authState is Authenticated) {
              // Auto-start network when user logs in
              networkCubit.start(authState.user);
            } else if (authState is Unauthenticated) {
              // Stop network when user logs out
              networkCubit.stop();
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              // Create SettingsCubit based on auth state
              final userId = authState is Authenticated
                  ? authState.user.id
                  : null;

              return BlocProvider(
                key: ValueKey(
                  userId,
                ), // Key ensures recreation when userId changes
                create: (context) => SettingsCubit(userId: userId),
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, settingsState) {
                    return BlocBuilder<ThemeCubit, AppThemeMode>(
                      builder: (context, themeMode) {
                        return MaterialApp.router(
                          onGenerateTitle: (context) =>
                              AppLocalizations.of(context)!.appTitle,
                          theme: themeMode == AppThemeMode.serious
                              ? AppThemes.serious
                              : AppThemes.playful,
                          locale: Locale(settingsState.locale),
                          localizationsDelegates:
                              AppLocalizations.localizationsDelegates,
                          supportedLocales: AppLocalizations.supportedLocales,
                          routerConfig: createAppRouter(
                            context.read<AuthCubit>(),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
