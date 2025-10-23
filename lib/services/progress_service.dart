// lib/services/progress_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/progress_backend.dart'; 
import '../models/lesson_model.dart';
import '../services/firebase_service.dart';

class ProgressService {
  static Future<void> updateLessonProgress(BuildContext context, Lesson lesson) async {
    try {
      final progressBackend = Provider.of<ProgressBackend>(context, listen: false);
      await progressBackend.updateLessonProgress(lesson.level, true, lesson);
      await progressBackend.updateStudyTime(lesson.duration);
      
      // Update streak in Firebase
      await FirebaseService.updateStreak();
    } catch (e) {
      debugPrint('Error updating lesson progress: $e');
    }
  }

  static Future<void> updatePronunciationProgress(
    BuildContext context, 
    double score, 
    String word,
    String phonetic,
    String meaning
  ) async {
    try {
      final progressBackend = Provider.of<ProgressBackend>(context, listen: false);
      await progressBackend.updatePronunciationProgress(score, word, phonetic, meaning);
      await progressBackend.updateStudyTime(5); // Estimate 5 minutes per practice session
      
      // Update streak in Firebase
      await FirebaseService.updateStreak();
    } catch (e) {
      debugPrint('Error updating pronunciation progress: $e');
    }
  }

  // Load all user progress data
  static Future<void> loadUserProgress(BuildContext context) async {
    try {
      final progressBackend = Provider.of<ProgressBackend>(context, listen: false);
      await progressBackend.loadProgressData();
    } catch (e) {
      debugPrint('Error loading user progress: $e');
    }
  }
}