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

// In api_service.dart - Replace the _getMockLessons() method with this:

List<Lesson> _getMockLessons() {
  return [
    // ========== BEGINNER LEVEL (20 Lessons) ==========
    
    // 🔹 BEGINNER - TENSES (4 lessons)
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

    Lesson(
      id: 'beginner_tenses_3',
      title: 'Past Simple Tense',
      description: 'Learn to talk about completed actions in the past',
      level: 'beginner',
      lessonNumber: 3,
      type: 'grammar',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Basic Tenses',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Past Simple Usage',
          content: 'Use past simple for completed actions at specific times in the past.',
          type: 'theory',
          examples: ['I worked yesterday.', 'She studied last night.', 'They played football last week.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses past simple correctly?',
          options: ['I work yesterday', 'I worked yesterday', 'I am working yesterday', 'I will work yesterday'],
          correctAnswer: 'I worked yesterday',
          explanation: 'Past simple uses the past form of the verb for completed actions.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_tenses_4',
      title: 'Future with "Will"',
      description: 'Learn to make predictions and spontaneous decisions',
      level: 'beginner',
      lessonNumber: 4,
      type: 'grammar',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Basic Tenses',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Future Simple Usage',
          content: 'Use "will" for predictions, promises, and spontaneous decisions.',
          type: 'theory',
          examples: ['It will rain tomorrow.', 'I will help you.', 'She will call you later.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses "will" correctly for a prediction?',
          options: ['I will eating dinner', 'It will rain tomorrow', 'She will studies English', 'They will playing soccer'],
          correctAnswer: 'It will rain tomorrow',
          explanation: '"Will" is followed by the base form of the verb for future predictions.',
        ),
      ],
    ),

    // 🔹 BEGINNER - IDIOMS (4 lessons)
    Lesson(
      id: 'beginner_idioms_1',
      title: 'Basic Everyday Idioms',
      description: 'Learn common idioms used in daily conversations',
      level: 'beginner',
      lessonNumber: 5,
      type: 'vocabulary',
      duration: 15,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 2: Common Expressions',
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

    Lesson(
      id: 'beginner_idioms_2',
      title: 'Food and Drink Idioms',
      description: 'Idioms related to food and beverages',
      level: 'beginner',
      lessonNumber: 6,
      type: 'vocabulary',
      duration: 20,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Common Expressions',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Food-related Idioms',
          content: 'Common idioms that use food and drink vocabulary.',
          type: 'theory',
          examples: ['Spill the beans', 'The best thing since sliced bread', 'Bring home the bacon', 'In a nutshell'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "spill the beans" mean?',
          options: ['To cook dinner', 'To reveal a secret', 'To make a mess', 'To eat quickly'],
          correctAnswer: 'To reveal a secret',
          explanation: '"Spill the beans" means to tell secret information.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_idioms_3',
      title: 'Animal Idioms',
      description: 'Common idioms featuring animals',
      level: 'beginner',
      lessonNumber: 7,
      type: 'vocabulary',
      duration: 18,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Common Expressions',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Animal Expressions',
          content: 'Fun idioms that use animals to describe situations.',
          type: 'theory',
          examples: ['Busy as a bee', 'Curious as a cat', 'Strong as an ox', 'Sly as a fox'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "busy as a bee" mean?',
          options: ['To be lazy', 'To be very busy', 'To make honey', 'To fly around'],
          correctAnswer: 'To be very busy',
          explanation: 'This idiom means someone is very active and working hard.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_idioms_4',
      title: 'Weather Idioms',
      description: 'Idioms related to weather conditions',
      level: 'beginner',
      lessonNumber: 8,
      type: 'vocabulary',
      duration: 22,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Common Expressions',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Weather Expressions',
          content: 'Idioms that use weather to describe emotions and situations.',
          type: 'theory',
          examples: ['Under the weather', 'Break the ice', 'Save for a rainy day', 'Storm in a teacup'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "under the weather" mean?',
          options: ['Feeling happy', 'Feeling sick', 'Feeling hot', 'Feeling cold'],
          correctAnswer: 'Feeling sick',
          explanation: '"Under the weather" means feeling ill or unwell.',
        ),
      ],
    ),

    // 🔹 BEGINNER - VERBS (4 lessons)
    Lesson(
      id: 'beginner_verbs_1',
      title: 'Action Verbs',
      description: 'Learn common verbs for daily activities',
      level: 'beginner',
      lessonNumber: 9,
      type: 'vocabulary',
      duration: 20,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 3: Essential Verbs',
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

    Lesson(
      id: 'beginner_verbs_2',
      title: 'Irregular Verbs - Group 1',
      description: 'Master the most common irregular verbs',
      level: 'beginner',
      lessonNumber: 10,
      type: 'grammar',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Essential Verbs',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Basic Irregular Verbs',
          content: 'Learn the most frequently used irregular verbs in English.',
          type: 'theory',
          examples: ['go - went - gone', 'see - saw - seen', 'eat - ate - eaten', 'take - took - taken'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What is the past tense of "go"?',
          options: ['goed', 'went', 'gone', 'going'],
          correctAnswer: 'went',
          explanation: 'The past tense of "go" is "went" - this is an irregular verb.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_verbs_3',
      title: 'Modal Verbs - Can and Could',
      description: 'Learn to express ability and possibility',
      level: 'beginner',
      lessonNumber: 11,
      type: 'grammar',
      duration: 28,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Essential Verbs',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Can and Could Usage',
          content: 'Learn to use "can" for present ability and "could" for past ability or polite requests.',
          type: 'theory',
          examples: ['I can swim.', 'She can speak English.', 'Could you help me?', 'I could run fast when I was young.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses "can" correctly?',
          options: ['I can to swim', 'I can swimming', 'I can swim', 'I can swam'],
          correctAnswer: 'I can swim',
          explanation: '"Can" is followed by the base form of the verb without "to".',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_verbs_4',
      title: 'Verb "To Be"',
      description: 'Master the most important verb in English',
      level: 'beginner',
      lessonNumber: 12,
      type: 'grammar',
      duration: 22,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Essential Verbs',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Forms of "To Be"',
          content: 'Learn all forms of the verb "to be" in present tense.',
          type: 'theory',
          examples: ['I am a student.', 'You are my friend.', 'He is a teacher.', 'We are happy.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which is correct?',
          options: ['I is happy', 'I am happy', 'I are happy', 'I be happy'],
          correctAnswer: 'I am happy',
          explanation: 'The correct form is "I am" for the first person singular.',
        ),
      ],
    ),

    // 🔹 BEGINNER - PHRASES (4 lessons)
    Lesson(
      id: 'beginner_phrases_1',
      title: 'Greetings and Introductions',
      description: 'Essential phrases for meeting people',
      level: 'beginner',
      lessonNumber: 13,
      type: 'conversation',
      duration: 20,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 4: Social English',
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

    Lesson(
      id: 'beginner_phrases_2',
      title: 'Asking for Directions',
      description: 'Essential phrases for navigating and finding places',
      level: 'beginner',
      lessonNumber: 14,
      type: 'conversation',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social English',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Direction Phrases',
          content: 'Learn how to ask for and understand directions.',
          type: 'theory',
          examples: ['Excuse me, where is...?', 'How do I get to...?', 'Is it far from here?', 'Turn left/right'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase is most polite for asking directions?',
          options: ['Where is it?', 'Tell me where...', 'Excuse me, could you tell me where...?', 'I need to find...'],
          correctAnswer: 'Excuse me, could you tell me where...?',
          explanation: 'This is the most polite and formal way to ask for directions.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_phrases_3',
      title: 'Shopping Phrases',
      description: 'Essential phrases for shopping and transactions',
      level: 'beginner',
      lessonNumber: 15,
      type: 'conversation',
      duration: 23,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social English',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Shopping Language',
          content: 'Learn phrases for shopping, asking about prices, and making purchases.',
          type: 'theory',
          examples: ['How much is this?', 'Do you have this in size medium?', 'I\'ll take it.', 'Can I pay by card?'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What is a polite way to ask about price?',
          options: ['How much?', 'What\'s the cost?', 'How much does this cost?', 'Tell me the price'],
          correctAnswer: 'How much does this cost?',
          explanation: 'This is a complete and polite way to ask about price.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_phrases_4',
      title: 'Restaurant Phrases',
      description: 'Essential phrases for dining out',
      level: 'beginner',
      lessonNumber: 16,
      type: 'conversation',
      duration: 26,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social English',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Restaurant Language',
          content: 'Learn phrases for ordering food, asking about the menu, and paying the bill.',
          type: 'theory',
          examples: ['I\'d like to order...', 'What do you recommend?', 'Could I have the bill?', 'Is service included?'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What is a polite way to ask for the menu?',
          options: ['Give me the menu', 'Menu please', 'Could I see the menu?', 'I want the menu'],
          correctAnswer: 'Could I see the menu?',
          explanation: 'This is a polite and formal way to request the menu.',
        ),
      ],
    ),

    // 🔹 BEGINNER - PRONUNCIATION (4 lessons)
    Lesson(
      id: 'beginner_pronunciation_1',
      title: 'Basic Vowel Sounds',
      description: 'Master English vowel pronunciation',
      level: 'beginner',
      lessonNumber: 17,
      type: 'pronunciation',
      duration: 25,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 5: Sound Foundations',
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

    Lesson(
      id: 'beginner_pronunciation_2',
      title: 'Consonant Sounds - P, B, T, D',
      description: 'Master basic consonant pronunciation',
      level: 'beginner',
      lessonNumber: 18,
      type: 'pronunciation',
      duration: 20,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Sound Foundations',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Plosive Consonants',
          content: 'Learn to pronounce P, B, T, and D sounds clearly.',
          type: 'theory',
          examples: ['p - pen, apple', 'b - boy, table', 't - time, water', 'd - dog, ladder'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which word starts with a "b" sound?',
          options: ['pen', 'boy', 'time', 'dog'],
          correctAnswer: 'boy',
          explanation: '"Boy" starts with the voiced bilabial plosive /b/ sound.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_pronunciation_3',
      title: 'Word Stress Patterns',
      description: 'Learn basic English word stress rules',
      level: 'beginner',
      lessonNumber: 19,
      type: 'pronunciation',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Sound Foundations',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Basic Stress Patterns',
          content: 'Learn where to place stress in common English words.',
          type: 'theory',
          examples: ['PHOtograph', 'phoTOGraphy', 'photoGRAPHic', 'TEAcher', 'STUdent', 'comPUter'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which syllable is stressed in "computer"?',
          options: ['COM', 'PU', 'TER', 'None'],
          correctAnswer: 'PU',
          explanation: 'The stress in "computer" falls on the second syllable: com-PU-ter.',
        ),
      ],
    ),

    Lesson(
      id: 'beginner_pronunciation_4',
      title: 'Sentence Rhythm',
      description: 'Learn the basic rhythm of English sentences',
      level: 'beginner',
      lessonNumber: 20,
      type: 'pronunciation',
      duration: 28,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Sound Foundations',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Content vs Function Words',
          content: 'Learn which words are stressed (content words) and which are unstressed (function words) in sentences.',
          type: 'theory',
          examples: ['I WANT to GO to the STORE.', 'She IS reading a BOOK.', 'They HAVE three CATS.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which words are typically stressed in English sentences?',
          options: ['Articles (a, an, the)', 'Prepositions (in, on, at)', 'Nouns and main verbs', 'Conjunctions (and, but, or)'],
          correctAnswer: 'Nouns and main verbs',
          explanation: 'Content words like nouns, main verbs, adjectives, and adverbs are usually stressed.',
        ),
      ],
    ),

    // ========== INTERMEDIATE LEVEL (20 Lessons) ==========
    
    // 🔸 INTERMEDIATE - TENSES (4 lessons)
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

    Lesson(
      id: 'intermediate_tenses_2',
      title: 'Past Continuous Tense',
      description: 'Learn to describe ongoing actions in the past',
      level: 'intermediate',
      lessonNumber: 2,
      type: 'grammar',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Complex Tenses',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Past Continuous Usage',
          content: 'Use past continuous for actions in progress at a specific time in the past.',
          type: 'theory',
          examples: ['I was studying when you called.', 'They were watching TV at 8 PM.', 'She was cooking dinner.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses past continuous correctly?',
          options: ['I studied when you called', 'I was studying when you called', 'I am studying when you called', 'I study when you called'],
          correctAnswer: 'I was studying when you called',
          explanation: 'Past continuous describes an action in progress interrupted by another action.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_tenses_3',
      title: 'Future Forms',
      description: 'Master different ways to talk about the future',
      level: 'intermediate',
      lessonNumber: 3,
      type: 'grammar',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Complex Tenses',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Future Tenses',
          content: 'Learn will, going to, present continuous, and present simple for future.',
          type: 'theory',
          examples: ['I will call you later.', 'I am going to visit my parents.', 'My flight leaves at 5 PM.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which is correct for a fixed schedule?',
          options: ['The train will leave at 9', 'The train is going to leave at 9', 'The train leaves at 9', 'The train is leaving at 9'],
          correctAnswer: 'The train leaves at 9',
          explanation: 'Present simple is used for fixed schedules and timetables.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_tenses_4',
      title: 'Past Perfect Tense',
      description: 'Learn to talk about earlier past events',
      level: 'intermediate',
      lessonNumber: 4,
      type: 'grammar',
      duration: 32,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Complex Tenses',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Past Perfect Usage',
          content: 'Use past perfect for actions that happened before another past action.',
          type: 'theory',
          examples: ['I had finished my work when she arrived.', 'They had already eaten when I called.', 'He had never seen snow before he moved to Canada.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses past perfect correctly?',
          options: ['I finished when she had arrived', 'I had finished when she arrived', 'I have finished when she arrived', 'I finish when she had arrived'],
          correctAnswer: 'I had finished when she arrived',
          explanation: 'Past perfect shows the earlier action in a sequence of past events.',
        ),
      ],
    ),

    // 🔸 INTERMEDIATE - IDIOMS (4 lessons)
    Lesson(
      id: 'intermediate_idioms_1',
      title: 'Business Idioms',
      description: 'Idioms commonly used in professional settings',
      level: 'intermediate',
      lessonNumber: 5,
      type: 'vocabulary',
      duration: 25,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 2: Professional Language',
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

    Lesson(
      id: 'intermediate_idioms_2',
      title: 'Animal Idioms',
      description: 'Common idioms featuring animals',
      level: 'intermediate',
      lessonNumber: 6,
      type: 'vocabulary',
      duration: 20,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Professional Language',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Animal Expressions',
          content: 'Idioms that use animals to describe human behavior or situations.',
          type: 'theory',
          examples: ['Busy as a bee', 'Curious as a cat', 'Strong as an ox', 'Sly as a fox'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "busy as a bee" mean?',
          options: ['To be lazy', 'To be very busy', 'To make honey', 'To fly around'],
          correctAnswer: 'To be very busy',
          explanation: 'This idiom means someone is very active and working hard.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_idioms_3',
      title: 'Body Part Idioms',
      description: 'Idioms using body parts',
      level: 'intermediate',
      lessonNumber: 7,
      type: 'vocabulary',
      duration: 22,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Professional Language',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Body Idioms',
          content: 'Common idioms that use body parts to express ideas.',
          type: 'theory',
          examples: ['Keep an eye on', 'Cost an arm and a leg', 'Pull someone\'s leg', 'Get cold feet'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "pull someone\'s leg" mean?',
          options: ['To help someone', 'To joke with someone', 'To hurt someone', 'To ignore someone'],
          correctAnswer: 'To joke with someone',
          explanation: '"Pull someone\'s leg" means to tease or joke with someone playfully.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_idioms_4',
      title: 'Color Idioms',
      description: 'Idioms using colors',
      level: 'intermediate',
      lessonNumber: 8,
      type: 'vocabulary',
      duration: 24,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Professional Language',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Color Expressions',
          content: 'Idioms that use colors to describe emotions and situations.',
          type: 'theory',
          examples: ['Green with envy', 'Feeling blue', 'Caught red-handed', 'Black and white'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "feeling blue" mean?',
          options: ['Feeling cold', 'Feeling sad', 'Feeling angry', 'Feeling happy'],
          correctAnswer: 'Feeling sad',
          explanation: '"Feeling blue" means feeling sad or depressed.',
        ),
      ],
    ),

    // 🔸 INTERMEDIATE - VERBS (4 lessons)
    Lesson(
      id: 'intermediate_verbs_1',
      title: 'Phrasal Verbs',
      description: 'Master common phrasal verbs in English',
      level: 'intermediate',
      lessonNumber: 9,
      type: 'grammar',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Verb Patterns',
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

    Lesson(
      id: 'intermediate_verbs_2',
      title: 'Modal Verbs',
      description: 'Master can, could, may, might, must, should',
      level: 'intermediate',
      lessonNumber: 10,
      type: 'grammar',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Verb Patterns',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Modal Verb Usage',
          content: 'Learn to use modal verbs for ability, possibility, permission, and obligation.',
          type: 'theory',
          examples: ['I can swim.', 'You should study.', 'She might come.', 'We must finish.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which modal shows strong obligation?',
          options: ['can', 'might', 'must', 'could'],
          correctAnswer: 'must',
          explanation: '"Must" shows strong obligation or necessity.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_verbs_3',
      title: 'Gerunds and Infinitives',
      description: 'Master verb patterns after other verbs',
      level: 'intermediate',
      lessonNumber: 11,
      type: 'grammar',
      duration: 38,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Verb Patterns',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Verb Patterns',
          content: 'Learn when to use gerunds (-ing) and when to use infinitives (to + verb) after other verbs.',
          type: 'theory',
          examples: ['I enjoy swimming.', 'She wants to learn.', 'They avoid eating late.', 'He decided to leave.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which verb is followed by a gerund?',
          options: ['want', 'decide', 'enjoy', 'hope'],
          correctAnswer: 'enjoy',
          explanation: '"Enjoy" is followed by a gerund (enjoy + -ing form).',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_verbs_4',
      title: 'Passive Voice',
      description: 'Learn to form and use passive sentences',
      level: 'intermediate',
      lessonNumber: 12,
      type: 'grammar',
      duration: 33,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Verb Patterns',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Passive Forms',
          content: 'Learn how and when to use passive voice in English.',
          type: 'theory',
          examples: ['The book was written by Shakespeare.', 'English is spoken here.', 'The car is being repaired.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence is in passive voice?',
          options: ['She wrote the letter', 'The letter was written by her', 'She is writing the letter', 'She will write the letter'],
          correctAnswer: 'The letter was written by her',
          explanation: 'Passive voice focuses on the action, not who performed it.',
        ),
      ],
    ),

    // 🔸 INTERMEDIATE - PHRASES (4 lessons)
    Lesson(
      id: 'intermediate_phrases_1',
      title: 'Social Conversation Phrases',
      description: 'Phrases for natural social interactions',
      level: 'intermediate',
      lessonNumber: 13,
      type: 'conversation',
      duration: 20,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social Skills',
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

    Lesson(
      id: 'intermediate_phrases_2',
      title: 'Opinion and Agreement Phrases',
      description: 'Express your views and agree/disagree politely',
      level: 'intermediate',
      lessonNumber: 14,
      type: 'conversation',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social Skills',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Expressing Opinions',
          content: 'Learn how to express your views and respond to others politely.',
          type: 'theory',
          examples: ['In my opinion...', 'I think that...', 'I see your point, but...', 'That\'s a good point.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase shows polite disagreement?',
          options: ['You\'re wrong', 'I disagree completely', 'I see your point, but...', 'That\'s stupid'],
          correctAnswer: 'I see your point, but...',
          explanation: 'This acknowledges the other person\'s view before presenting your different opinion.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_phrases_3',
      title: 'Telephone English',
      description: 'Essential phrases for phone conversations',
      level: 'intermediate',
      lessonNumber: 15,
      type: 'conversation',
      duration: 28,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social Skills',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Phone Language',
          content: 'Learn phrases for making and receiving phone calls professionally.',
          type: 'theory',
          examples: ['May I speak to...?', 'Who\'s calling please?', 'Could I leave a message?', 'I\'ll put you through.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What is a polite way to ask who is calling?',
          options: ['Who is this?', 'Who are you?', 'May I ask who\'s calling?', 'Tell me your name'],
          correctAnswer: 'May I ask who\'s calling?',
          explanation: 'This is a polite and professional way to ask for the caller\'s identity.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_phrases_4',
      title: 'Email Writing Phrases',
      description: 'Professional phrases for email communication',
      level: 'intermediate',
      lessonNumber: 16,
      type: 'writing',
      duration: 32,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Social Skills',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Email Language',
          content: 'Learn professional phrases for different parts of business emails.',
          type: 'theory',
          examples: ['I am writing to inquire about...', 'Thank you for your prompt response.', 'I look forward to hearing from you.', 'Best regards'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which is an appropriate email closing?',
          options: ['See ya', 'Bye', 'Best regards', 'Later'],
          correctAnswer: 'Best regards',
          explanation: '"Best regards" is professional and appropriate for business emails.',
        ),
      ],
    ),

    // 🔸 INTERMEDIATE - PRONUNCIATION (4 lessons)
    Lesson(
      id: 'intermediate_pronunciation_1',
      title: 'Vowel Contrasts',
      description: 'Master difficult vowel distinctions',
      level: 'intermediate',
      lessonNumber: 17,
      type: 'pronunciation',
      duration: 30,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 5: Advanced Sounds',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Similar Vowel Sounds',
          content: 'Learn to distinguish between similar vowel sounds that are often confused.',
          type: 'theory',
          examples: ['ship vs sheep', 'cat vs cut', 'pool vs pull', 'bad vs bed'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which word has the same vowel sound as "sheep"?',
          options: ['ship', 'sleep', 'shape', 'shop'],
          correctAnswer: 'sleep',
          explanation: 'Both "sheep" and "sleep" have the long E sound /iː/.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_pronunciation_2',
      title: 'Linking and Connected Speech',
      description: 'Learn how words connect in natural speech',
      level: 'intermediate',
      lessonNumber: 18,
      type: 'pronunciation',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Advanced Sounds',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Connected Speech Patterns',
          content: 'Learn how sounds change when words are spoken together naturally.',
          type: 'theory',
          examples: ['What are you → Whaddaya', 'Going to → Gonna', 'Want to → Wanna', 'Could you → Couldja'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'How is "going to" often pronounced in casual speech?',
          options: ['go-in-to', 'gon-na', 'go-ing-to', 'go-to'],
          correctAnswer: 'gon-na',
          explanation: '"Going to" is often reduced to "gonna" in informal spoken English.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_pronunciation_3',
      title: 'Intonation Patterns',
      description: 'Master rising and falling intonation',
      level: 'intermediate',
      lessonNumber: 19,
      type: 'pronunciation',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Advanced Sounds',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Question Intonation',
          content: 'Learn how voice pitch rises and falls in different types of questions.',
          type: 'theory',
          examples: ['Rising for yes/no questions', 'Falling for information questions', 'Rise-fall for choice questions'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which question typically uses rising intonation?',
          options: ['What time is it?', 'Where do you live?', 'Are you coming?', 'How old are you?'],
          correctAnswer: 'Are you coming?',
          explanation: 'Yes/no questions like "Are you coming?" usually have rising intonation.',
        ),
      ],
    ),

    Lesson(
      id: 'intermediate_pronunciation_4',
      title: 'Consonant Clusters',
      description: 'Master difficult consonant combinations',
      level: 'intermediate',
      lessonNumber: 20,
      type: 'pronunciation',
      duration: 28,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Advanced Sounds',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Difficult Clusters',
          content: 'Learn to pronounce challenging consonant combinations clearly.',
          type: 'theory',
          examples: ['strengths', 'twelfths', 'asks', 'world', 'months'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which word has a consonant cluster?',
          options: ['cat', 'dog', 'strength', 'book'],
          correctAnswer: 'strength',
          explanation: '"Strength" has the consonant cluster "str" at the beginning.',
        ),
      ],
    ),

    // ========== ADVANCED LEVEL (20 Lessons) ==========
    
    // 🔷 ADVANCED - TENSES (4 lessons)
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

    Lesson(
      id: 'advanced_tenses_2',
      title: 'Perfect Continuous Tenses',
      description: 'Master present/past/future perfect continuous',
      level: 'advanced',
      lessonNumber: 2,
      type: 'grammar',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Advanced Grammar',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Perfect Continuous Forms',
          content: 'Learn to use perfect continuous tenses for actions over periods of time.',
          type: 'theory',
          examples: ['I have been studying for 3 hours.', 'She had been waiting when I arrived.', 'They will have been working here for 10 years.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses present perfect continuous?',
          options: ['I have studied', 'I have been studying', 'I studied', 'I was studying'],
          correctAnswer: 'I have been studying',
          explanation: 'Present perfect continuous emphasizes the duration of an ongoing action.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_tenses_3',
      title: 'Subjunctive Mood',
      description: 'Master hypothetical and wish expressions',
      level: 'advanced',
      lessonNumber: 3,
      type: 'grammar',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Advanced Grammar',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Subjunctive Forms',
          content: 'Learn to use subjunctive for wishes, hypothetical situations, and formal requests.',
          type: 'theory',
          examples: ['I wish I were taller.', 'If I were you, I would...', 'It\'s essential that he be here.', 'I suggest that she study more.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses the subjunctive correctly?',
          options: ['I wish I was taller', 'I wish I were taller', 'I wish I am taller', 'I wish I will be taller'],
          correctAnswer: 'I wish I were taller',
          explanation: 'The subjunctive uses "were" for all persons in hypothetical situations.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_tenses_4',
      title: 'Future in the Past',
      description: 'Master talking about past future events',
      level: 'advanced',
      lessonNumber: 4,
      type: 'grammar',
      duration: 32,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 1: Advanced Grammar',
      category: 'tenses',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Future in the Past Forms',
          content: 'Learn to talk about future events from a past perspective.',
          type: 'theory',
          examples: ['I knew she would come.', 'They thought it was going to rain.', 'He said he would call.', 'We were going to leave early.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses "future in the past" correctly?',
          options: ['I know she will come', 'I knew she would come', 'I know she would come', 'I knew she will come'],
          correctAnswer: 'I knew she would come',
          explanation: '"Would" is used to express future from a past perspective.',
        ),
      ],
    ),

    // 🔷 ADVANCED - IDIOMS (4 lessons)
    Lesson(
      id: 'advanced_idioms_1',
      title: 'Advanced Cultural Idioms',
      description: 'Complex idioms and their cultural origins',
      level: 'advanced',
      lessonNumber: 5,
      type: 'vocabulary',
      duration: 30,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 2: Cultural English',
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

    Lesson(
      id: 'advanced_idioms_2',
      title: 'Academic and Formal Idioms',
      description: 'Idioms used in academic and formal writing',
      level: 'advanced',
      lessonNumber: 6,
      type: 'vocabulary',
      duration: 25,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Cultural English',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Formal Expressions',
          content: 'Idioms and expressions commonly used in academic papers and formal documents.',
          type: 'theory',
          examples: ['In light of these findings', 'It stands to reason that', 'By the same token', 'Be that as it may'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "by the same token" mean?',
          options: ['Using the same method', 'For the same reasons', 'With the same object', 'At the same time'],
          correctAnswer: 'For the same reasons',
          explanation: 'This phrase means "for the same reasons" or "similarly".',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_idioms_3',
      title: 'Legal and Political Idioms',
      description: 'Idioms from legal and political contexts',
      level: 'advanced',
      lessonNumber: 7,
      type: 'vocabulary',
      duration: 28,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Cultural English',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Professional Idioms',
          content: 'Idioms commonly used in legal, political, and professional contexts.',
          type: 'theory',
          examples: ['Above board', 'In good faith', 'Without prejudice', 'The bottom line'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "above board" mean?',
          options: ['On the surface', 'Honest and legal', 'Higher than expected', 'Over the table'],
          correctAnswer: 'Honest and legal',
          explanation: '"Above board" means legitimate, honest, and without deception.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_idioms_4',
      title: 'Metaphorical Idioms',
      description: 'Complex metaphorical expressions',
      level: 'advanced',
      lessonNumber: 8,
      type: 'vocabulary',
      duration: 32,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 2: Cultural English',
      category: 'idioms',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Complex Metaphors',
          content: 'Advanced idioms that use complex metaphorical language.',
          type: 'theory',
          examples: ['The elephant in the room', 'A blessing in disguise', 'A double-edged sword', 'A stitch in time saves nine'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does "a double-edged sword" mean?',
          options: ['A dangerous weapon', 'Something with advantages and disadvantages', 'A sharp object', 'A military strategy'],
          correctAnswer: 'Something with advantages and disadvantages',
          explanation: 'This means something that has both positive and negative consequences.',
        ),
      ],
    ),

    // 🔷 ADVANCED - VERBS (4 lessons)
    Lesson(
      id: 'advanced_verbs_1',
      title: 'Reporting Verbs',
      description: 'Master verbs for reported speech and academic writing',
      level: 'advanced',
      lessonNumber: 9,
      type: 'grammar',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Advanced Verb Usage',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Advanced Reporting Verbs',
          content: 'Learn sophisticated verbs for reporting what others have said or written.',
          type: 'theory',
          examples: ['The researcher asserted that...', 'She contended that...', 'He postulated that...', 'The study demonstrated that...'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which reporting verb suggests strong confidence?',
          options: ['suggested', 'asserted', 'wondered', 'speculated'],
          correctAnswer: 'asserted',
          explanation: '"Asserted" indicates strong confidence and declaration.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_verbs_2',
      title: 'Causative Verbs',
      description: 'Master have, get, make, let in causative structures',
      level: 'advanced',
      lessonNumber: 10,
      type: 'grammar',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Advanced Verb Usage',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Causative Structures',
          content: 'Learn to use causative verbs to indicate that someone causes something to happen.',
          type: 'theory',
          examples: ['I had my car repaired.', 'She got her hair cut.', 'He made me do it.', 'They let us leave early.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses causative "have" correctly?',
          options: ['I had repair my car', 'I had my car repair', 'I had my car repaired', 'I had repaired my car'],
          correctAnswer: 'I had my car repaired',
          explanation: 'The structure is "have + object + past participle".',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_verbs_3',
      title: 'Inversion Structures',
      description: 'Master advanced sentence inversion',
      level: 'advanced',
      lessonNumber: 11,
      type: 'grammar',
      duration: 38,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Advanced Verb Usage',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Inversion Patterns',
          content: 'Learn advanced inversion structures for emphasis and formal writing.',
          type: 'theory',
          examples: ['Never have I seen such beauty.', 'Not only did she finish early, but she also...', 'Little did they know...', 'Under no circumstances will we accept...'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses inversion correctly?',
          options: ['Never I have seen such beauty', 'Never have I seen such beauty', 'Never I seen such beauty', 'Never I saw such beauty'],
          correctAnswer: 'Never have I seen such beauty',
          explanation: 'Inversion requires auxiliary verb + subject after negative adverbs.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_verbs_4',
      title: 'Ellipsis and Substitution',
      description: 'Master omitting and replacing words in context',
      level: 'advanced',
      lessonNumber: 12,
      type: 'grammar',
      duration: 33,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 3: Advanced Verb Usage',
      category: 'verbs',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Ellipsis Patterns',
          content: 'Learn when and how to omit words that can be understood from context.',
          type: 'theory',
          examples: ['She can play piano, and he can [play piano] too.', 'I\'ll help if I can [help].', 'He works harder than she does [work].'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which sentence uses ellipsis correctly?',
          options: ['She can swim and he can too', 'She can swim and he can swim too', 'She can swim and he too', 'She can swim and he can'],
          correctAnswer: 'She can swim and he can too',
          explanation: 'The verb "swim" is correctly omitted as it can be understood from context.',
        ),
      ],
    ),

    // 🔷 ADVANCED - PHRASES (4 lessons)
    Lesson(
      id: 'advanced_phrases_1',
      title: 'Negotiation and Persuasion',
      description: 'Advanced phrases for professional discussions',
      level: 'advanced',
      lessonNumber: 13,
      type: 'conversation',
      duration: 40,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Professional Communication',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Persuasive Language',
          content: 'Learn sophisticated phrases for negotiating, persuading, and influencing in professional contexts.',
          type: 'theory',
          examples: ['I\'d like to propose that...', 'From our perspective...', 'What if we were to...', 'I see where you\'re coming from, however...'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase is most diplomatic for disagreeing?',
          options: ['You\'re wrong', 'I completely disagree', 'I see your point, however...', 'That makes no sense'],
          correctAnswer: 'I see your point, however...',
          explanation: 'This acknowledges the other person\'s view before presenting a counter-argument.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_phrases_2',
      title: 'Academic Discussion Phrases',
      description: 'Phrases for academic debates and presentations',
      level: 'advanced',
      lessonNumber: 14,
      type: 'conversation',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Professional Communication',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Academic Language',
          content: 'Learn formal phrases for academic discussions, presentations, and debates.',
          type: 'theory',
          examples: ['The data seems to indicate that...', 'Contrary to popular belief...', 'It could be argued that...', 'The evidence suggests...'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase introduces a counter-argument in academic writing?',
          options: ['Everyone knows that...', 'It could be argued that...', 'I think that...', 'This is true because...'],
          correctAnswer: 'It could be argued that...',
          explanation: 'This phrase introduces an alternative perspective in a formal, academic way.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_phrases_3',
      title: 'Diplomatic Language',
      description: 'Phrases for sensitive and diplomatic communication',
      level: 'advanced',
      lessonNumber: 15,
      type: 'conversation',
      duration: 38,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Professional Communication',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Diplomatic Expressions',
          content: 'Learn phrases for handling sensitive topics and maintaining professional relationships.',
          type: 'theory',
          examples: ['With all due respect...', 'I appreciate your perspective, but...', 'Perhaps we could consider...', 'I understand your concerns, however...'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase is most diplomatic for expressing disagreement?',
          options: ['You\'re mistaken', 'I think you\'re wrong', 'With all due respect, I see it differently', 'That\'s incorrect'],
          correctAnswer: 'With all due respect, I see it differently',
          explanation: 'This shows respect while clearly stating a different opinion.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_phrases_4',
      title: 'Crisis Management Phrases',
      description: 'Professional phrases for handling difficult situations',
      level: 'advanced',
      lessonNumber: 16,
      type: 'conversation',
      duration: 42,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 4: Professional Communication',
      category: 'phrases',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Crisis Communication',
          content: 'Learn appropriate phrases for handling complaints, apologies, and difficult conversations professionally.',
          type: 'theory',
          examples: ['I understand your frustration...', 'Let me see what I can do to resolve this.', 'I apologize for the inconvenience.', 'Thank you for bringing this to our attention.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which phrase is best for handling a customer complaint?',
          options: ['It\'s not my problem', 'I understand your frustration', 'You should have been more careful', 'That\'s your fault'],
          correctAnswer: 'I understand your frustration',
          explanation: 'This shows empathy and acknowledges the customer\'s feelings.',
        ),
      ],
    ),

    // 🔷 ADVANCED - PRONUNCIATION (4 lessons)
    Lesson(
      id: 'advanced_pronunciation_1',
      title: 'Advanced Stress and Rhythm',
      description: 'Master sentence stress and speech rhythm',
      level: 'advanced',
      lessonNumber: 17,
      type: 'pronunciation',
      duration: 40,
      isUnlocked: true,
      progress: 0.0,
      unit: 'Unit 5: Native-like Speech',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Sentence Stress Patterns',
          content: 'Learn how stress on different words changes meaning in sentences.',
          type: 'theory',
          examples: ['I didn\'t say HE stole the money.', 'I didn\'t SAY he stole the money.', 'I didn\'t say he STOLE the money.'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'What does stressing "HE" imply in "I didn\'t say HE stole the money"?',
          options: ['Someone else said it', 'Someone else stole it', 'He borrowed it', 'It wasn\'t money'],
          correctAnswer: 'Someone else stole it',
          explanation: 'Stressing "HE" implies that someone else, not him, stole the money.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_pronunciation_2',
      title: 'Reduction and Assimilation',
      description: 'Master native speaker sound changes',
      level: 'advanced',
      lessonNumber: 18,
      type: 'pronunciation',
      duration: 35,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Native-like Speech',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Sound Assimilation',
          content: 'Learn how sounds change when they come together in fast, natural speech.',
          type: 'theory',
          examples: ['Did you → Didja', 'Want to → Wanna', 'Going to → Gonna', 'Could you → Couldja'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'How is "did you" typically pronounced in fast speech?',
          options: ['did-you', 'did-ya', 'did-ja', 'di-doo'],
          correctAnswer: 'did-ja',
          explanation: '"Did you" often becomes "didja" in connected speech.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_pronunciation_3',
      title: 'Advanced Intonation Patterns',
      description: 'Master sophisticated intonation for emphasis and attitude',
      level: 'advanced',
      lessonNumber: 19,
      type: 'pronunciation',
      duration: 30,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Native-like Speech',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Emotional Intonation',
          content: 'Learn how intonation conveys emotions, attitudes, and subtle meanings.',
          type: 'theory',
          examples: ['Really? (surprise)', 'Really. (boredom)', 'I see. (interest)', 'I see. (disinterest)'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which intonation pattern typically shows surprise?',
          options: ['Falling', 'Rising', 'Rise-fall', 'Fall-rise'],
          correctAnswer: 'Rise-fall',
          explanation: 'A sharp rise-fall intonation often indicates surprise or strong emotion.',
        ),
      ],
    ),

    Lesson(
      id: 'advanced_pronunciation_4',
      title: 'Regional Accent Features',
      description: 'Understand key features of major English accents',
      level: 'advanced',
      lessonNumber: 20,
      type: 'pronunciation',
      duration: 45,
      isUnlocked: false,
      progress: 0.0,
      unit: 'Unit 5: Native-like Speech',
      category: 'pronunciation',
      sections: [
        LessonSection(
          id: 'sec1',
          title: 'Accent Variations',
          content: 'Learn about key pronunciation differences between major English accents like American, British, and Australian.',
          type: 'theory',
          examples: ['American: water → "wader"', 'British: water → "waw-tuh"', 'Australian: day → "die"', 'Rhotic vs non-rhotic R sounds'],
        ),
      ],
      exercises: [
        Exercise(
          id: 'ex1',
          type: 'multiple_choice',
          question: 'Which accent typically pronounces "r" at the end of words?',
          options: ['British English', 'Australian English', 'American English', 'All of them'],
          correctAnswer: 'American English',
          explanation: 'American English is rhotic, meaning "r" is pronounced at the end of words.',
        ),
      ],
    ),
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