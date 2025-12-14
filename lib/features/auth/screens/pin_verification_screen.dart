import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/wizard_background.dart';

class PinVerificationScreen extends StatefulWidget {
  final String userName;
  final String expectedPin;
  final VoidCallback onSuccess;

  const PinVerificationScreen({
    super.key,
    required this.userName,
    required this.expectedPin,
    required this.onSuccess,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _pinController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    final enteredPin = _pinController.text;

    if (enteredPin.length != 4) {
      setState(() {
        _errorMessage = 'PIN must be 4 digits';
      });
      return;
    }

    if (enteredPin == widget.expectedPin) {
      widget.onSuccess();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: isWizard
                    ? const Color(0xFFFFD700)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome back,',
                style: isWizard
                    ? const TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontFamily: 'Cinzel',
                      )
                    : Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.userName,
                style: isWizard
                    ? const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cinzel',
                      )
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                    color: isWizard ? Colors.white : null,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(
                      color: isWizard ? Colors.white30 : null,
                    ),
                    errorText: _errorMessage,
                    errorStyle: TextStyle(
                      color: isWizard ? Colors.redAccent : null,
                    ),
                    counterText: '',
                    border: const OutlineInputBorder(),
                    enabledBorder: isWizard
                        ? OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    filled: isWizard,
                    fillColor: isWizard
                        ? Colors.white.withValues(alpha: 0.1)
                        : null,
                  ),
                  onChanged: (value) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                    if (value.length == 4) {
                      _verifyPin();
                    }
                  },
                  onSubmitted: (_) => _verifyPin(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _verifyPin,
                style: isWizard
                    ? FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: const Color(0xFFFFD700),
                        side: const BorderSide(color: Color(0xFFFFD700)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      )
                    : null,
                child: Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: isWizard ? 16 : null,
                    fontWeight: isWizard ? FontWeight.bold : null,
                    fontFamily: isWizard ? 'Cinzel' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : null,
      appBar: AppBar(
        title: Text(
          'Enter PIN',
          style: isWizard ? const TextStyle(fontFamily: 'Cinzel') : null,
        ),
        backgroundColor: isWizard ? Colors.transparent : null,
        iconTheme: isWizard ? const IconThemeData(color: Colors.white) : null,
        titleTextStyle: isWizard
            ? const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }
}
