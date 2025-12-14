import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/wizard_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.name;
      _selectedDate = authState.user.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date of birth')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return;

      final updatedUser = authState.user.copyWith(
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDate,
      );

      await context.read<DatabaseHelper>().updateUser(updatedUser);

      if (!mounted) return;

      await context.read<AuthCubit>().refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      return BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Immutable identifier display
                  Container(
                    decoration: isWizard
                        ? BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD700,
                                ).withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: Card(
                      color: isWizard ? Colors.transparent : Colors.grey[200],
                      elevation: isWizard ? 0 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isWizard ? BorderSide.none : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.role == UserRole.student ? 'NISN' : 'NUPTK',
                              style: TextStyle(
                                fontSize: 12,
                                color: isWizard
                                    ? Colors.white54
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.identifier,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isWizard ? Colors.white : Colors.black,
                                fontFamily: isWizard ? 'Cinzel' : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This identifier cannot be changed',
                              style: TextStyle(
                                fontSize: 12,
                                color: isWizard
                                    ? Colors.white38
                                    : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Editable fields
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isWizard ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(
                        color: isWizard ? Colors.white70 : null,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: isWizard
                          ? const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            )
                          : null,
                      prefixIcon: Icon(
                        Icons.person,
                        color: isWizard ? const Color(0xFFFFD700) : null,
                      ),
                      filled: isWizard,
                      fillColor: isWizard
                          ? Colors.white.withValues(alpha: 0.1)
                          : null,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: TextStyle(
                          color: isWizard ? Colors.white70 : null,
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: isWizard
                            ? const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: isWizard ? const Color(0xFFFFD700) : null,
                        ),
                        filled: isWizard,
                        fillColor: isWizard
                            ? Colors.white.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? (isWizard ? Colors.white38 : Colors.grey)
                              : (isWizard ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isWizard
                          ? const Color(0xFF4A148C)
                          : null, // Deep Purple for Wizard
                      foregroundColor: isWizard
                          ? const Color(0xFFFFD700)
                          : null, // Gold text
                      side: isWizard
                          ? const BorderSide(color: Color(0xFFFFD700))
                          : null,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isWizard
                                    ? const Color(0xFFFFD700)
                                    : Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: isWizard ? 'Cinzel' : null,
                              fontWeight: isWizard ? FontWeight.bold : null,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      appBar: AppBar(
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isWizard ? Colors.white : Colors.black),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWizard ? const Color(0xFF4A148C) : Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                border: isWizard
                    ? Border.all(color: const Color(0xFFFFD700))
                    : null,
              ),
              child: Text(
                'Sikolah',
                style: TextStyle(
                  color: isWizard ? const Color(0xFFFFD700) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWizard ? const Color(0xFFFFD700) : Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'Apps',
                style: TextStyle(
                  color: isWizard ? const Color(0xFF4A148C) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            ),
          ],
        ),
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }
}
