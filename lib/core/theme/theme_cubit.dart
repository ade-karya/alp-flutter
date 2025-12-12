import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_themes.dart';

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.playful); // Default to Playful

  void toggleTheme() {
    emit(
      state == AppThemeMode.serious
          ? AppThemeMode.playful
          : AppThemeMode.serious,
    );
  }

  void setSerious() => emit(AppThemeMode.serious);
  void setPlayful() => emit(AppThemeMode.playful);
}
