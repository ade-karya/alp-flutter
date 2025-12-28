import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/wizard_background.dart';

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
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_classes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: isWizard ? Colors.white54 : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data kelas.',
                style: TextStyle(
                  color: isWizard ? Colors.white70 : Colors.grey[600],
                ),
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
            color: isWizard ? Colors.black.withValues(alpha: 0.4) : null,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                cls['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWizard ? Colors.white : null,
                ),
              ),
              subtitle: Text(
                'PIN: ${cls['class_pin']}',
                style: TextStyle(color: isWizard ? Colors.white70 : null),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Future: Detailed report for class
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      appBar: AppBar(
        title: const Text('Laporan Hasil Belajar'),
        backgroundColor: isWizard ? Colors.transparent : null,
        elevation: 0,
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }
}
