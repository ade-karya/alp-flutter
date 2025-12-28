import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher }

class User {
  final String? uid; // Firebase UID (primary identifier)
  final int? id; // Legacy local SQLite ID (for backward compatibility)
  final String?
  identifier; // NISN for students, NUPTK for teachers (optional now)
  final String? email; // Email from Google Sign-In
  final String name;
  final DateTime dateOfBirth;
  final UserRole role;
  final String? pin; // Legacy - deprecated, kept for migration
  final String? apiKey;
  final String? selectedModel;
  final String? photoUrl; // Profile photo from Google
  final DateTime createdAt;

  User({
    this.uid,
    this.id,
    this.identifier,
    this.email,
    required this.name,
    required this.dateOfBirth,
    required this.role,
    this.pin,
    this.apiKey,
    this.selectedModel,
    this.photoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'identifier': identifier,
      'email': email,
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'role': role.name,
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      uid: doc.id,
      identifier: data['identifier'] as String?,
      email: data['email'] as String?,
      name: data['name'] as String? ?? 'User',
      dateOfBirth:
          (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1),
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.student,
      ),
      apiKey: data['apiKey'] as String?,
      selectedModel: data['selectedModel'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Legacy: Convert to local SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identifier': identifier ?? '',
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'role': role.name,
      'pin': pin,
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Legacy: Create from local SQLite map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      identifier: map['identifier'] as String?,
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
    String? uid,
    int? id,
    String? identifier,
    String? email,
    String? name,
    DateTime? dateOfBirth,
    UserRole? role,
    String? pin,
    String? apiKey,
    String? selectedModel,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      email: email ?? this.email,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get maskedIdentifier {
    if (identifier == null || identifier!.isEmpty) return '';
    if (identifier!.length <= 4) return identifier!;
    return '${identifier!.substring(0, 4)}${'*' * (identifier!.length - 4)}';
  }

  String get displayEmail {
    if (email == null || email!.isEmpty) return '';
    return email!;
  }
}
