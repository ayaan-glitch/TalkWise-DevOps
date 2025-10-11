// lib/models/user_progress_model.dart
class UserProgress {
  final String userId;
  final String currentLevel;
  final int totalLessons;
  final int completedLessons;
  final int dayStreak;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;
  final Map<String, dynamic> statistics;
  final DateTime? lastActive;

  UserProgress({
    required this.userId,
    required this.currentLevel,
    required this.totalLessons,
    required this.completedLessons,
    required this.dayStreak,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.statistics,
    this.lastActive,
  });

  // In progress_model.dart - Fix the fromJson method
factory UserProgress.fromJson(Map<String, dynamic> json) {
  return UserProgress(
    userId: json['user_id'] ?? 'mock_user_123', // Fixed this line
    currentLevel: json['current_level'] ?? 'beginner',
    totalLessons: json['total_lessons'] ?? 0,
    completedLessons: json['completed_lessons'] ?? 0,
    dayStreak: json['day_streak'] ?? 0,
    totalXp: json['total_xp'] ?? 0,
    currentLevelXp: json['current_level_xp'] ?? 0,
    nextLevelXp: json['next_level_xp'] ?? 100,
    statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
    lastActive: json['last_active'] != null
        ? DateTime.parse(json['last_active'])
        : null,
  );
}

  double get progressPercentage {
    if (nextLevelXp == 0) return 0.0;
    return (currentLevelXp / nextLevelXp).clamp(0.0, 1.0);
  }

  double get overallProgress {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons).clamp(0.0, 1.0);
  }
}