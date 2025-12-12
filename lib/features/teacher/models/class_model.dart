class ClassModel {
  final int? id;
  final int teacherId;
  final String name;
  final String? description;
  final String pin;
  final DateTime createdAt;
  final String? teacherName; // For display purposes

  ClassModel({
    this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.pin,
    required this.createdAt,
    this.teacherName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'name': name,
      'description': description,
      'class_pin': pin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as int?,
      teacherId: map['teacher_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      pin: map['class_pin'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      teacherName: map['teacher_name'] as String?,
    );
  }
}
