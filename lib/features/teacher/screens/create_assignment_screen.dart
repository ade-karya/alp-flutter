import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final int classId;

  const CreateAssignmentScreen({super.key, required this.classId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '60');

  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  List<Map<String, dynamic>> _selectedQuestions = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Buat Tugas Baru',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tugas Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat tugas untuk siswa di kelas ini',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Tugas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      hintText: 'contoh: Ulangan Harian Bab 1',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) =>
                        v?.isEmpty == true ? 'Judul harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      hintText: 'Petunjuk pengerjaan, dll',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schedule Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal & Durasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScheduleTile(
                          icon: Icons.calendar_today,
                          title: 'Tanggal',
                          value: DateFormat(
                            'dd MMM yyyy',
                          ).format(_scheduledDate),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildScheduleTile(
                          icon: Icons.access_time,
                          title: 'Waktu',
                          value: _scheduledTime.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Durasi Pengerjaan',
                      suffixText: 'menit',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Angka tidak valid'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Questions Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Soal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedQuestions.length}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _openQuestionPicker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedQuestions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada soal dipilih',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambahkan soal dari bank soal',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._selectedQuestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final q = entry.value;
                      final isMC = q['type'] == 'mc';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['question_text'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMC
                                              ? Colors.blue.withAlpha(25)
                                              : Colors.purple.withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          isMC ? 'PG' : 'Essay',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isMC
                                                ? Colors.blue
                                                : Colors.purple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        q['topic'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _selectedQuestions.remove(q);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[700]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAssignment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Buat Tugas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _openQuestionPicker() async {
    final user = (context.read<AuthCubit>().state as Authenticated).user;
    final allQuestions = await DatabaseHelper.instance.getTeacherQuestions(
      user.id!,
    );

    if (!mounted) return;

    final mcQuestions = allQuestions.where((q) => q['type'] == 'mc').toList();
    final essayQuestions = allQuestions
        .where((q) => q['type'] == 'essay')
        .toList();

    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) {
        final selectedIds = _selectedQuestions.map((q) => q['id']).toSet();
        final tempSelected = List<Map<String, dynamic>>.from(
          _selectedQuestions,
        );

        return StatefulBuilder(
          builder: (context, setStateSB) {
            Widget buildQuestionList(List<Map<String, dynamic>> questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      const Text('Tidak ada soal'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final isSelected = selectedIds.contains(q['id']);
                  final isMC = q['type'] == 'mc';

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withAlpha(15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setStateSB(() {
                          if (val == true) {
                            selectedIds.add(q['id']);
                            tempSelected.add(q);
                          } else {
                            selectedIds.remove(q['id']);
                            tempSelected.removeWhere((e) => e['id'] == q['id']);
                          }
                        });
                      },
                      activeColor: Colors.orange,
                      title: Text(
                        q['question_text'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isMC
                                  ? Colors.blue.withAlpha(25)
                                  : Colors.purple.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isMC ? 'PG' : 'Essay',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMC ? Colors.blue : Colors.purple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q['topic'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return DefaultTabController(
              length: 3,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pilih Soal'),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        labelColor: Colors.orange,
                        unselectedLabelColor: Colors.grey,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Semua (${allQuestions.length})'),
                          Tab(text: 'PG (${mcQuestions.length})'),
                          Tab(text: 'Essay (${essayQuestions.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: TabBarView(
                    children: [
                      buildQuestionList(allQuestions),
                      buildQuestionList(mcQuestions),
                      buildQuestionList(essayQuestions),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tempSelected.length} dipilih',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempSelected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tambahkan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedQuestions = result);
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal satu soal'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = (context.read<AuthCubit>().state as Authenticated).user;
    final scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    try {
      await DatabaseHelper.instance.createAssignment(
        teacherId: user.id!,
        classId: widget.classId,
        title: _titleController.text,
        description: _descController.text,
        scheduledAt: scheduledDateTime,
        durationMinutes: int.parse(_durationController.text),
        questionIds: _selectedQuestions.map((q) => q['id'] as int).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tugas berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
