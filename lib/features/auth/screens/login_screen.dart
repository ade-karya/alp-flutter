import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();

  // Default to Student
  UserRole _selectedRole = UserRole.student;
  bool _isObscured = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        _identifierController.text.trim(),
        _pinController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.user.role == UserRole.student) {
              context.go('/student/dashboard');
            } else {
              context.go('/teacher/dashboard');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
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

                  // Form Section
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Welcome Text
                                Text(
                                  'Selamat Datang!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isWizard
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Masuk untuk melanjutkan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isWizard
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Role Selection Toggle
                                Container(
                                  decoration: BoxDecoration(
                                    color: isWizard
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildRoleButton(
                                          role: UserRole.student,
                                          label: l10n.roleStudent,
                                          icon: Icons.school,
                                          color: isWizard
                                              ? Colors.amber
                                              : Colors.blue,
                                          isWizard: isWizard,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildRoleButton(
                                          role: UserRole.teacher,
                                          label: l10n.roleTeacher,
                                          icon: Icons.person_outline,
                                          color: isWizard
                                              ? Colors.purpleAccent
                                              : Colors.green,
                                          isWizard: isWizard,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Identifier Input (NISN or NUPTK)
                                _buildTextField(
                                  controller: _identifierController,
                                  label: _selectedRole == UserRole.student
                                      ? l10n.labelNISN
                                      : l10n.labelNUPTK,
                                  icon: Icons.badge,
                                  keyboardType: TextInputType.number,
                                  isWizard: isWizard,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _selectedRole == UserRole.student
                                          ? l10n.errorEmptyNISN
                                          : l10n.errorEmptyNUPTK;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // PIN Input
                                _buildTextField(
                                  controller: _pinController,
                                  label: l10n.labelPIN,
                                  icon: Icons.lock,
                                  keyboardType: TextInputType.number,
                                  obscureText: _isObscured,
                                  isWizard: isWizard,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscured
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: isWizard
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscured = !_isObscured;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.errorEmptyPIN;
                                    }
                                    if (value.length < 4) {
                                      return l10n.errorShortPIN;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Login Button
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isWizard
                                          ? [
                                              const Color(0xFF6A1B9A),
                                              const Color(0xFF4A148C),
                                            ]
                                          : [
                                              Colors.blue[400]!,
                                              Colors.blue[700]!,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isWizard
                                            ? Colors.purple.withValues(
                                                alpha: 0.4,
                                              )
                                            : Colors.blue.withAlpha(80),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    border: isWizard
                                        ? Border.all(color: Colors.white24)
                                        : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.loginButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Register Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun? ',
                                      style: TextStyle(
                                        color: isWizard
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/register'),
                                      child: Text(
                                        l10n.registerLink,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isWizard
                                              ? Colors.amber
                                              : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: isWizard
            ? null
            : LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isWizard ? Colors.transparent : null,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Top row with language selector
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [LanguageSelector()],
          ),
          const SizedBox(height: 24),
          // Sikolah Apps Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
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
                  vertical: 10,
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
            'Platform Pembelajaran Adaptif',
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
    required Color color,
    required bool isWizard,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isWizard ? Colors.white70 : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isWizard ? Colors.white70 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isWizard,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: isWizard ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isWizard ? Colors.white70 : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isWizard ? Colors.white70 : Colors.grey[600],
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isWizard
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isWizard ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isWizard ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isWizard ? Colors.amber : Colors.blue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
