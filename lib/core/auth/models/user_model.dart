enum UserRole { student, teacher }

class User {
  final int? id;
  final String identifier; // NISN for students, NUPTK for teachers
  final String name;
  final DateTime dateOfBirth;
  final UserRole role;
  final String? pin; // 4-digit PIN
  final String? apiKey;
  final String? selectedModel;
  final DateTime createdAt;

  User({
    this.id,
    required this.identifier,
    required this.name,
    required this.dateOfBirth,
    required this.role,
    this.pin,
    this.apiKey,
    this.selectedModel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identifier': identifier,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'role': role.name,
      'pin': pin,
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      identifier: map['identifier'] as String,
      name: map['name'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      pin: map['pin'] as String?,
      apiKey: map['apiKey'] as String?,
      selectedModel: map['selectedModel'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  User copyWith({
    int? id,
    String? identifier,
    String? name,
    DateTime? dateOfBirth,
    UserRole? role,
    String? pin,
    String? apiKey,
    String? selectedModel,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get maskedIdentifier {
    if (identifier.length <= 4) return identifier;
    return '${identifier.substring(0, 4)}${'*' * (identifier.length - 4)}';
  }
}
