import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.userName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '••••',
                    errorText: _errorMessage,
                    counterText: '',
                    border: const OutlineInputBorder(),
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
              FilledButton(onPressed: _verifyPin, child: const Text('Verify')),
            ],
          ),
        ),
      ),
    );
  }
}
