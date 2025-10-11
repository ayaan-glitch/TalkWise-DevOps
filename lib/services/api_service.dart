// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_model.dart';
import '../models/progress_model.dart';

class ApiService {
  // Use a flag to switch between real and mock data
  static const bool useMockData = true;
  static const String _baseUrl = 'https://your-api-domain.com/api/v1';
  static const Duration _timeout = Duration(seconds: 30);
  
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  // Headers for API requests
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Get all lessons with user progress
  Future<List<Lesson>> getLessons() async {
    if (useMockData) {
      // Return mock data directly
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      return _getMockLessons();
    } else {
      // Real API call
      try {
        final response = await client
            .get(Uri.parse('$_baseUrl/lessons'), headers: _headers)
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return _parseLessonsFromJson(data);
        } else {
          throw ApiException(
            'Failed to load lessons: ${response.statusCode}',
            response.statusCode,
          );
        }
      } on http.ClientException catch (e) {
        throw ApiException('Network error: $e', 0);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Unexpected error: $e', 500);
      }
    }
  }

  // Get lessons by level
  Future<List<Lesson>> getLessonsByLevel(String level) async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 500));
      final allLessons = _getMockLessons();
      return allLessons.where((lesson) => lesson.level == level).toList();
    } else {
      try {
        final response = await client
            .get(Uri.parse('$_baseUrl/lessons?level=$level'), headers: _headers)
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return _parseLessonsFromJson(data);
        } else {
          throw ApiException(
            'Failed to load $level lessons: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to load lessons: $e', 0);
      }
    }
  }

  // Complete a lesson
  Future<void> completeLesson(String lessonId) async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 300));
      // Simulate successful completion
      return;
    } else {
      try {
        final response = await client
            .post(
              Uri.parse('$_baseUrl/lessons/$lessonId/complete'),
              headers: _headers,
              body: json.encode({
                'completed_at': DateTime.now().toIso8601String(),
                'score': 100,
              }),
            )
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw ApiException(
            'Failed to complete lesson: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to complete lesson: $e', 0);
      }
    }
  }

  // Update lesson progress
  Future<void> submitLessonProgress(String lessonId, double progress) async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 200));
      // Simulate successful progress update
      return;
    } else {
      try {
        final response = await client
            .put(
              Uri.parse('$_baseUrl/lessons/$lessonId/progress'),
              headers: _headers,
              body: json.encode({
                'progress': progress,
                'updated_at': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode != 200) {
          throw ApiException(
            'Failed to update progress: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to update progress: $e', 0);
      }
    }
  }

  // Get user progress and statistics
  Future<UserProgress> getUserProgress() async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 400));
      return UserProgress(
        userId: 'mock_user_123',
        currentLevel: 'beginner',
        totalLessons: _getMockLessons().length,
        completedLessons: 2,
        dayStreak: 3,
        totalXp: 150,
        currentLevelXp: 75,
        nextLevelXp: 100,
        statistics: {
          'grammar_correct': 15,
          'vocabulary_correct': 12,
          'pronunciation_correct': 8,
          'conversation_correct': 10,
          'total_attempts': 45,
          'accuracy_rate': 0.78,
        },
        lastActive: DateTime.now().subtract(Duration(days: 1)),
      );
    } else {
      try {
        final response = await client
            .get(Uri.parse('$_baseUrl/user/progress'), headers: _headers)
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return UserProgress.fromJson(data);
        } else {
          throw ApiException(
            'Failed to load progress: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to load progress: $e', 0);
      }
    }
  }

  // Submit exercise attempt
  Future<ExerciseResult> submitExerciseAttempt(
    String lessonId,
    String exerciseId,
    String userAnswer,
  ) async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 300));
      // Simple mock implementation - check if answer matches
      final lessons = _getMockLessons();
      final lesson = lessons.firstWhere((l) => l.id == lessonId);
      final exercise = lesson.exercises.firstWhere((e) => e.id == exerciseId);
      
      final isCorrect = userAnswer.toLowerCase() == exercise.correctAnswer.toLowerCase();
      
      return ExerciseResult(
        isCorrect: isCorrect,
        correctAnswer: exercise.correctAnswer,
        explanation: isCorrect ? 'Great job!' : exercise.explanation,
        pointsEarned: isCorrect ? 10 : 0,
        streak: isCorrect ? 1 : 0,
      );
    } else {
      try {
        final response = await client
            .post(
              Uri.parse('$_baseUrl/lessons/$lessonId/exercises/$exerciseId/attempt'),
              headers: _headers,
              body: json.encode({
                'user_answer': userAnswer,
                'attempted_at': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return ExerciseResult.fromJson(data);
        } else {
          throw ApiException(
            'Failed to submit exercise: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to submit exercise: $e', 0);
      }
    }
  }

  // Submit exercise progress
  Future<void> submitExerciseProgress(
    String lessonId,
    String exerciseId,
    bool completed,
    double score,
  ) async {
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 200));
      // Simulate successful progress update
      return;
    } else {
      try {
        final response = await client
            .post(
              Uri.parse('$_baseUrl/lessons/$lessonId/exercises/$exerciseId/progress'),
              headers: _headers,
              body: json.encode({
                'completed': completed,
                'score': score,
                'updated_at': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(_timeout, onTimeout: () {
          throw ApiException('Request timeout', 408);
        });

        if (response.statusCode != 200) {
          throw ApiException(
            'Failed to update exercise progress: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to update exercise progress: $e', 0);
      }
    }
  }

  // Mock lessons data 
  List<Lesson> _getMockLessons() {
    return [
      // ========== BEGINNER LEVEL ==========
      
      // 🔹 BEGINNER - TENSES
      Lesson(
        id: 'beginner_tenses_1',
        title: 'Present Simple Tense',
        description: 'Learn to talk about daily routines and general truths',
        level: 'beginner',
        lessonNumber: 1,
        type: 'grammar',
        duration: 25,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Basic Tenses',
        category: 'tenses',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Present Simple Usage',
            content: 'Use present simple for habits, routines, and general truths.',
            type: 'theory',
            examples: ['I work every day.', 'She studies English.', 'The sun rises in the east.'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which sentence uses present simple?',
            options: ['I am working now', 'I work every day', 'I worked yesterday', 'I will work tomorrow'],
            correctAnswer: 'I work every day',
            explanation: 'Present simple is used for routines and habits.',
          ),
        ],
      ),

      Lesson(
        id: 'beginner_tenses_2',
        title: 'Present Continuous Tense',
        description: 'Learn to talk about actions happening now',
        level: 'beginner',
        lessonNumber: 2,
        type: 'grammar',
        duration: 20,
        isUnlocked: false,
        progress: 0.0,
        unit: 'Unit 1: Basic Tenses',
        category: 'tenses',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Present Continuous Usage',
            content: 'Use present continuous for actions happening at the moment of speaking.',
            type: 'theory',
            examples: ['I am studying now.', 'She is watching TV.', 'They are playing football.'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which sentence is correct for something happening now?',
            options: ['I study English', 'I am studying English', 'I studied English', 'I will study English'],
            correctAnswer: 'I am studying English',
            explanation: 'Present continuous describes current actions.',
          ),
        ],
      ),

      // 🔹 BEGINNER - IDIOMS
      Lesson(
        id: 'beginner_idioms_1',
        title: 'Basic Everyday Idioms',
        description: 'Learn common idioms used in daily conversations',
        level: 'beginner',
        lessonNumber: 1,
        type: 'vocabulary',
        duration: 15,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Common Expressions',
        category: 'idioms',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Simple Idioms',
            content: 'Idioms that are easy to understand and frequently used.',
            type: 'theory',
            examples: ['Break the ice', 'Piece of cake', 'Cost an arm and a leg', 'Hit the books'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'What does "piece of cake" mean?',
            options: ['Something delicious', 'Something very easy', 'A dessert', 'A difficult task'],
            correctAnswer: 'Something very easy',
            explanation: '"Piece of cake" means something is very easy to do.',
          ),
        ],
      ),

      // 🔹 BEGINNER - VERBS
      Lesson(
        id: 'beginner_verbs_1',
        title: 'Action Verbs',
        description: 'Learn common verbs for daily activities',
        level: 'beginner',
        lessonNumber: 1,
        type: 'vocabulary',
        duration: 20,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Essential Verbs',
        category: 'verbs',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Daily Routine Verbs',
            content: 'Verbs that describe everyday activities and routines.',
            type: 'theory',
            examples: ['wake up', 'eat breakfast', 'go to work', 'study', 'exercise', 'sleep'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which verb means "to leave your bed in the morning"?',
            options: ['sleep', 'eat', 'wake up', 'exercise'],
            correctAnswer: 'wake up',
            explanation: 'To wake up means to stop sleeping and get out of bed.',
          ),
        ],
      ),

      // 🔹 BEGINNER - PHRASES
      Lesson(
        id: 'beginner_phrases_1',
        title: 'Greetings and Introductions',
        description: 'Essential phrases for meeting people',
        level: 'beginner',
        lessonNumber: 1,
        type: 'conversation',
        duration: 20,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Social English',
        category: 'phrases',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Basic Greetings',
            content: 'Learn how to greet people and introduce yourself properly.',
            type: 'theory',
            examples: ['Hello! How are you?', 'Nice to meet you!', 'My name is...', 'What do you do?'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'What is a formal way to greet someone in the morning?',
            options: ['Hey!', 'Hi!', 'Good morning!', 'What\'s up?'],
            correctAnswer: 'Good morning!',
            explanation: '"Good morning" is formal and appropriate for professional settings.',
          ),
        ],
      ),

      // 🔹 BEGINNER - PRONUNCIATION
      Lesson(
        id: 'beginner_pronunciation_1',
        title: 'Basic Vowel Sounds',
        description: 'Master English vowel pronunciation',
        level: 'beginner',
        lessonNumber: 1,
        type: 'pronunciation',
        duration: 25,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Sound Foundations',
        category: 'pronunciation',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Short Vowel Sounds',
            content: 'Learn the five basic short vowel sounds in English.',
            type: 'theory',
            examples: ['a - cat, man', 'e - bed, pen', 'i - sit, big', 'o - hot, dog', 'u - sun, bus'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which word has a different vowel sound?',
            options: ['cat', 'man', 'cake', 'hat'],
            correctAnswer: 'cake',
            explanation: '"Cake" has a long A sound, while the others have short A sounds.',
          ),
        ],
      ),

      // ========== INTERMEDIATE LEVEL ==========
      
      // 🔸 INTERMEDIATE - TENSES
      Lesson(
        id: 'intermediate_tenses_1',
        title: 'Present Perfect Tense',
        description: 'Learn to talk about experiences and recent events',
        level: 'intermediate',
        lessonNumber: 1,
        type: 'grammar',
        duration: 30,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Complex Tenses',
        category: 'tenses',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Present Perfect Usage',
            content: 'Learn when to use present perfect for experiences and unfinished time.',
            type: 'theory',
            examples: ['I have visited Paris.', 'She has lived here for 5 years.', 'We have just finished.'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which sentence uses present perfect correctly?',
            options: ['I have seen that movie yesterday', 'I saw that movie yesterday', 'I have seen that movie', 'I see that movie'],
            correctAnswer: 'I have seen that movie',
            explanation: 'Present perfect is used for experiences without specific time.',
          ),
        ],
      ),

      // 🔸 INTERMEDIATE - IDIOMS
      Lesson(
        id: 'intermediate_idioms_1',
        title: 'Business Idioms',
        description: 'Idioms commonly used in professional settings',
        level: 'intermediate',
        lessonNumber: 1,
        type: 'vocabulary',
        duration: 25,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Professional Language',
        category: 'idioms',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Workplace Idioms',
            content: 'Idioms that are frequently used in business and office environments.',
            type: 'theory',
            examples: ['Think outside the box', 'Get the ball rolling', 'Touch base', 'Back to the drawing board'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'What does "think outside the box" mean?',
            options: ['To be creative', 'To work late', 'To follow rules', 'To organize things'],
            correctAnswer: 'To be creative',
            explanation: 'It means to think creatively, beyond normal boundaries.',
          ),
        ],
      ),

      // 🔸 INTERMEDIATE - VERBS
      Lesson(
        id: 'intermediate_verbs_1',
        title: 'Phrasal Verbs',
        description: 'Master common phrasal verbs in English',
        level: 'intermediate',
        lessonNumber: 1,
        type: 'grammar',
        duration: 35,
        isUnlocked: false,
        progress: 0.0,
        unit: 'Unit 1: Verb Patterns',
        category: 'verbs',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Common Phrasal Verbs',
            content: 'Learn phrasal verbs that combine verbs with prepositions or adverbs.',
            type: 'theory',
            examples: ['get up', 'look after', 'turn down', 'give up', 'break down'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'What does "give up" mean?',
            options: ['To celebrate', 'To stop trying', 'To stand up', 'To help someone'],
            correctAnswer: 'To stop trying',
            explanation: '"Give up" means to quit or stop trying to do something.',
          ),
        ],
      ),

      // 🔸 INTERMEDIATE - PHRASES
      Lesson(
        id: 'intermediate_phrases_1',
        title: 'Social Conversation Phrases',
        description: 'Phrases for natural social interactions',
        level: 'intermediate',
        lessonNumber: 1,
        type: 'conversation',
        duration: 20,
        isUnlocked: false,
        progress: 0.0,
        unit: 'Unit 1: Social Skills',
        category: 'phrases',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Making Small Talk',
            content: 'Learn phrases for casual conversations in social situations.',
            type: 'theory',
            examples: ['How have you been?', 'What have you been up to?', 'That reminds me of...', 'Speaking of which...'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which phrase is best for changing the topic naturally?',
            options: ['Anyway,...', 'That\'s wrong', 'Be quiet', 'I don\'t care'],
            correctAnswer: 'Anyway,...',
            explanation: '"Anyway" is a natural way to transition to a new topic.',
          ),
        ],
      ),

      // ========== ADVANCED LEVEL ==========
      
      // 🔷 ADVANCED - TENSES
      Lesson(
        id: 'advanced_tenses_1',
        title: 'Advanced Conditionals',
        description: 'Master complex conditional sentences',
        level: 'advanced',
        lessonNumber: 1,
        type: 'grammar',
        duration: 40,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Advanced Grammar',
        category: 'tenses',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Mixed Conditionals',
            content: 'Learn to combine different conditional forms for complex situations.',
            type: 'theory',
            examples: ['If I had studied harder, I would have a better job now.', 'If I were you, I would have taken that opportunity.'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which sentence is a mixed conditional?',
            options: ['If it rains, I will stay home', 'If I had money, I would buy a car', 'If I had studied, I would have passed', 'If I had known, I would be there now'],
            correctAnswer: 'If I had known, I would be there now',
            explanation: 'This mixes past perfect in the if-clause with present conditional in the main clause.',
          ),
        ],
      ),

      // 🔷 ADVANCED - IDIOMS
      Lesson(
        id: 'advanced_idioms_1',
        title: 'Advanced Cultural Idioms',
        description: 'Complex idioms and their cultural origins',
        level: 'advanced',
        lessonNumber: 1,
        type: 'vocabulary',
        duration: 30,
        isUnlocked: true,
        progress: 0.0,
        unit: 'Unit 1: Cultural English',
        category: 'idioms',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Literary and Historical Idioms',
            content: 'Idioms that come from literature, history, and complex cultural references.',
            type: 'theory',
            examples: ['A wolf in sheep\'s clothing', 'The ball is in your court', 'Bite the bullet', 'Cut to the chase'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'What does "a wolf in sheep\'s clothing" mean?',
            options: ['A friendly person', 'Someone who appears friendly but is dangerous', 'A farmer', 'An animal lover'],
            correctAnswer: 'Someone who appears friendly but is dangerous',
            explanation: 'It describes someone who hides their true harmful intentions behind a friendly appearance.',
          ),
        ],
      ),

      // 🔷 ADVANCED - VERBS
      Lesson(
        id: 'advanced_verbs_1',
        title: 'Reporting Verbs',
        description: 'Master verbs for reported speech and academic writing',
        level: 'advanced',
        lessonNumber: 1,
        type: 'grammar',
        duration: 35,
        isUnlocked: false,
        progress: 0.0,
        unit: 'Unit 1: Academic English',
        category: 'verbs',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Verbs for Reported Speech',
            content: 'Learn sophisticated verbs for reporting what others have said or written.',
            type: 'theory',
            examples: ['The researcher claimed that...', 'The author argued that...', 'The study demonstrated that...', 'The evidence suggests that...'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which reporting verb shows strong evidence?',
            options: ['suggested', 'claimed', 'demonstrated', 'thought'],
            correctAnswer: 'demonstrated',
            explanation: '"Demonstrated" implies strong evidence and proof.',
          ),
        ],
      ),

      // 🔷 ADVANCED - PHRASES
      Lesson(
        id: 'advanced_phrases_1',
        title: 'Academic Writing Phrases',
        description: 'Formal phrases for essays and research papers',
        level: 'advanced',
        lessonNumber: 1,
        type: 'writing',
        duration: 45,
        isUnlocked: false,
        progress: 0.0,
        unit: 'Unit 1: Academic Writing',
        category: 'phrases',
        sections: [
          LessonSection(
            id: 'sec1',
            title: 'Academic Language',
            content: 'Learn formal phrases and expressions used in academic writing.',
            type: 'theory',
            examples: ['It is widely acknowledged that...', 'There is considerable evidence that...', 'This essay will argue that...', 'In conclusion, it can be stated that...'],
          ),
        ],
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'multiple_choice',
            question: 'Which phrase is most appropriate for academic writing?',
            options: ['Everyone knows that...', 'It is commonly accepted that...', 'I think that...', 'This is totally true that...'],
            correctAnswer: 'It is commonly accepted that...',
            explanation: 'This is formal and objective, suitable for academic writing.',
          ),
        ],
      ),

      // Add more lessons to fill each category...
    ];
  }

  // Parse lessons from JSON response
  List<Lesson> _parseLessonsFromJson(Map<String, dynamic> data) {
    final List<dynamic> lessonsJson = data['lessons'] ?? data['data'] ?? [];
    return lessonsJson.map<Lesson>((json) => Lesson.fromJson(json)).toList();
  }

  // Close the HTTP client when done
  void dispose() {
    client.close();
  }
}

// API Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// Exercise result model
class ExerciseResult {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final int pointsEarned;
  final int streak;

  ExerciseResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.pointsEarned,
    required this.streak,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      isCorrect: json['is_correct'] ?? false,
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
      pointsEarned: json['points_earned'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }
}