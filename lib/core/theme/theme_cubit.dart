import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_themes.dart';

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.wizard); // Default to Wizard

  /// Toggle between Wizard and Forest themes
  void toggleTheme() {
    if (state == AppThemeMode.wizard) {
      emit(AppThemeMode.forest);
    } else {
      emit(AppThemeMode.wizard);
    }
  }

  void setWizard() => emit(AppThemeMode.wizard);
  void setForest() => emit(AppThemeMode.forest);

  bool get isWizard => state == AppThemeMode.wizard;
  bool get isForest => state == AppThemeMode.forest;
}
