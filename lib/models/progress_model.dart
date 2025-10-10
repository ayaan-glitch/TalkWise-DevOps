// lib/models/progress_model.dart
class ProgressModel {
  final String userId;
  final Map<String, dynamic> lessons;
  final Map<String, dynamic> vocabulary;
  final Map<String, dynamic> pronunciation;
  final DateTime lastUpdated;
  final int totalXP;
  final int level;
  final int streak;
  final Map<String, dynamic> stats;

  ProgressModel({
    required this.userId,
    required this.lessons,
    required this.vocabulary,
    required this.pronunciation,
    required this.lastUpdated,
    required this.totalXP,
    required this.level,
    required this.streak,
    required this.stats,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessons': lessons,
      'vocabulary': vocabulary,
      'pronunciation': pronunciation,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'totalXP': totalXP,
      'level': level,
      'streak': streak,
      'stats': stats,
    };
  }

  static ProgressModel fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      userId: map['userId'],
      lessons: Map<String, dynamic>.from(map['lessons']),
      vocabulary: Map<String, dynamic>.from(map['vocabulary']),
      pronunciation: Map<String, dynamic>.from(map['pronunciation']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      totalXP: map['totalXP'],
      level: map['level'],
      streak: map['streak'],
      stats: Map<String, dynamic>.from(map['stats']),
    );
  }

  // Calculate completion percentage
  double getCompletionPercentage() {
    if (lessons.isEmpty) return 0.0;
    
    int completed = 0;
    lessons.forEach((key, value) {
      if (value['completed'] == true) completed++;
    });
    
    return completed / lessons.length;
  }

  // Get current level based on XP
  static int calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    if (xp < 1500) return 5;
    return 6; // Max level for demo
  }

  // Create demo progress for testing
  static ProgressModel demoProgress(String userId) {
    return ProgressModel(
      userId: userId,
      lessons: {
        'lesson_1': {'completed': true, 'score': 85, 'timeSpent': 15},
        'lesson_2': {'completed': true, 'score': 90, 'timeSpent': 20},
        'lesson_3': {'completed': false, 'score': 0, 'timeSpent': 0},
      },
      vocabulary: {
        'totalWords': 120,
        'masteredWords': 85,
        'practiceWords': 35,
      },
      pronunciation: {
        'accuracy': 75,
        'totalPractice': 45,
        'lastPractice': DateTime.now().millisecondsSinceEpoch,
      },
      lastUpdated: DateTime.now(),
      totalXP: 450,
      level: calculateLevel(450),
      streak: 12,
      stats: {
        'totalTime': 125, // in minutes
        'sessions': 45,
        'daysActive': 30,
        'averageAccuracy': 85,
      },
    );
  }
}