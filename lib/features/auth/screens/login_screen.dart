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
import '../../../core/theme/wizard_background.dart';

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
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );

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
            isWizard: isWizard,
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || _isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with branding
                _buildHeader(context, l10n, isWizard),

                // Login Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isWizard
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(isWizard ? 0 : 30),
                              spreadRadius: 2,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: isWizard
                              ? Border.all(color: Colors.white24)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            Text(
                              l10n.loginTitle,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isWizard ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              l10n.welcomeMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: isWizard
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Google Sign-In Button
                            _buildGoogleSignInButton(l10n, isWizard),
                            const SizedBox(height: 24),

                            // Divider with text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isWizard
                                        ? Colors.white24
                                        : Colors.grey[300],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Secure Login',
                                    style: TextStyle(
                                      color: isWizard
                                          ? Colors.white54
                                          : Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isWizard
                                        ? Colors.white24
                                        : Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Info text
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isWizard
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isWizard
                                      ? Colors.white12
                                      : Colors.blue.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: isWizard
                                        ? Colors.amber
                                        : Colors.blue[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Masuk dengan akun Google untuk menyimpan data secara aman di cloud',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isWizard
                                            ? Colors.white70
                                            : Colors.grey[700],
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
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      body: isWizard ? WizardBackground(child: body) : body,
    );
  }

  Widget _buildGoogleSignInButton(AppLocalizations l10n, bool isWizard) {
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
        border: Border.all(
          color: isWizard ? Colors.white24 : Colors.grey[300]!,
        ),
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
                // Google Logo
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
    bool isWizard,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isWizard ? Colors.transparent : Colors.blue[600],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
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
                  color: Colors.green[700],
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
            style: TextStyle(
              color: isWizard ? Colors.white70 : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
