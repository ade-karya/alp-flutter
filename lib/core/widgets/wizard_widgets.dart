import 'package:flutter/material.dart';

/// Collection of wizard-themed widgets for consistent styling across the app
class WizardWidgets {
  WizardWidgets._();

  /// Wizard-themed TextField with magical styling
  static Widget textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int? maxLines = 1,
    bool isWizard = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        color: isWizard ? Colors.white : Colors.black87,
        fontFamily: isWizard ? 'Lato' : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isWizard ? Colors.white70 : Colors.grey[600],
          fontFamily: isWizard ? 'Lato' : null,
        ),
        hintStyle: TextStyle(
          color: isWizard ? Colors.white30 : Colors.grey[400],
        ),
        filled: true,
        fillColor: isWizard
            ? Colors.white.withValues(alpha: 0.05)
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
            color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  /// Wizard-themed Dropdown with magical styling
  static Widget dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required void Function(T?) onChanged,
    bool isWizard = true,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      dropdownColor: isWizard ? const Color(0xFF2E004B) : Colors.white,
      style: TextStyle(
        color: isWizard ? Colors.white : Colors.black87,
        fontSize: 16,
        fontFamily: isWizard ? 'Lato' : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isWizard ? Colors.white70 : Colors.grey[600],
          fontFamily: isWizard ? 'Lato' : null,
        ),
        filled: true,
        fillColor: isWizard
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Wizard-themed Primary Button (Filled)
  static Widget primaryButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    bool isLoading = false,
    bool isWizard = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: icon != null
          ? FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: isWizard
                    ? const Color(0xFF4A148C)
                    : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: isWizard
                    ? const BorderSide(color: Color(0xFFFFD700))
                    : null,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            )
          : FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: isWizard
                    ? const Color(0xFF4A148C)
                    : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: isWizard
                    ? const BorderSide(color: Color(0xFFFFD700))
                    : null,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(label),
            ),
    );
  }

  /// Wizard-themed Secondary Button (Outlined)
  static Widget secondaryButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    bool isWizard = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: isWizard
                    ? const Color(0xFFFFD700)
                    : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: isWizard
                    ? const Color(0xFFFFD700)
                    : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isWizard ? const Color(0xFFFFD700) : Colors.blue,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
              child: Text(label),
            ),
    );
  }

  /// Wizard-themed Card
  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    bool isWizard = true,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWizard ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isWizard
            ? Border.all(color: Colors.white10)
            : null,
        boxShadow: [
          BoxShadow(
            color: isWizard
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Wizard-themed Dialog
  static Future<T?> showWizardDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool isWizard = true,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isWizard
            ? const Color(0xFF2E004B)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isWizard
              ? const BorderSide(color: Color(0xFFFFD700), width: 2)
              : BorderSide.none,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isWizard ? const Color(0xFFFFD700) : Colors.black87,
            fontFamily: isWizard ? 'Cinzel' : null,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: DefaultTextStyle(
          style: TextStyle(
            color: isWizard ? Colors.white : Colors.black87,
            fontFamily: isWizard ? 'Lato' : null,
          ),
          child: content,
        ),
        actions: actions,
      ),
    );
  }

  /// Wizard-themed SnackBar
  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isWizard = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: isWizard ? 'Lato' : null,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError
            ? Colors.red[700]
            : (isWizard ? const Color(0xFF4A148C) : Colors.blue),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isWizard && !isError
              ? const BorderSide(color: Color(0xFFFFD700))
              : BorderSide.none,
        ),
      ),
    );
  }
}
