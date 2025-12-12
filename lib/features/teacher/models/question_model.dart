// Models for questions in the question bank.

enum QuestionType { multipleChoice, essay }

/// Base class for all question types.
abstract class Question {
  final int? id;
  final int teacherId;
  final int? classId;
  final QuestionType type;
  final String topic;
  final String grade;
  final String questionText;
  final String feedback;
  final DateTime createdAt;

  Question({
    this.id,
    required this.teacherId,
    this.classId,
    required this.type,
    required this.topic,
    required this.grade,
    required this.questionText,
    required this.feedback,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap();

  static Question fromMap(Map<String, dynamic> map) {
    final type = map['type'] == 'mc'
        ? QuestionType.multipleChoice
        : QuestionType.essay;

    if (type == QuestionType.multipleChoice) {
      return MultipleChoiceQuestion.fromMap(map);
    } else {
      return EssayQuestion.fromMap(map);
    }
  }
}

/// Multiple choice question with options A-D, answer key, and feedback.
class MultipleChoiceQuestion extends Question {
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer; // 'A', 'B', 'C', or 'D'

  MultipleChoiceQuestion({
    super.id,
    required super.teacherId,
    super.classId,
    required super.topic,
    required super.grade,
    required super.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required super.feedback,
    super.createdAt,
  }) : super(type: QuestionType.multipleChoice);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'class_id': classId,
      'type': 'mc',
      'topic': topic,
      'grade': grade,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
      'feedback': feedback,
      'rubric': null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MultipleChoiceQuestion.fromMap(Map<String, dynamic> map) {
    return MultipleChoiceQuestion(
      id: map['id'],
      teacherId: map['teacher_id'],
      classId: map['class_id'],
      topic: map['topic'] ?? '',
      grade: map['grade'] ?? '',
      questionText: map['question_text'] ?? '',
      optionA: map['option_a'] ?? '',
      optionB: map['option_b'] ?? '',
      optionC: map['option_c'] ?? '',
      optionD: map['option_d'] ?? '',
      correctAnswer: map['correct_answer'] ?? 'A',
      feedback: map['feedback'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  MultipleChoiceQuestion copyWith({
    int? id,
    int? teacherId,
    int? classId,
    String? topic,
    String? grade,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctAnswer,
    String? feedback,
  }) {
    return MultipleChoiceQuestion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      topic: topic ?? this.topic,
      grade: grade ?? this.grade,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      feedback: feedback ?? this.feedback,
    );
  }
}

/// Essay question with rubric and feedback.
class EssayQuestion extends Question {
  final String rubric;

  EssayQuestion({
    super.id,
    required super.teacherId,
    super.classId,
    required super.topic,
    required super.grade,
    required super.questionText,
    required this.rubric,
    required super.feedback,
    super.createdAt,
  }) : super(type: QuestionType.essay);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'class_id': classId,
      'type': 'essay',
      'topic': topic,
      'grade': grade,
      'question_text': questionText,
      'option_a': null,
      'option_b': null,
      'option_c': null,
      'option_d': null,
      'correct_answer': null,
      'feedback': feedback,
      'rubric': rubric,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EssayQuestion.fromMap(Map<String, dynamic> map) {
    return EssayQuestion(
      id: map['id'],
      teacherId: map['teacher_id'],
      classId: map['class_id'],
      topic: map['topic'] ?? '',
      grade: map['grade'] ?? '',
      questionText: map['question_text'] ?? '',
      rubric: map['rubric'] ?? '',
      feedback: map['feedback'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  EssayQuestion copyWith({
    int? id,
    int? teacherId,
    int? classId,
    String? topic,
    String? grade,
    String? questionText,
    String? rubric,
    String? feedback,
  }) {
    return EssayQuestion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      topic: topic ?? this.topic,
      grade: grade ?? this.grade,
      questionText: questionText ?? this.questionText,
      rubric: rubric ?? this.rubric,
      feedback: feedback ?? this.feedback,
    );
  }
}
