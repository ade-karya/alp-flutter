import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/wizard_widgets.dart';
import '../../../core/theme/theme_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _signInWithGoogle() {
    setState(() => _isLoading = true);
    context.read<AuthCubit>().signInWithGoogle();
    // Safety timeout to prevent stuck state
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final accentColor = ThemeHelper.getAccentColor(themeMode);

    final body = BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = false);

        if (state is Authenticated) {
          if (state.user.role == UserRole.student) {
            context.go('/student/dashboard');
          } else {
            context.go('/teacher/dashboard');
          }
        } else if (state is RoleSelectionRequired) {
          context.go('/register');
        } else if (state is AuthError) {
          WizardWidgets.showSnackBar(
            context: context,
            message: state.message,
            isError: true,
            isWizard: true, // Both themes are dark/magical
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || _isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, l10n, themeMode),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: ThemeHelper.getCardColor(themeMode),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: ThemeHelper.getBorderColor(themeMode),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.loginTitle,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ThemeHelper.getHeadingColor(themeMode),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              l10n.welcomeMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: ThemeHelper.getBodyColor(themeMode),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            _buildGoogleSignInButton(l10n, themeMode),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Colors.white24),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Secure Login',
                                    style: TextStyle(
                                      color: ThemeHelper.getSubtleColor(
                                        themeMode,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Colors.white24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ThemeHelper.getBorderColor(themeMode),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Masuk dengan akun Google untuk menyimpan data secara aman di cloud',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ThemeHelper.getBodyColor(
                                          themeMode,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemeHelper.wrapWithBackground(themeMode, body),
    );
  }

  Widget _buildGoogleSignInButton(
    AppLocalizations l10n,
    AppThemeMode themeMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _signInWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.g_mobiledata,
                      color: Colors.red,
                      size: 32,
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'Masuk dengan Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeMode themeMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [LanguageSelector()],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sikolah',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeMode == AppThemeMode.forest
                      ? const Color(0xFF2E7D32)
                      : Colors.green[700],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apps',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
