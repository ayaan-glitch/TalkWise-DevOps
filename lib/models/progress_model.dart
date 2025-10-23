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

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_level': currentLevel,
      'total_lessons': totalLessons,
      'completed_lessons': completedLessons,
      'day_streak': dayStreak,
      'total_xp': totalXp,
      'current_level_xp': currentLevelXp,
      'next_level_xp': nextLevelXp,
      'statistics': statistics,
      'last_active': lastActive?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['user_id'] ?? '',
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
}