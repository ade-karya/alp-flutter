import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        actions: const [LanguageSelector(), SizedBox(width: 16)],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.user.role == UserRole.student) {
              context.go('/student/dashboard');
            } else {
              context.go('/teacher/dashboard');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Selection Toggle
                      SegmentedButton<UserRole>(
                        segments: [
                          ButtonSegment(
                            value: UserRole.student,
                            label: Text(l10n.roleStudent),
                            icon: const Icon(Icons.school),
                          ),
                          ButtonSegment(
                            value: UserRole.teacher,
                            label: Text(l10n.roleTeacher),
                            icon: const Icon(Icons.person_outline),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (Set<UserRole> newSelection) {
                          setState(() {
                            _selectedRole = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Identifier Input (NISN or NUPTK)
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          labelText: _selectedRole == UserRole.student
                              ? l10n.labelNISN
                              : l10n.labelNUPTK,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        keyboardType: TextInputType.number,
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
                      TextFormField(
                        controller: _pinController,
                        decoration: InputDecoration(
                          labelText: l10n.labelPIN,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscured = !_isObscured;
                              });
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: _isObscured,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.errorEmptyPIN;
                          }
                          if (value.length < 4) {
                            // Basic validation
                            return l10n.errorShortPIN;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      FilledButton(
                        onPressed: _login,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            l10n.loginButton,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Register Link
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(l10n.registerLink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
