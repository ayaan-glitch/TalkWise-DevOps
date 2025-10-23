import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../services/api_service.dart';
import '../services/app_state_manager.dart';
import 'quiz_page.dart'; 
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LessonsBackend with ChangeNotifier {
  static final LessonsBackend _instance = LessonsBackend._internal();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int currentLessonIndex = 0;
  Set<int> unlockedLessons = {0};

  factory LessonsBackend() => _instance;
  LessonsBackend._internal() {
    _initTts();
    _initSpeech();
  }

  List<Lesson> _lessons = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  // TTS and Voice Navigation
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  double _speechRate = 1.0;
  double _speechVolume = 1.0;

  // Getters
  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get speechVolume => _speechVolume;

  // Initialize TTS
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_speechVolume);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _ttsCompleter?.complete();
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _ttsCompleter?.complete();
        debugPrint('TTS Error: $msg');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Add this method to LessonsBackend class in lessons_backend.dart
Future<void> refreshProgress() async {
  try {
    await _loadProgressFromFirestore();
    
    // Update lesson unlocked status based on loaded progress
    for (int i = 0; i < _lessons.length; i++) {
      if (unlockedLessons.contains(i)) {
        _lessons[i] = _lessons[i].copyWith(isUnlocked: true);
      } else {
        _lessons[i] = _lessons[i].copyWith(isUnlocked: false);
      }
    }
    
    notifyListeners();
    debugPrint('✅ Progress refreshed: $unlockedLessons lessons unlocked');
  } catch (e) {
    debugPrint('❌ Error refreshing progress: $e');
  }
}

  Future<void> listenForCommandWithFallback(Function(String) onCommand) async {
    try {
      await listenForCommand(onCommand);
    } catch (e) {
      debugPrint('Primary speech recognition failed: $e');

      try {
        final stt.SpeechToText fallbackSpeech = stt.SpeechToText();
        bool available = await fallbackSpeech.initialize();

        if (available) {
          _isListening = true;
          notifyListeners();

          await fallbackSpeech.listen(
            onResult: (result) {
              if (result.finalResult) {
                final command = result.recognizedWords.toLowerCase();
                debugPrint('Fallback voice command: $command');
                onCommand(command);
                fallbackSpeech.stop();
                _isListening = false;
                notifyListeners();
              }
            },
            listenFor: const Duration(seconds: 5),
          );
        }
      } catch (fallbackError) {
        debugPrint('Fallback speech also failed: $fallbackError');
        _isListening = false;
        notifyListeners();
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          _isListening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _isListening = false;
          notifyListeners();
        },
      );

      if (!available) {
        debugPrint('Speech recognition not available');
      } else {
        debugPrint('Speech recognition initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Completer<void>? _ttsCompleter;

  Future<void> speak(String text) async {
    try {
      _ttsCompleter = Completer<void>();
      _isSpeaking = true;
      notifyListeners();

      await _tts.speak(text);

      await _ttsCompleter?.future;
    } catch (e) {
      debugPrint('Error speaking: $e');
      _ttsCompleter?.complete();
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    notifyListeners();
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume;
    await _tts.setVolume(volume);
    notifyListeners();
  }

  Future<void> listenForCommand(Function(String) onCommand) async {
    try {
      if (!_speech.isAvailable) {
        await _initSpeech();
      }

      if (!_speech.isAvailable) {
        debugPrint('Speech recognition not available, skipping listen');
        return;
      }

      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
        return;
      }

      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final command = result.recognizedWords.toLowerCase();
            debugPrint('Voice command received: $command');
            onCommand(command);
            _speech.stop();
            _isListening = false;
            notifyListeners();
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
        onSoundLevelChange: (level) {},
      );
    } catch (e) {
      debugPrint('Error listening: $e');
      _isListening = false;
      notifyListeners();

      if (e.toString().contains('Null') || e.toString().contains('Event')) {
        debugPrint('Speech recognition compatibility issue detected');
      }
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping listening: $e');
    }
  }

  List<Lesson> getLessonsByLevel(String level) {
    return _lessons.where((lesson) => lesson.level == level).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  Future<void> loadLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lessons = await _apiService.getLessons();

      // 🔹 Load user progress after fetching lessons
      await _loadProgressFromFirestore();

      // Unlock saved lessons
      for (int i = 0; i < _lessons.length; i++) {
        if (unlockedLessons.contains(i)) {
          _lessons[i] = _lessons[i].copyWith(isUnlocked: true);
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading lessons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FIRESTORE PROGRESS SYNC ---

  Future<void> _saveProgressToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('userProgress').doc(user.uid);

      await userDoc.set({
        'currentLessonIndex': currentLessonIndex,
        'unlockedLessons': unlockedLessons.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Progress saved to Firestore for ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving progress to Firestore: $e');
    }
  }

  Future<void> _loadProgressFromFirestore() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore
        .collection('userProgress')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        currentLessonIndex = data['currentLessonIndex'] ?? 0;
        unlockedLessons = Set<int>.from(
          List<int>.from(data['unlockedLessons'] ?? [0]),
        );
        
        // Update lesson states based on loaded progress
        for (int i = 0; i < _lessons.length; i++) {
          if (unlockedLessons.contains(i)) {
            _lessons[i] = _lessons[i].copyWith(isUnlocked: true);
          } else {
            _lessons[i] = _lessons[i].copyWith(isUnlocked: false);
          }
        }
        
        debugPrint(
          '✅ Progress loaded: Lesson $currentLessonIndex, unlocked: $unlockedLessons',
        );
      }
    } else {
      debugPrint('ℹ️ No saved progress found, starting fresh.');
    }
    notifyListeners();
  } catch (e) {
    debugPrint('❌ Error loading progress from Firestore: $e');
  }
}

 Future<void> completeLesson(String lessonId, {BuildContext? context}) async {
  try {
    final lessonIndex = _lessons.indexWhere(
      (lesson) => lesson.id == lessonId,
    );
    if (lessonIndex == -1) {
      throw Exception('Lesson not found');
    }

    final currentLesson = _lessons[lessonIndex];

    // Mark current lesson as completed
    _lessons[lessonIndex] = _lessons[lessonIndex].copyWith(
      progress: 1.0,
      isCompleted: true,
    );

    if (context != null) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      appState.incrementCompletedLessons();
      appState.setLastAccessedLesson(lessonId, currentLesson.title, 1.0);
    }

    debugPrint('Completed lesson: ${currentLesson.title}');

    // Update in API
    await _apiService.completeLesson(lessonId);

    // ALWAYS unlock the next lesson in sequence
    _unlockNextLesson(currentLesson);
    
    // Add the current lesson to unlocked lessons if not already there
    unlockedLessons.add(lessonIndex);
    
    await _saveProgressToFirestore();

    // Check if we should trigger quiz after lesson completion (after every 5 lessons)
     if (context != null) {
      _checkAndTriggerQuiz(context, currentLesson);
    }

    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}

// Add a helper method for cases where context might not be available
Future<void> completeLessonWithoutContext(String lessonId) async {
  try {
    final lessonIndex = _lessons.indexWhere(
      (lesson) => lesson.id == lessonId,
    );
    if (lessonIndex == -1) {
      throw Exception('Lesson not found');
    }

    final currentLesson = _lessons[lessonIndex];

    // Mark current lesson as completed
    _lessons[lessonIndex] = _lessons[lessonIndex].copyWith(
      progress: 1.0,
      isCompleted: true,
    );

    debugPrint('Completed lesson: ${currentLesson.title}');

    // Update in API
    await _apiService.completeLesson(lessonId);

    // ALWAYS unlock the next lesson in sequence
    _unlockNextLesson(currentLesson);
    
    // Add the current lesson to unlocked lessons if not already there
    unlockedLessons.add(lessonIndex);
    
    await _saveProgressToFirestore();

    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}


  void _unlockNextLesson(Lesson completedLesson) {
  final allLessons = _lessons;

  // Get lessons for the current level only
  final currentLevelLessons = allLessons
      .where((lesson) => lesson.level == completedLesson.level)
      .toList()
    ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

  // Find the next lesson to unlock (next lesson number in sequence)
  final nextLessonNumber = completedLesson.lessonNumber + 1;
  Lesson? nextLesson;

  try {
    nextLesson = currentLevelLessons.firstWhere(
      (lesson) => lesson.lessonNumber == nextLessonNumber,
    );
  } catch (e) {
    debugPrint('No next lesson found with number $nextLessonNumber');
    nextLesson = null;
  }

  // If we found a real next lesson, unlock it
  if (nextLesson != null) {
    final nextLessonIndex = allLessons.indexWhere(
      (lesson) => lesson.id == nextLesson!.id,
    );
    if (nextLessonIndex != -1) {
      _lessons[nextLessonIndex] = _lessons[nextLessonIndex].copyWith(
        isUnlocked: true,
      );
      
      // Add to unlocked lessons set
      unlockedLessons.add(nextLessonIndex);
      
      debugPrint('Unlocked next lesson: ${nextLesson.title}');

      // Show success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lesson completed! ${nextLesson!.title} is now unlocked.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  } else {
    debugPrint('No next lesson found to unlock');

    // Check if we should unlock first lesson of next level
    _checkAndUnlockNextLevel(completedLesson);
  }
}

  void _checkAndUnlockNextLevel(Lesson completedLesson) {
    final allLessons = _lessons;
    final levels = ['beginner', 'intermediate', 'advanced'];
    final currentLevelIndex = levels.indexOf(completedLesson.level);

    // If this is not the last level and we completed the last lesson of current level
    if (currentLevelIndex != -1 && currentLevelIndex < levels.length - 1) {
      final nextLevel = levels[currentLevelIndex + 1];
      final nextLevelLessons =
          allLessons.where((lesson) => lesson.level == nextLevel).toList()
            ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      if (nextLevelLessons.isNotEmpty) {
        final firstNextLevelLesson = nextLevelLessons.first;
        final firstLessonIndex = allLessons.indexWhere(
          (lesson) => lesson.id == firstNextLevelLesson.id,
        );

        if (firstLessonIndex != -1) {
          _lessons[firstLessonIndex] = _lessons[firstLessonIndex].copyWith(
            isUnlocked: true,
          );
          debugPrint(
            'Unlocked first lesson of next level: ${firstNextLevelLesson.title}',
          );

          // Show level up message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Level up! ${firstNextLevelLesson.title} is now unlocked.',
                  ),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          });
        }
      }
    }
  }

  void _checkAndTriggerQuiz(BuildContext context, Lesson completedLesson) {
    final allLessons = _lessons;

    // Get lessons for the current level only
    final currentLevelLessons =
        allLessons
            .where((lesson) => lesson.level == completedLesson.level)
            .toList()
          ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    // Count completed lessons in current level
    final completedInLevel = currentLevelLessons
        .where((lesson) => lesson.isCompleted)
        .length;

    debugPrint(
      'Completed lessons in ${completedLesson.level} level: $completedInLevel',
    );

    // Trigger quiz after every 5 completed lessons in the same level
    if (completedInLevel > 0 && completedInLevel % 5 == 0) {
      final recentLessons = _getRecentLessons(
        currentLevelLessons,
        completedInLevel,
      );
      final quiz = _generateQuizForLessons(recentLessons, completedInLevel);

      // Use Navigator with the provided context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizPage(
              quiz: quiz,
              onQuizPassed: () {
                Navigator.pop(context);
                _unlockNextLessonAfterQuiz(completedLesson);

                _saveProgressToFirestore()
                    .then((_) {
                      debugPrint('Progress saved after quiz pass.');
                    })
                    .catchError((e) {
                      debugPrint('Error saving progress after quiz: $e');
                    });

                speak('Congratulations! Quiz passed. Next lesson unlocked.');
              },

              onQuizFailed: () {
                Navigator.pop(context);
                // Don't unlock next lesson, stay for review
                speak(
                  'Quiz not passed. Please review the recent lessons and try again.',
                );
                // Show failure message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Quiz failed. Please review lessons ${completedInLevel - 4} to $completedInLevel.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
        );
      });
    }
  }

  List<Lesson> _getRecentLessons(
    List<Lesson> levelLessons,
    int completedCount,
  ) {
    // Get the last 5 completed lessons
    final completedLessons = levelLessons
        .where((lesson) => lesson.isCompleted)
        .toList();

    // Return the most recent 5 lessons
    return completedLessons.length >= 5
        ? completedLessons.sublist(completedLessons.length - 5)
        : completedLessons;
  }

  Quiz _generateQuizForLessons(List<Lesson> recentLessons, int quizNumber) {
    List<QuizQuestion> questions = [];

    // Generate questions based on the content of recent lessons
    for (int i = 0; i < recentLessons.length; i++) {
      final lesson = recentLessons[i];
      final lessonNumber = lesson.lessonNumber;

      // Create questions based on lesson type and content
      switch (lesson.type) {
        case 'grammar':
          questions.add(_createGrammarQuestion(lesson, lessonNumber));
          break;
        case 'vocabulary':
          questions.add(_createVocabularyQuestion(lesson, lessonNumber));
          break;
        case 'pronunciation':
          questions.add(_createPronunciationQuestion(lesson, lessonNumber));
          break;
        case 'conversation':
          questions.add(_createConversationQuestion(lesson, lessonNumber));
          break;
        default:
          questions.add(_createGeneralQuestion(lesson, lessonNumber));
      }
    }

    // Ensure we have at least 3 questions
    while (questions.length < 3) {
      questions.add(_createGeneralQuestion(recentLessons.last, quizNumber));
    }

    // Take only 5 questions maximum
    if (questions.length > 5) {
      questions = questions.sublist(0, 5);
    }

    return Quiz(
      id: 'quiz_${recentLessons.first.level}_$quizNumber',
      title:
          'Progress Quiz - Lessons ${recentLessons.first.lessonNumber} to ${recentLessons.last.lessonNumber}',
      description:
          'Test your understanding of the recent ${recentLessons.length} lessons you completed.',
      questions: questions,
      passingScore: 70, // 70% to pass
      duration: 15,
    );
  }

  QuizQuestion _createGrammarQuestion(Lesson lesson, int lessonNumber) {
    return QuizQuestion(
      id: 'grammar_${lesson.id}',
      question: 'What was the main grammar focus in "${lesson.title}"?',
      options: [
        'Verb tenses and structures',
        'Vocabulary building',
        'Pronunciation practice',
        'Conversation skills',
        'All of the above',
      ],
      correctAnswer: _getGrammarCorrectAnswer(lesson),
      explanation: 'This lesson focused on ${_getGrammarExplanation(lesson)}',
    );
  }

  QuizQuestion _createVocabularyQuestion(Lesson lesson, int lessonNumber) {
    return QuizQuestion(
      id: 'vocab_${lesson.id}',
      question: 'Which vocabulary area was covered in "${lesson.title}"?',
      options: [
        'Business terminology',
        'Everyday expressions',
        'Technical terms',
        'Academic vocabulary',
        'Idioms and phrases',
      ],
      correctAnswer: _getVocabularyCorrectAnswer(lesson),
      explanation:
          'This lesson introduced vocabulary related to ${_getVocabularyExplanation(lesson)}',
    );
  }

  QuizQuestion _createPronunciationQuestion(Lesson lesson, int lessonNumber) {
    return QuizQuestion(
      id: 'pronunciation_${lesson.id}',
      question: 'What pronunciation aspect was practiced in "${lesson.title}"?',
      options: [
        'Vowel sounds',
        'Consonant sounds',
        'Word stress',
        'Sentence intonation',
        'All of the above',
      ],
      correctAnswer: _getPronunciationCorrectAnswer(lesson),
      explanation:
          'This lesson focused on ${_getPronunciationExplanation(lesson)}',
    );
  }

  QuizQuestion _createConversationQuestion(Lesson lesson, int lessonNumber) {
    return QuizQuestion(
      id: 'conversation_${lesson.id}',
      question: 'What conversation skill was developed in "${lesson.title}"?',
      options: [
        'Formal greetings',
        'Small talk',
        'Professional communication',
        'Social interactions',
        'All of the above',
      ],
      correctAnswer: _getConversationCorrectAnswer(lesson),
      explanation:
          'This lesson helped with ${_getConversationExplanation(lesson)}',
    );
  }

  QuizQuestion _createGeneralQuestion(Lesson lesson, int lessonNumber) {
    return QuizQuestion(
      id: 'general_${lesson.id}',
      question: 'What was the primary learning objective of "${lesson.title}"?',
      options: [
        'Grammar mastery',
        'Vocabulary expansion',
        'Speaking confidence',
        'Listening comprehension',
        'Overall language improvement',
      ],
      correctAnswer: 'Overall language improvement',
      explanation:
          'This lesson aimed to improve your overall English skills with focus on ${lesson.type}',
    );
  }

  // Helper methods for correct answers based on lesson content
  String _getGrammarCorrectAnswer(Lesson lesson) {
    if (lesson.title.toLowerCase().contains('tense')) {
      return 'Verb tenses and structures';
    } else if (lesson.title.toLowerCase().contains('verb')) {
      return 'Verb tenses and structures';
    }
    return 'All of the above';
  }

  String _getVocabularyCorrectAnswer(Lesson lesson) {
    if (lesson.title.toLowerCase().contains('idiom')) {
      return 'Idioms and phrases';
    } else if (lesson.title.toLowerCase().contains('business')) {
      return 'Business terminology';
    }
    return 'Everyday expressions';
  }

  String _getPronunciationCorrectAnswer(Lesson lesson) {
    if (lesson.title.toLowerCase().contains('vowel')) {
      return 'Vowel sounds';
    } else if (lesson.title.toLowerCase().contains('consonant')) {
      return 'Consonant sounds';
    }
    return 'All of the above';
  }

  String _getConversationCorrectAnswer(Lesson lesson) {
    if (lesson.title.toLowerCase().contains('greeting')) {
      return 'Formal greetings';
    } else if (lesson.title.toLowerCase().contains('professional')) {
      return 'Professional communication';
    }
    return 'All of the above';
  }

  // Helper methods for explanations
  String _getGrammarExplanation(Lesson lesson) {
    return lesson.description.isNotEmpty
        ? lesson.description
        : 'grammar structures and rules';
  }

  String _getVocabularyExplanation(Lesson lesson) {
    return lesson.description.isNotEmpty
        ? lesson.description
        : 'new words and expressions';
  }

  String _getPronunciationExplanation(Lesson lesson) {
    return lesson.description.isNotEmpty
        ? lesson.description
        : 'improving your speaking clarity';
  }

  String _getConversationExplanation(Lesson lesson) {
    return lesson.description.isNotEmpty
        ? lesson.description
        : 'developing your communication skills';
  }

  void _unlockNextLessonAfterQuiz(Lesson lastCompletedLesson) {
    final allLessons = _lessons;

    // Get lessons for the current level only
    final currentLevelLessons =
        allLessons
            .where((lesson) => lesson.level == lastCompletedLesson.level)
            .toList()
          ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    // Find the specific next lesson (6th lesson after quiz)
    final nextLessonNumber = lastCompletedLesson.lessonNumber + 1;
    Lesson? nextLesson;

    try {
      nextLesson = currentLevelLessons.firstWhere(
        (lesson) => lesson.lessonNumber == nextLessonNumber,
      );
    } catch (e) {
      debugPrint('No next lesson found with number $nextLessonNumber');
      nextLesson = null;
    }

    // If we found a real next lesson, unlock it
    if (nextLesson != null) {
      final nextLessonIndex = allLessons.indexWhere(
        (lesson) => lesson.id == nextLesson!.id,
      );
      if (nextLessonIndex != -1 && !_lessons[nextLessonIndex].isUnlocked) {
        _lessons[nextLessonIndex] = _lessons[nextLessonIndex].copyWith(
          isUnlocked: true,
        );
        debugPrint('Unlocked next lesson after quiz: ${nextLesson.title}');

        // Show success message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Quiz passed! ${nextLesson!.title} is now unlocked.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    }
  }

  // In the LessonsBackend class, update this method:

Future<void> updateLessonProgress(String lessonId, double progress, {BuildContext? context}) async {
  try {
    await _apiService.submitLessonProgress(lessonId, progress);

    final lessonIndex = _lessons.indexWhere(
      (lesson) => lesson.id == lessonId,
    );
    if (lessonIndex != -1) {
      _lessons[lessonIndex] = _lessons[lessonIndex].copyWith(
        progress: progress,
      );

        if (context != null) {
        final currentLesson = _lessons[lessonIndex];
        final appState = Provider.of<AppStateManager>(context, listen: false);
        appState.setLastAccessedLesson(lessonId, currentLesson.title, progress);
      }

      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

  Future<void> submitExerciseResult(
    String lessonId,
    String exerciseId,
    bool isCorrect,
    double score,
  ) async {
    try {
      await _apiService.submitExerciseProgress(
        lessonId,
        exerciseId,
        isCorrect,
        score,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting exercise: $e');
    }
  }

  Future<Map<String, dynamic>> submitExerciseAttempt(
    String lessonId,
    String exerciseId,
    String userAnswer,
  ) async {
    try {
      final result = await _apiService.submitExerciseAttempt(
        lessonId,
        exerciseId,
        userAnswer,
      );
      return {
        'is_correct': result.isCorrect,
        'correct_answer': result.correctAnswer,
        'explanation': result.explanation,
        'points_earned': result.pointsEarned,
        'streak': result.streak,
      };
    } catch (e) {
      debugPrint('Error submitting exercise attempt: $e');
      return {
        'is_correct': false,
        'correct_answer': '',
        'explanation': 'Error submitting answer: $e',
        'points_earned': 0,
        'streak': 0,
      };
    }
  }

  void checkAndTriggerQuiz(BuildContext context, Lesson completedLesson) {
    _checkAndTriggerQuiz(context, completedLesson);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
