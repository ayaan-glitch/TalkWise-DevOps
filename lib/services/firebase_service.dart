// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../models/progress_model.dart';
import '../models/lesson_model.dart';
import 'dart:async';  

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Progress Collection
  static const String _userProgressCollection = 'user_progress';
  static const String _userLessonsCollection = 'user_lessons';
  static const String _userPronunciationCollection = 'user_pronunciation';

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  static bool get isUserLoggedIn => _auth.currentUser != null;

  // Save user progress
  static Future<void> saveUserProgress(UserProgress progress) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore
          .collection(_userProgressCollection)
          .doc(currentUserId)
          .set(progress.toJson());
    } catch (e) {
      print('Error saving user progress: $e');
      rethrow;
    }
  }

  // Get user progress
  static Future<UserProgress?> getUserProgress() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore
          .collection(_userProgressCollection)
          .doc(currentUserId)
          .get();
      
      if (doc.exists) {
        return UserProgress.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }

  // Save lesson progress
  static Future<void> saveLessonProgress(Lesson lesson, bool completed) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore
          .collection(_userLessonsCollection)
          .doc(currentUserId)
          .collection('lessons')
          .doc(lesson.id)
          .set({
        'lesson_id': lesson.id,
        'title': lesson.title,
        'level': lesson.level,
        'progress': lesson.progress,
        'is_completed': completed,
        'last_accessed': FieldValue.serverTimestamp(),
        'completed_at': completed ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving lesson progress: $e');
      rethrow;
    }
  }

  // Get user's lesson progress
  static Future<Map<String, dynamic>> getUserLessonProgress(String lessonId) async {
    if (currentUserId == null) return {};
    
    try {
      final doc = await _firestore
          .collection(_userLessonsCollection)
          .doc(currentUserId)
          .collection('lessons')
          .doc(lessonId)
          .get();
      
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting lesson progress: $e');
      return {};
    }
  }

  // Get all user lessons
  static Future<List<Map<String, dynamic>>> getAllUserLessons() async {
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection(_userLessonsCollection)
          .doc(currentUserId)
          .collection('lessons')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting all user lessons: $e');
      return [];
    }
  }

  // Save pronunciation practice
  static Future<void> savePronunciationPractice(
    String word, 
    double score, 
    String phonetic,
    String meaning
  ) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore
          .collection(_userPronunciationCollection)
          .doc(currentUserId)
          .collection('practice_sessions')
          .add({
        'word': word,
        'score': score,
        'phonetic': phonetic,
        'meaning': meaning,
        'practiced_at': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving pronunciation practice: $e');
      rethrow;
    }
  }

  // Get user pronunciation history
  static Future<List<Map<String, dynamic>>> getPronunciationHistory() async {
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection(_userPronunciationCollection)
          .doc(currentUserId)
          .collection('practice_sessions')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting pronunciation history: $e');
      return [];
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    if (currentUserId == null) return {};
    
    try {
      // Get lesson progress
      final lessons = await getAllUserLessons();
      final completedLessons = lessons.where((lesson) => 
        (lesson['is_completed'] ?? false)).length;
      final totalLessons = lessons.length;
      
      // Get pronunciation stats
      final pronunciationHistory = await getPronunciationHistory();
      final totalPracticeSessions = pronunciationHistory.length;
      final averageScore = pronunciationHistory.isNotEmpty 
          ? pronunciationHistory.map((p) => (p['score'] as num).toDouble()).reduce((a, b) => a + b) / pronunciationHistory.length
          : 0.0;
      
      // Get streak (simplified - you might want to implement proper streak calculation)
      final progressDoc = await _firestore
          .collection(_userProgressCollection)
          .doc(currentUserId)
          .get();
      
      final streak = progressDoc.exists ? (progressDoc.data()?['day_streak'] ?? 0) : 0;
      
      return {
        'completed_lessons': completedLessons,
        'total_lessons': totalLessons,
        'practice_sessions': totalPracticeSessions,
        'average_pronunciation_score': averageScore,
        'current_streak': streak,
        'total_time_studied': (totalPracticeSessions * 5) + (completedLessons * 25), // Estimate
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  // Add this method to firebase_service.dart
  static Future<void> updateStreak() async {
    if (currentUserId == null) return;
    
    try {
      final userProgress = await getUserProgress();
      if (userProgress != null) {
        // Simple streak implementation - in a real app, you'd check consecutive days
        final newStreak = userProgress.dayStreak + 1;
        
        await _firestore
            .collection(_userProgressCollection)
            .doc(currentUserId)
            .update({
          'day_streak': newStreak,
          'last_active': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Initialize user progress when they first sign up
  static Future<void> initializeUserProgress(String userId, String email) async {
    try {
      final initialProgress = UserProgress(
        userId: userId,
        currentLevel: 'beginner',
        totalLessons: 30,
        completedLessons: 0,
        dayStreak: 0,
        totalXp: 0,
        currentLevelXp: 0,
        nextLevelXp: 100,
        statistics: {
          'grammar_correct': 0,
          'vocabulary_correct': 0,
          'pronunciation_correct': 0,
          'conversation_correct': 0,
          'total_attempts': 0,
          'accuracy_rate': 0.0,
        },
        lastActive: DateTime.now(),
      );
      
      await _firestore
          .collection(_userProgressCollection)
          .doc(userId)
          .set(initialProgress.toJson());
    } catch (e) {
      print('Error initializing user progress: $e');
      rethrow;
    }
  }
}