// lib/pages/home_backend.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeBackend with ChangeNotifier {
  static final HomeBackend _instance = HomeBackend._internal();
  factory HomeBackend() => _instance;
  
  HomeBackend._internal() {
    _initializeHomeData();
  }

  // User progress state
  bool _isLoading = true;
  String _userName = 'Learner';
  int _dayStreak = 0;
  
  // Progress tracking
  final int _totalLessons = 20;
  int _lessonsCompletedToday = 0;
  int _pronunciationSessionsToday = 0;
  
  // Study goals
  int _dailyGoalMinutes = 30;
  bool _dailyGoalCompleted = false;
  
  // Today's lessons
  List<DailyLesson> _todaysLessons = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get dayStreak => _dayStreak;
  int get totalLessons => _totalLessons;
  int get lessonsCompletedToday => _lessonsCompletedToday;
  int get pronunciationSessionsToday => _pronunciationSessionsToday;
  List<DailyLesson> get todaysLessons => _todaysLessons;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  bool get dailyGoalCompleted => _dailyGoalCompleted;
  
  // Initialize home data
  Future<void> _initializeHomeData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadUserPreferences();
      await _generateTodaysLessons();
      await _checkDailyGoals();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing home data: $e');
      }
      await _initializeDefaultData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user preferences from local storage
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _userName = prefs.getString('userName') ?? 'Learner';
      _dayStreak = prefs.getInt('dayStreak') ?? 0;
      _dailyGoalMinutes = prefs.getInt('dailyGoalMinutes') ?? 30;
      _dailyGoalCompleted = prefs.getBool('dailyGoalCompleted') ?? false;
      
      // Load today's activity
      final today = DateTime.now().toIso8601String().split('T')[0];
      _lessonsCompletedToday = prefs.getInt('lessonsCompleted_$today') ?? 0;
      _pronunciationSessionsToday = prefs.getInt('pronunciationSessions_$today') ?? 0;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user preferences: $e');
      }
    }
  }

  // Generate today's recommended lessons
  Future<void> _generateTodaysLessons() async {
    _todaysLessons = [
      DailyLesson(
        title: 'Greetings & Introductions',
        duration: 15,
        status: 'Start',
        isCompleted: false,
        category: 'Basics',
        difficulty: 'Beginner',
      ),
      DailyLesson(
        title: 'Asking for Directions',
        duration: 20,
        status: 'Start',
        isCompleted: false,
        category: 'Conversation',
        difficulty: 'Beginner',
      ),
      DailyLesson(
        title: 'Ordering Food',
        duration: 18,
        status: 'Start',
        isCompleted: false,
        category: 'Practical',
        difficulty: 'Beginner',
      ),
    ];
  }

  // Check and update daily goals
  Future<void> _checkDailyGoals() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();
    
    // Check if daily goal is completed
    _dailyGoalCompleted = prefs.getBool('dailyGoalCompleted_$today') == true;
    
    // Update streak
    await _updateStreak();
  }

  // Update user streak
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudyDate = prefs.getString('lastStudyDate');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastStudyDate != today) {
      // Check if user studied yesterday to maintain streak
      final yesterday = DateTime.now().subtract(const Duration(days:1)).toIso8601String().split('T')[0];
      final yesterdayStudyTime = prefs.getInt('studyTime_$yesterday') ?? 0;
      
      if (yesterdayStudyTime > 0 || lastStudyDate == yesterday) {
        _dayStreak++;
      } else {
        _dayStreak = 1; // Reset streak if missed a day
      }
      
      await prefs.setInt('dayStreak', _dayStreak);
      await prefs.setString('lastStudyDate', today);
    }
  }

  // Initialize default data for new users
  Future<void> _initializeDefaultData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userName = 'Learner';
    _dayStreak = 0;
    _lessonsCompletedToday = 0;
    _pronunciationSessionsToday = 0;
    _dailyGoalCompleted = false;
    
    await prefs.setString('userName', _userName);
    await prefs.setInt('dayStreak', _dayStreak);
    await prefs.setInt('dailyGoalMinutes', _dailyGoalMinutes);
    
    await _generateTodaysLessons();
  }

  // Mark lesson as completed
  Future<void> completeLesson(String lessonTitle) async {
    _lessonsCompletedToday++;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lessonsCompleted_$today', _lessonsCompletedToday);
    
    // Update the specific lesson status
    for (var lesson in _todaysLessons) {
      if (lesson.title == lessonTitle) {
        lesson.isCompleted = true;
        lesson.status = 'Complete';
        break;
      }
    }
    
    await _checkDailyGoals();
    notifyListeners();
  }

  // Record pronunciation practice session - FIXED METHOD SIGNATURE
  Future<void> recordPronunciationSession() async {
  _pronunciationSessionsToday++;
  
  final today = DateTime.now().toIso8601String().split('T')[0];
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('pronunciationSessions_$today', _pronunciationSessionsToday);
  
  await _checkDailyGoals();
  notifyListeners();
}

  // Update study time - ADD THIS METHOD
  Future<void> updateStudyTime() async {
    // This method is called from other pages to update study time
    // The actual study time is managed by AppStateManager
    await _checkDailyGoals();
    notifyListeners();
  }

  // Get motivational message based on time of day and progress
  String getMotivationalMessage(int todayStudyTime, bool dailyGoalCompleted) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    
    if (todayStudyTime == 0) {
      return '$timeGreeting! 👋\nReady to start your English journey today?';
    } else if (todayStudyTime < 15) {
      return '$timeGreeting! 👋\nGreat start! Keep building your momentum.';
    } else if (dailyGoalCompleted) {
      return '$timeGreeting! 👋\nAmazing! You completed your daily goal!';
    } else {
      return '$timeGreeting! 👋\nYou\'re making great progress today!';
    }
  }

  // Get progress summary for home page
  Map<String, dynamic> getProgressSummary(
    String userLevel, 
    int completedLessons, 
    double overallProgress, 
    double pronunciationAccuracy, 
    int todayStudyTime
  ) {
    return {
      'level': userLevel,
      'completedLessons': '$completedLessons/$_totalLessons',
      'progressPercentage': overallProgress,
      'dayStreak': _dayStreak,
      'pronunciationAccuracy': pronunciationAccuracy,
      'todayStudyTime': todayStudyTime,
    };
  }

  // Reset daily progress (for testing)
  Future<void> resetDailyProgress() async {
    _lessonsCompletedToday = 0;
    _pronunciationSessionsToday = 0;
    _dailyGoalCompleted = false;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('lessonsCompleted_$today', 0);
    await prefs.setInt('pronunciationSessions_$today', 0);
    await prefs.setBool('dailyGoalCompleted_$today', false);
    
    // Reset today's lessons status
    for (var lesson in _todaysLessons) {
      lesson.isCompleted = false;
      lesson.status = 'Start';
    }
    
    notifyListeners();
  }

  // Set daily goal
  Future<void> setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoalMinutes', minutes);
    
    await _checkDailyGoals();
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    
    await _loadUserPreferences();
    await _checkDailyGoals();
    
    _isLoading = false;
    notifyListeners();
  }
}

// Daily Lesson model
class DailyLesson {
  final String title;
  final int duration;
  String status;
  bool isCompleted;
  final String category;
  final String difficulty;

  DailyLesson({
    required this.title,
    required this.duration,
    required this.status,
    required this.isCompleted,
    required this.category,
    required this.difficulty,
  });
}