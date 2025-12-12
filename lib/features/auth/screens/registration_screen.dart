import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';

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
      context.read<AuthCubit>().register(
        identifier: _identifierController.text.trim(),
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDate!,
        role: _selectedRole,
        pin: _pinController.text.trim(),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorEmptyDate)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        automaticallyImplyLeading: false,
        actions: const [LanguageSelector(), SizedBox(width: 16)],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            // Capture references BEFORE showing dialog to avoid context issues
            final authCubit = context.read<AuthCubit>();
            final router = GoRouter.of(context);

            showAdaptiveDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog.adaptive(
                title: Text(l10n.registrationSuccessTitle),
                content: Text(
                  l10n.registrationSuccessContent(state.identifier),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      // Reload auth status and navigate to user-selection
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.registerTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Role Selection
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
                          _identifierController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _selectedRole == UserRole.student
                                    ? l10n.errorEmptyNISN
                                    : l10n.errorEmptyNUPTK;
                              }
                              if (_selectedRole == UserRole.student &&
                                  value.length != 10) {
                                return l10n.errorNISNLength;
                              }
                              if (_selectedRole == UserRole.teacher &&
                                  value.length != 16) {
                                return l10n.errorNUPTKLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.labelName,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.errorEmptyName;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.labelDateOfBirth,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? l10n.labelSelectDate
                                    : DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              labelText: l10n.labelPIN,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              helperText: l10n.helperPIN,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPinObscured
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPinObscured = !_isPinObscured;
                                  });
                                },
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: _isPinObscured,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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
                          TextFormField(
                            controller: _confirmPinController,
                            decoration: InputDecoration(
                              labelText: l10n.labelConfirmPIN,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPinObscured
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPinObscured =
                                        !_isConfirmPinObscured;
                                  });
                                },
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: _isConfirmPinObscured,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              l10n.registerButton,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(l10n.loginLink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
