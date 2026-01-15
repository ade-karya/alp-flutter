import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_helper.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      final classes = await DatabaseHelper.instance.getTeacherClasses(
        authState.user.id!,
      );
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isForest = themeMode == AppThemeMode.forest;
    final accentColor = ThemeHelper.getAccentColor(themeMode);

    Widget buildContent() {
      if (_isLoading) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }

      if (_classes.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment_outlined, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Belum ada data kelas.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final cls = _classes[index];
          return Card(
            color: ThemeHelper.getCardColor(themeMode),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ThemeHelper.getBorderColor(themeMode)),
            ),
            child: ListTile(
              title: Text(
                cls['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'PIN: ${cls['class_pin']}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Icon(Icons.chevron_right, color: accentColor),
              onTap: () {
                // Future: Detailed report for class
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Laporan Hasil Belajar',
          style: TextStyle(color: accentColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        actions: [
          IconButton(
            icon: Icon(isForest ? Icons.forest : Icons.auto_awesome),
            tooltip: 'Ganti Tema',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        ],
      ),
      body: ThemeHelper.wrapWithBackground(themeMode, buildContent()),
    );
  }
}
