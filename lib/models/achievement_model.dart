// lib/models/achievement_model.dart
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final AchievementType type;
  final int progress;
  final int target;
  final bool achieved;
  final DateTime? achievedDate;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.type,
    required this.progress,
    required this.target,
    required this.achieved,
    this.achievedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'xpReward': xpReward,
      'type': type.toString(),
      'progress': progress,
      'target': target,
      'achieved': achieved,
      'achievedDate': achievedDate?.millisecondsSinceEpoch,
    };
  }

  static AchievementModel fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      xpReward: map['xpReward'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AchievementType.lesson,
      ),
      progress: map['progress'],
      target: map['target'],
      achieved: map['achieved'],
      achievedDate: map['achievedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['achievedDate']) 
          : null,
    );
  }

  // Calculate progress percentage
  double getProgressPercentage() {
    return (progress / target).clamp(0.0, 1.0);
  }

  // Get demo achievements for testing
  static List<AchievementModel> getDemoAchievements() {
    return [
      AchievementModel(
        id: 'first_lesson',
        title: 'First Lesson Complete',
        description: 'Complete your first lesson',
        icon: '🎯',
        xpReward: 50,
        type: AchievementType.lesson,
        progress: 1,
        target: 1,
        achieved: true,
        achievedDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AchievementModel(
        id: 'week_streak',
        title: '7-Day Streak',
        description: 'Practice for 7 days in a row',
        icon: '🔥',
        xpReward: 100,
        type: AchievementType.streak,
        progress: 12,
        target: 7,
        achieved: true,
        achievedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      AchievementModel(
        id: 'vocabulary_master',
        title: 'Vocabulary Master',
        description: 'Learn 100 words',
        icon: '📚',
        xpReward: 150,
        type: AchievementType.vocabulary,
        progress: 120,
        target: 100,
        achieved: true,
        achievedDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      AchievementModel(
        id: 'pronunciation_expert',
        title: 'Pronunciation Expert',
        description: 'Achieve 80% accuracy in pronunciation',
        icon: '🎙️',
        xpReward: 200,
        type: AchievementType.pronunciation,
        progress: 75,
        target: 80,
        achieved: false,
      ),
      AchievementModel(
        id: 'time_investor',
        title: 'Time Investor',
        description: 'Spend 5 hours practicing',
        icon: '⏱️',
        xpReward: 250,
        type: AchievementType.time,
        progress: 125,
        target: 300,
        achieved: false,
      ),
    ];
  }
}

enum AchievementType {
  lesson,
  streak,
  vocabulary,
  pronunciation,
  time,
}