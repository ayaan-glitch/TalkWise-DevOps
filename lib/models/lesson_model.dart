// lib/models/lesson_model.dart
class LessonModel {
  final String id;
  final String title;
  final String unit;
  final String level;
  final List<Exercise> exercises;
  final int order;
  final int estimatedTime; // in minutes
  final String description;
  final String category;

  LessonModel({
    required this.id,
    required this.title,
    required this.unit,
    required this.level,
    required this.exercises,
    required this.order,
    required this.estimatedTime,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
      'level': level,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'order': order,
      'estimatedTime': estimatedTime,
      'description': description,
      'category': category,
    };
  }

  static LessonModel fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'],
      title: map['title'],
      unit: map['unit'],
      level: map['level'],
      exercises: List<Exercise>.from(
          map['exercises'].map((x) => Exercise.fromMap(x))),
      order: map['order'],
      estimatedTime: map['estimatedTime'],
      description: map['description'],
      category: map['category'],
    );
  }

  // Get demo lessons for testing
  static List<LessonModel> getDemoLessons() {
    return [
      LessonModel(
        id: 'lesson_1',
        title: 'Greetings & Introductions',
        unit: 'Unit 1',
        level: 'A1',
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'vocabulary',
            word: 'Hello',
            phonetic: '/həˈloʊ/',
            meaning: 'A greeting or expression of goodwill',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['Hi', 'Goodbye', 'Thank you', 'Please'],
          ),
          Exercise(
            id: 'ex2',
            type: 'vocabulary',
            word: 'Goodbye',
            phonetic: '/ɡʊdˈbaɪ/',
            meaning: 'A farewell or expression used when parting',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['Hello', 'See you', 'Welcome', 'Sorry'],
          ),
        ],
        order: 1,
        estimatedTime: 15,
        description: 'Learn basic greetings and introductions',
        category: 'Conversations',
      ),
      LessonModel(
        id: 'lesson_2',
        title: 'Asking for Directions',
        unit: 'Unit 2',
        level: 'A1',
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'vocabulary',
            word: 'Where',
            phonetic: '/wer/',
            meaning: 'In or to what place or position',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['When', 'Why', 'How', 'What'],
          ),
          Exercise(
            id: 'ex2',
            type: 'vocabulary',
            word: 'Street',
            phonetic: '/striːt/',
            meaning: 'A public road in a city or town',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['Road', 'Avenue', 'Path', 'Highway'],
          ),
        ],
        order: 2,
        estimatedTime: 20,
        description: 'Learn how to ask for and give directions',
        category: 'Navigation',
      ),
      LessonModel(
        id: 'lesson_3',
        title: 'Daily Conversations',
        unit: 'Unit 3',
        level: 'A2',
        exercises: [
          Exercise(
            id: 'ex1',
            type: 'vocabulary',
            word: 'Restaurant',
            phonetic: '/ˈrestərənt/',
            meaning: 'A place where people pay to sit and eat meals',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['Cafe', 'Hotel', 'Market', 'School'],
          ),
          Exercise(
            id: 'ex2',
            type: 'vocabulary',
            word: 'Menu',
            phonetic: '/ˈmenjuː/',
            meaning: 'A list of dishes available in a restaurant',
            audioUrl: '',
            contextAudioUrl: '',
            options: ['List', 'Book', 'Card', 'Table'],
          ),
        ],
        order: 3,
        estimatedTime: 18,
        description: 'Practice conversations for daily situations',
        category: 'Conversations',
      ),
    ];
  }
}

class Exercise {
  final String id;
  final String type;
  final String word;
  final String phonetic;
  final String meaning;
  final String audioUrl;
  final String contextAudioUrl;
  final List<String> options;
  final String? correctAnswer;

  Exercise({
    required this.id,
    required this.type,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.audioUrl,
    required this.contextAudioUrl,
    this.options = const [],
    this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'audioUrl': audioUrl,
      'contextAudioUrl': contextAudioUrl,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  static Exercise fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      type: map['type'],
      word: map['word'],
      phonetic: map['phonetic'],
      meaning: map['meaning'],
      audioUrl: map['audioUrl'],
      contextAudioUrl: map['contextAudioUrl'],
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'],
    );
  }
}