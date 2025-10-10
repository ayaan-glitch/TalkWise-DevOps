// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final int level;
  final Map<String, dynamic> progress;
  final List<dynamic> achievements;
  final DateTime createdAt;
  final DateTime lastLogin;
  final int streak;
  final Map<String, dynamic> stats;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.level = 1,
    this.progress = const {},
    this.achievements = const [],
    required this.createdAt,
    required this.lastLogin,
    this.streak = 0,
    this.stats = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'level': level,
      'progress': progress,
      'achievements': achievements,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
      'streak': streak,
      'stats': stats,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      level: map['level'],
      progress: Map<String, dynamic>.from(map['progress']),
      achievements: List<dynamic>.from(map['achievements']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastLogin: DateTime.fromMillisecondsSinceEpoch(map['lastLogin']),
      streak: map['streak'],
      stats: Map<String, dynamic>.from(map['stats']),
    );
  }

  // Create a demo user for testing
  static UserModel demoUser() {
    return UserModel(
      uid: 'demo_user_123',
      email: 'demo@talkwise.com',
      displayName: 'Demo User',
      photoURL: null,
      level: 2, // A2 level
      progress: {
        'lessons': {
          'lesson_1': {'completed': true, 'score': 85},
          'lesson_2': {'completed': true, 'score': 90},
          'lesson_3': {'completed': false, 'score': 0},
        },
        'vocabulary': 120,
        'pronunciation': 75,
      },
      achievements: ['first_lesson', 'week_streak', 'vocabulary_master'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLogin: DateTime.now(),
      streak: 12,
      stats: {
        'totalTime': 12500, // in minutes
        'sessions': 45,
        'accuracy': 85,
      },
    );
  }
}