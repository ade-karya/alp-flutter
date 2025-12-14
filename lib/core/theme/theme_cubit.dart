import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_themes.dart'; // Assuming AppThemeMode enum is defined here and updated to include 'wizard'

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.wizard); // Default to Wizard

  void toggleTheme() {
    if (state == AppThemeMode.serious) {
      emit(AppThemeMode.playful);
    } else if (state == AppThemeMode.playful) {
      emit(AppThemeMode.wizard);
    } else {
      emit(AppThemeMode.serious);
    }
  }

  void setSerious() => emit(AppThemeMode.serious);
  void setPlayful() => emit(AppThemeMode.playful);
  void setWizard() => emit(AppThemeMode.wizard);
}
