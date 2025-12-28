import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/wizard_background.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  UserRole _selectedRole = UserRole.student;
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  DateTime? _selectedDate;
  bool _isPinObscured = true;
  bool _isConfirmPinObscured = true;
  bool _isGoogleSignIn = false;
  dynamic _googleUser;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is RoleSelectionRequired) {
      _isGoogleSignIn = true;
      _googleUser = authState.firebaseUser;
      _nameController.text = _googleUser.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _register() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      if (_isGoogleSignIn) {
        context.read<AuthCubit>().completeProfile(
          firebaseUser: _googleUser,
          role: _selectedRole,
          identifier: _identifierController.text.trim(),
          dateOfBirth: _selectedDate,
        );
      } else {
        context.read<AuthCubit>().register(
          identifier: _identifierController.text.trim(),
          name: _nameController.text.trim(),
          dateOfBirth: _selectedDate!,
          role: _selectedRole,
          pin: _pinController.text.trim(),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorEmptyDate),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );

    final body = BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          final authCubit = context.read<AuthCubit>();
          final router = GoRouter.of(context);

          showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog.adaptive(
              title: Text(l10n.registrationSuccessTitle),
              content: Text(l10n.registrationSuccessContent(state.identifier)),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await authCubit.reloadAuthStatus();
                    router.go('/user-selection');
                  },
                  child: Text(l10n.buttonOK),
                ),
              ],
            ),
          );
        } else if (state is Authenticated) {
          if (state.user.role == UserRole.student) {
            context.go('/student/dashboard');
          } else {
            context.go('/teacher/dashboard');
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, l10n, isWizard),
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
                              Text(
                                _isGoogleSignIn
                                    ? 'Lengkapi Profil Anda'
                                    : 'Buat Akun Baru',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isWizard
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              _buildRoleSelector(l10n, isWizard),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _identifierController,
                                label: _selectedRole == UserRole.student
                                    ? l10n.labelNISN
                                    : l10n.labelNUPTK,
                                icon: Icons.badge,
                                keyboardType: TextInputType.number,
                                isWizard: isWizard,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
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
                              _buildTextField(
                                controller: _nameController,
                                label: l10n.labelName,
                                icon: Icons.person,
                                isWizard: isWizard,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.errorEmptyName;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDateField(context, l10n, isWizard),
                              const SizedBox(height: 16),
                              const SizedBox(height: 16),
                              if (!_isGoogleSignIn) ...[
                                _buildTextField(
                                  controller: _pinController,
                                  label: l10n.labelPIN,
                                  icon: Icons.lock,
                                  keyboardType: TextInputType.number,
                                  obscureText: _isPinObscured,
                                  maxLength: 4,
                                  isWizard: isWizard,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPinObscured
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: isWizard
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    onPressed: () => setState(
                                      () => _isPinObscured = !_isPinObscured,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.errorEmptyPIN;
                                    }
                                    if (value.length != 4) {
                                      return l10n.errorPINLength;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _confirmPinController,
                                  label: l10n.labelConfirmPIN,
                                  icon: Icons.lock_outline,
                                  keyboardType: TextInputType.number,
                                  obscureText: _isConfirmPinObscured,
                                  maxLength: 4,
                                  isWizard: isWizard,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPinObscured
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: isWizard
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    onPressed: () => setState(
                                      () => _isConfirmPinObscured =
                                          !_isConfirmPinObscured,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.errorConfirmPIN;
                                    }
                                    if (value != _pinController.text) {
                                      return l10n.errorMatchPIN;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 32),
                              _buildRegisterButton(l10n, isWizard),
                              if (!_isGoogleSignIn) ...[
                                const SizedBox(height: 24),
                                _buildLoginLink(l10n, isWizard),
                              ],
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
    );

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.grey[50],
      body: isWizard ? WizardBackground(child: body) : body,
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
        color: isWizard ? Colors.transparent : Colors.green[600],
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
          _buildBranding(),
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

  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildRoleSelector(AppLocalizations l10n, bool isWizard) {
    return Container(
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
              color: isWizard ? Colors.amber : Colors.blue,
              isWizard: isWizard,
            ),
          ),
          Expanded(
            child: _buildRoleButton(
              role: UserRole.teacher,
              label: l10n.roleTeacher,
              icon: Icons.person_outline,
              color: isWizard ? Colors.purpleAccent : Colors.green,
              isWizard: isWizard,
            ),
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
      onTap: () => setState(() {
        _selectedRole = role;
        _identifierController.clear();
      }),
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

  Widget _buildDateField(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isWizard
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWizard ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: isWizard ? Colors.white70 : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? l10n.labelSelectDate
                    : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDate == null
                      ? (isWizard ? Colors.white38 : Colors.grey)
                      : (isWizard ? Colors.white : Colors.black87),
                ),
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
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
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
        counterText: '',
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
            color: isWizard ? Colors.amber : Colors.green,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(AppLocalizations l10n, bool isWizard) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWizard
              ? [const Color(0xFF6A1B9A), const Color(0xFF4A148C)]
              : [Colors.green[400]!, Colors.green[700]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.registerButton,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n, bool isWizard) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: TextStyle(color: isWizard ? Colors.white70 : Colors.grey[600]),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            l10n.loginLink,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWizard ? Colors.amber : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
