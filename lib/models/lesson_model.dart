// lib/models/lesson_model.dart
// In lesson_model.dart, add this enum at the top
enum LessonCategory {
  tenses,
  idioms,
  verbs,
  phrases,
  pronunciation,
  vocabulary,
  conversation,
  grammar,
  business,
  writing,
  reading
}
class Lesson {
  final String id;
  final String title;
  final String description;
  final String level;
  final int lessonNumber;
  final String type;
  final int duration;
  final bool isUnlocked;
  final double progress;
  final String unit;
  final String category;
  final List<LessonSection> sections;
  final List<Exercise> exercises;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.lessonNumber,
    required this.type,
    required this.duration,
    required this.isUnlocked,
    required this.progress,
    required this.unit,
    required this.category,
    required this.sections,
    required this.exercises,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? 'beginner',
      lessonNumber: json['lesson_number'] ?? json['order'] ?? 0,
      type: json['type'] ?? 'conversation',
      duration: json['duration'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      category: json['category'] ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((section) => LessonSection.fromJson(section))
              .toList() ??
          [],
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((exercise) => Exercise.fromJson(exercise))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level,
      'lesson_number': lessonNumber,
      'type': type,
      'duration': duration,
      'is_unlocked': isUnlocked,
      'progress': progress,
      'unit': unit,
      'category': category,
      'sections': sections.map((section) => section.toJson()).toList(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? level,
    int? lessonNumber,
    String? type,
    int? duration,
    bool? isUnlocked,
    double? progress,
    String? unit,
    String? category,
    List<LessonSection>? sections,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      sections: sections ?? this.sections,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LessonSection {
  final String id;
  final String title;
  final String content;
  final String type;
  final List<String> examples;
  final int order;

  LessonSection({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.examples,
    this.order = 0,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'theory',
      examples: List<String>.from(json['examples'] ?? []),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'examples': examples,
      'order': order,
    };
  }
}

class Exercise {
  final String id;
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? hint;
  final int points;
  final int timeLimit;

  Exercise({
    required this.id,
    required this.type,
    required this.question,
    required this.options, // Make it required
    required this.correctAnswer,
    required this.explanation,
    this.hint,
    this.points = 10,
    this.timeLimit = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
      hint: json['hint'],
      points: json['points'] ?? 10,
      timeLimit: json['time_limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'hint': hint,
      'points': points,
      'time_limit': timeLimit,
    };
  }
}