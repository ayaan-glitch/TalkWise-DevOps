// lib/pages/progress_backend.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityType {
  lessonCompleted,
  pronunciationPractice,
  highScore,
}

class ActivityItem {
  final ActivityType type;
  final String description;
  final String timeAgo;
  final DateTime timestamp;

  ActivityItem({
    required this.type,
    required this.description,
    required this.timeAgo,
    required this.timestamp,
  });
}

class ProgressBackend with ChangeNotifier {
  bool _isLoading = false;
  
  // Lessons progress
  int _completedLessonsCount = 0;
  final int _totalLessonsCount = 30; // Fixed total for simplicity
  int _beginnerCompleted = 0;
  final int _beginnerTotal = 10;
  int _intermediateCompleted = 0;
  final int _intermediateTotal = 10;
  int _advancedCompleted = 0;
  final int _advancedTotal = 10;
  
  // Pronunciation progress
  int _wordsPracticed = 0;
  double _averagePronunciationScore = 0.0;
  double _bestPronunciationScore = 0.0;
  int _practiceSessions = 0;
  
  // Overall progress
  double _overallProgress = 0.0;
  int _currentStreak = 0;
  int _totalTimeStudied = 0;
  
  List<ActivityItem> _recentActivities = [];

  // Getters
  bool get isLoading => _isLoading;
  int get completedLessonsCount => _completedLessonsCount;
  int get totalLessonsCount => _totalLessonsCount;
  int get beginnerCompleted => _beginnerCompleted;
  int get beginnerTotal => _beginnerTotal;
  int get intermediateCompleted => _intermediateCompleted;
  int get intermediateTotal => _intermediateTotal;
  int get advancedCompleted => _advancedCompleted;
  int get advancedTotal => _advancedTotal;
  int get wordsPracticed => _wordsPracticed;
  double get averagePronunciationScore => _averagePronunciationScore;
  double get bestPronunciationScore => _bestPronunciationScore;
  int get practiceSessions => _practiceSessions;
  double get overallProgress => _overallProgress;
  int get currentStreak => _currentStreak;
  int get totalTimeStudied => _totalTimeStudied;
  List<ActivityItem> get recentActivities => _recentActivities;

