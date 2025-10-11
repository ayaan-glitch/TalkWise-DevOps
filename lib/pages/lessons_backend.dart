import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/lesson_model.dart';
import '../services/api_service.dart';

class LessonsBackend with ChangeNotifier {
  static final LessonsBackend _instance = LessonsBackend._internal();
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
  double _speechRate = 0.5;
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
        notifyListeners();
      });
      
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Initialize Speech Recognition
  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
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
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  // Speak text using TTS
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    notifyListeners();
  }

  // Set speech volume
  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume;
    await _tts.setVolume(volume);
    notifyListeners();
  }

  // Listen for voice commands
  Future<void> listenForCommand(Function(String) onCommand) async {
    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    try {
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
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
      );
    } catch (e) {
      debugPrint('Error listening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping listening: $e');
    }
  }

  // Get lessons by level
  List<Lesson> getLessonsByLevel(String level) {
    return _lessons.where((lesson) => lesson.level == level).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  // Load lessons from API
  Future<void> loadLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lessons = await _apiService.getLessons();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading lessons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete a lesson and unlock the next one
  Future<void> completeLesson(String lessonId) async {
    try {
      await _apiService.completeLesson(lessonId);

      final lessonIndex = _lessons.indexWhere((lesson) => lesson.id == lessonId);
      if (lessonIndex != -1) {
        _lessons[lessonIndex] = _lessons[lessonIndex].copyWith(
          progress: 1.0,
        );

        // Unlock next lesson if exists
        final nextLessonIndex = lessonIndex + 1;
        if (nextLessonIndex < _lessons.length) {
          _lessons[nextLessonIndex] = _lessons[nextLessonIndex].copyWith(
            isUnlocked: true,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update lesson progress
  Future<void> updateLessonProgress(String lessonId, double progress) async {
    try {
      await _apiService.submitLessonProgress(lessonId, progress);

      final lessonIndex = _lessons.indexWhere((lesson) => lesson.id == lessonId);
      if (lessonIndex != -1) {
        _lessons[lessonIndex] = _lessons[lessonIndex].copyWith(progress: progress);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Submit exercise result
  Future<void> submitExerciseResult(
    String lessonId,
    String exerciseId,
    bool isCorrect,
    double score,
  ) async {
    try {
      await _apiService.submitExerciseProgress(lessonId, exerciseId, isCorrect, score);
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting exercise: $e');
    }
  }

  // Submit exercise attempt
  Future<ExerciseResult> submitExerciseAttempt(
    String lessonId,
    String exerciseId,
    String userAnswer,
  ) async {
    try {
      return await _apiService.submitExerciseAttempt(lessonId, exerciseId, userAnswer);
    } catch (e) {
      debugPrint('Error submitting exercise attempt: $e');
      // Return a default error result
      return ExerciseResult(
        isCorrect: false,
        correctAnswer: '',
        explanation: 'Error submitting answer: $e',
        pointsEarned: 0,
        streak: 0,
      );
    }
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