  // Load progress data from local storage
  Future<void> loadProgressData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadFromLocalStorage();
      await _updateOverallProgress();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading progress data: $e');
      }
      await _initializeDefaultData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _completedLessonsCount = prefs.getInt('completedLessonsCount') ?? 0;
      _beginnerCompleted = prefs.getInt('beginnerCompleted') ?? 0;
      _intermediateCompleted = prefs.getInt('intermediateCompleted') ?? 0;
      _advancedCompleted = prefs.getInt('advancedCompleted') ?? 0;
      
      _wordsPracticed = prefs.getInt('wordsPracticed') ?? 0;
      _averagePronunciationScore = prefs.getDouble('averagePronunciationScore') ?? 0.0;
      _bestPronunciationScore = prefs.getDouble('bestPronunciationScore') ?? 0.0;
      _practiceSessions = prefs.getInt('practiceSessions') ?? 0;
      
      _overallProgress = prefs.getDouble('overallProgress') ?? 0.0;
      _currentStreak = prefs.getInt('currentStreak') ?? 0;
      _totalTimeStudied = prefs.getInt('totalTimeStudied') ?? 0;
      
      _loadRecentActivitiesFromPrefs(prefs);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from local storage: $e');
      }
      await _initializeDefaultData();
    }
  }

  // Load recent activities from shared preferences
  void _loadRecentActivitiesFromPrefs(SharedPreferences prefs) {
    final activitiesJson = prefs.getStringList('recentActivities');
    if (activitiesJson != null && activitiesJson.isNotEmpty) {
      _recentActivities = activitiesJson.map((json) {
        try {
          final parts = json.split('|');
          if (parts.length >= 4) {
            return ActivityItem(
              type: ActivityType.values[int.parse(parts[0])],
              description: parts[1],
              timeAgo: parts[2],
              timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3])),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing activity: $e');
          }
        }
        return _createDefaultActivity();
      }).toList();
    } else {
      _createSampleActivities();
    }
  }

  // Create sample activities for new users
  void _createSampleActivities() {
    _recentActivities = [
      ActivityItem(
        type: ActivityType.pronunciationPractice,
        description: 'Start your first pronunciation practice',
        timeAgo: 'Waiting for you',
        timestamp: DateTime.now(),
      ),
      ActivityItem(
        type: ActivityType.lessonCompleted,
        description: 'Complete your first lesson',
        timeAgo: 'Waiting for you',
        timestamp: DateTime.now(),
      ),
    ];
  }

  // Create a default activity
  ActivityItem _createDefaultActivity() {
    return ActivityItem(
      type: ActivityType.lessonCompleted,
      description: 'Started learning journey',
      timeAgo: 'Just now',
      timestamp: DateTime.now(),
    );
  }

  // Initialize with default data for new users
  Future<void> _initializeDefaultData([SharedPreferences? prefs]) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    
    _completedLessonsCount = 0;
    _beginnerCompleted = 0;
    _intermediateCompleted = 0;
    _advancedCompleted = 0;
    
    _wordsPracticed = 0;
    _averagePronunciationScore = 0.0;
    _bestPronunciationScore = 0.0;
    _practiceSessions = 0;
    
    _overallProgress = 0.0;
    _currentStreak = 0;
    _totalTimeStudied = 0;
    
    _createSampleActivities();
    
    await _saveProgressData(sharedPrefs);
  }

  // Save progress data to shared preferences
  Future<void> _saveProgressData(SharedPreferences prefs) async {
    await prefs.setInt('completedLessonsCount', _completedLessonsCount);
    await prefs.setInt('beginnerCompleted', _beginnerCompleted);
    await prefs.setInt('intermediateCompleted', _intermediateCompleted);
    await prefs.setInt('advancedCompleted', _advancedCompleted);
    
    await prefs.setInt('wordsPracticed', _wordsPracticed);
    await prefs.setDouble('averagePronunciationScore', _averagePronunciationScore);
    await prefs.setDouble('bestPronunciationScore', _bestPronunciationScore);
    await prefs.setInt('practiceSessions', _practiceSessions);
    
    await prefs.setDouble('overallProgress', _overallProgress);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('totalTimeStudied', _totalTimeStudied);
    
    // Save recent activities
    final activitiesJson = _recentActivities.map((activity) {
      return '${activity.type.index}|${activity.description}|${_getTimeAgo(activity.timestamp)}|${activity.timestamp.millisecondsSinceEpoch}';
    }).toList();
    await prefs.setStringList('recentActivities', activitiesJson);
  }

  // Helper method to get time ago string
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
  }

  // Called when a lesson is completed
  Future<void> updateLessonProgress(String level, bool isCompleted, String lessonTitle) async {
    try {
      // Update local state
      switch (level.toLowerCase()) {
        case 'beginner':
          if (isCompleted) {
            _beginnerCompleted++;
            _completedLessonsCount++;
          } else {
            _beginnerCompleted = (_beginnerCompleted - 1).clamp(0, _beginnerTotal);
            _completedLessonsCount = (_completedLessonsCount - 1).clamp(0, _totalLessonsCount);
          }
          break;
        case 'intermediate':
          if (isCompleted) {
            _intermediateCompleted++;
            _completedLessonsCount++;
          } else {
            _intermediateCompleted = (_intermediateCompleted - 1).clamp(0, _intermediateTotal);
            _completedLessonsCount = (_completedLessonsCount - 1).clamp(0, _totalLessonsCount);
          }
          break;
        case 'advanced':
          if (isCompleted) {
            _advancedCompleted++;
            _completedLessonsCount++;
          } else {
            _advancedCompleted = (_advancedCompleted - 1).clamp(0, _advancedTotal);
            _completedLessonsCount = (_completedLessonsCount - 1).clamp(0, _totalLessonsCount);
          }
          break;
      }
      
      // Add to recent activities
      if (isCompleted) {
        _addActivity(ActivityItem(
          type: ActivityType.lessonCompleted,
          description: 'Completed $lessonTitle',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
        ));
      }
      
      await _updateOverallProgress();
      notifyListeners();
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await _saveProgressData(prefs);
      
    } catch (e) {
      print('Error updating lesson progress: $e');
    }
  }

  // Called when pronunciation practice is completed
  Future<void> updatePronunciationProgress(double score, String word, String phonetic, String meaning) async {
    try {
      // Update local state
      _wordsPracticed++;
      _practiceSessions++;
      
      // Update average score
      _averagePronunciationScore = ((_averagePronunciationScore * (_practiceSessions - 1)) + score) / _practiceSessions;
      
      // Update best score if applicable
      if (score > _bestPronunciationScore) {
        _bestPronunciationScore = score;
        
        // Add high score activity
        _addActivity(ActivityItem(
          type: ActivityType.highScore,
          description: 'Achieved ${score.toStringAsFixed(1)}% for "$word"',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
        ));
      } else {
        // Add regular practice activity
        _addActivity(ActivityItem(
          type: ActivityType.pronunciationPractice,
          description: 'Practiced "$word" - ${score.toStringAsFixed(1)}%',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
        ));
      }
      
      await _updateOverallProgress();
      notifyListeners();
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await _saveProgressData(prefs);

      
    } catch (e) {
      print('Error updating pronunciation progress: $e');
    }
  }

  // Update study time
  Future<void> updateStudyTime(int minutes) async {
    _totalTimeStudied += minutes;
    
    // Update streak (simplified - count any study session)
    if (minutes > 0) {
      _currentStreak++; // In real app, you'd check consecutive days
    }
    
    notifyListeners();
    
    // Save to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await _saveProgressData(prefs);
  }

  // Update overall progress calculation
  Future<void> _updateOverallProgress() async {
    // Calculate weighted progress (50% lessons, 50% pronunciation)
    final lessonsProgress = _totalLessonsCount > 0 
        ? (_completedLessonsCount / _totalLessonsCount * 100) 
        : 0;
    
    final pronunciationProgress = _practiceSessions > 0 
        ? (_averagePronunciationScore * 0.5) + (_practiceSessions / 20 * 50).clamp(0, 50)
        : 0;
    
    _overallProgress = (lessonsProgress * 0.5) + (pronunciationProgress * 0.5);
    _overallProgress = _overallProgress.clamp(0.0, 100.0);
  }

  // Add activity to recent activities (keep only last 10)
  void _addActivity(ActivityItem activity) {
    _recentActivities.insert(0, activity);
    if (_recentActivities.length > 10) {
      _recentActivities = _recentActivities.sublist(0, 10);
    }
  }

  // Reset all progress (for testing/debugging)
  Future<void> resetProgress() async {
    _completedLessonsCount = 0;
    _beginnerCompleted = 0;
    _intermediateCompleted = 0;
    _advancedCompleted = 0;
    _wordsPracticed = 0;
    _averagePronunciationScore = 0.0;
    _bestPronunciationScore = 0.0;
    _practiceSessions = 0;
    _overallProgress = 0.0;
    _currentStreak = 0;
    _totalTimeStudied = 0;
    _recentActivities.clear();
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await _saveProgressData(prefs);
  }

  // Get progress percentage for each level
  double getBeginnerProgress() {
    return _beginnerTotal > 0 ? (_beginnerCompleted / _beginnerTotal) * 100 : 0;
  }

  double getIntermediateProgress() {
    return _intermediateTotal > 0 ? (_intermediateCompleted / _intermediateTotal) * 100 : 0;
  }

  double getAdvancedProgress() {
    return _advancedTotal > 0 ? (_advancedCompleted / _advancedTotal) * 100 : 0;
  }

  // Get icon for activity type
  String getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.lessonCompleted:
        return '📚';
      case ActivityType.pronunciationPractice:
        return '🎤';
      case ActivityType.highScore:
        return '🏆';
      default:
        return '📝';
    }
  }
}