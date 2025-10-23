// lib/pages/pronunciation_backend.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import '../services/firebase_service.dart';

class PronunciationBackend with ChangeNotifier {
  static final PronunciationBackend _instance = PronunciationBackend._internal();
  factory PronunciationBackend() => _instance;

  // Add these properties to the PronunciationBackend class
  bool _isPlaying = false;
  double _speechRate = 1.0; // Default speed

  // Speech recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastSpokenText = '';

  // Add getters for the new properties
  bool get isPlaying => _isPlaying;
  double get speechRate => _speechRate;
  bool get isListening => _isListening;
  String get lastSpokenText => _lastSpokenText;

  int get currentWordIndex => _currentWordIndex;
  int get currentWordListLength => _currentWordList.length;
  
  PronunciationBackend._internal() {
    _loadUserProgress();
    _initRecorder();
    _initSpeech();
  }

  // API Configuration
  static const String MERRIAM_WEBSTER_API_KEY = '6b6c9792-9cba-4e4f-a236-ea64ec1a95dd';
  static const String DICTIONARY_API_BASE = 'https://dictionaryapi.com/api/v3/references/learners/json/';
  
  // Fallback to WordsAPI if Merriam-Webster fails
  static const String WORDS_API_KEY = 'your-wordsapi-key-here';
  static const String WORDS_API_BASE = 'https://wordsapiv1.p.rapidapi.com/words/';

  // TTS engine for pronunciation
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // Current user and progress
  UserModel? _currentUser;
  ProgressModel? _userProgress;
  
  // Pronunciation practice state
  int _currentWordIndex = 0;
  String _currentLevel = 'beginner';
  bool _isRecording = false;
  bool _audioContextEnabled = true;
  double _pronunciationScore = 0.0;
  Duration _recordingDuration = Duration.zero;
  double _amplitudeLevel = 0.0;
  Timer? _recordingTimer;
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  
  // API-related state
  bool _isLoading = false;
  String _errorMessage = '';
  List<PronunciationWord> _currentWordList = [];
  Map<String, List<PronunciationWord>> _cachedWords = {};

  // Getters
  UserModel? get currentUser => _currentUser;
  ProgressModel? get userProgress => _userProgress;
  bool get isRecording => _isRecording;
  bool get audioContextEnabled => _audioContextEnabled;
  double get pronunciationScore => _pronunciationScore;
  String get currentLevel => _currentLevel;
  Duration get recordingDuration => _recordingDuration;
  double get amplitudeLevel => _amplitudeLevel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<PronunciationWord> get currentWordList => _currentWordList;

  // Initialize speech recognition
Future<void> _initSpeech() async {
  try {
    bool available = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        _isListening = false;
        _errorMessage = 'Speech recognition error occurred';
        notifyListeners();
      },
    );
    
    if (available) {
      debugPrint('Speech recognition initialized');
    } else {
      debugPrint('Speech recognition not available');
      _errorMessage = 'Speech recognition not available on this device';
    }
  } catch (e) {
    debugPrint('Error initializing speech: $e');
    _errorMessage = 'Failed to initialize speech recognition';
  }
  notifyListeners();
}

  // Initialize recorder
  Future<void> _initRecorder() async {
    try {
      if (kIsWeb) {
        debugPrint('Running on web - using simplified audio recording');
        return;
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        return;
      }
      
      _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
        _isRecording = recordState == RecordState.record;
        notifyListeners();
      });
      
      _amplitudeSub = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        _amplitudeLevel = (amp.current + 160) / 160;
        notifyListeners();
      });
      
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  // Load user progress from persistent storage and Firebase
  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.containsKey('currentUser')) {
        final userMap = prefs.getString('currentUser');
        if (userMap != null) {
          _currentUser = UserModel.fromMap(json.decode(userMap));
        }
      }
      
      if (prefs.containsKey('userProgress')) {
        final progressMap = prefs.getString('userProgress');
        if (progressMap != null) {
          _userProgress = ProgressModel.fromMap(json.decode(progressMap));
        }
      }
      
      if (prefs.containsKey('pronunciationLevel')) {
        _currentLevel = prefs.getString('pronunciationLevel') ?? 'beginner';
      }
      
      // Load cached words if available
      if (prefs.containsKey('cachedPronunciationWords')) {
        final cachedMap = prefs.getString('cachedPronunciationWords');
        if (cachedMap != null) {
          final decodedMap = json.decode(cachedMap);
          _cachedWords = Map<String, List<PronunciationWord>>.from(
            decodedMap.map((key, value) => 
              MapEntry(key, (value as List).map((e) => PronunciationWord.fromMap(e)).toList())
            )
          );
          _currentWordList = _cachedWords[_currentLevel] ?? [];
        }
      }
      
      // If no cached words, load initial words for current level
      if (_currentWordList.isEmpty) {
        await _loadWordsForLevel(_currentLevel);
      }
      
      // Load pronunciation history from Firebase
      await _loadPronunciationHistory();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      // Load fallback words if loading fails
      _loadFallbackWords();
    }
  }

  // Load pronunciation history from Firebase
  Future<void> _loadPronunciationHistory() async {
    try {
      final history = await FirebaseService.getPronunciationHistory();
      if (history.isNotEmpty) {
        // Update words practiced count
        _wordsPracticed = history.length;
        
        // Calculate average score
        final totalScore = history.map((p) => p['score'] as double).reduce((a, b) => a + b);
        _averagePronunciationScore = totalScore / history.length;
        
        // Calculate best score
        _bestPronunciationScore = history.map((p) => p['score'] as double).reduce((a, b) => a > b ? a : b);
        
        debugPrint('Loaded pronunciation history: ${history.length} sessions');
      }
    } catch (e) {
      debugPrint('Error loading pronunciation history: $e');
    }
  }

  // Load words for a specific level from API
  Future<void> _loadWordsForLevel(String level) async {
    if (_cachedWords.containsKey(level) && _cachedWords[level]!.isNotEmpty) {
      _currentWordList = _cachedWords[level]!;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      List<String> wordsToFetch = _getWordsForLevel(level);
      List<PronunciationWord> fetchedWords = [];

      for (String word in wordsToFetch) {
        try {
          PronunciationWord? wordData = await _fetchWordFromAPI(word);
          if (wordData != null) {
            fetchedWords.add(wordData);
          }
          // Delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Error fetching word $word: $e');
        }
      }

      if (fetchedWords.isNotEmpty) {
        _cachedWords[level] = fetchedWords;
        _currentWordList = fetchedWords;
        await _saveCachedWords();
      } else {
        // Fallback to built-in words if API fails
        _loadFallbackWordsForLevel(level);
      }
    } catch (e) {
      debugPrint('Error loading words for level $level: $e');
      _errorMessage = 'Failed to load words. Using offline data.';
      _loadFallbackWordsForLevel(level);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch word data from Merriam-Webster API
  Future<PronunciationWord?> _fetchWordFromAPI(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$DICTIONARY_API_BASE${Uri.encodeComponent(word)}?key=$MERRIAM_WEBSTER_API_KEY')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseMerriamWebsterResponse(word, response.body);
      } else {
        // Try WordsAPI as fallback
        return await _fetchFromWordsAPI(word);
      }
    } catch (e) {
      debugPrint('Merriam-Webster API error for $word: $e');
      return await _fetchFromWordsAPI(word);
    }
  }

  // Parse Merriam-Webster API response
  PronunciationWord? _parseMerriamWebsterResponse(String word, String responseBody) {
    try {
      final List<dynamic> data = json.decode(responseBody);
      if (data.isEmpty || data[0] is String) {
        return null; // Word not found or suggestion returned
      }

      final Map<String, dynamic> entry = data[0];
      final List<dynamic> definitions = entry['shortdef'] ?? [];
      final String phonetic = entry['hwi']?['prs']?[0]?['mw'] ?? '/${word.toLowerCase()}/';
      
      if (definitions.isNotEmpty) {
        // FIX: Use explicit type and conditional logic instead of min
        int endIndex = 3;
        if (definitions.length < 3) {
          endIndex = definitions.length;
        }
        
        return PronunciationWord(
          word: word,
          phonetic: phonetic,
          meaning: definitions[0].toString(),
          category: _determineCategory(word, definitions[0].toString()),
          difficulty: _currentLevel,
          audioUrl: '', // Merriam-Webster doesn't provide audio in free tier
          context: _generateContext(word, definitions[0].toString()),
          examples: definitions.sublist(0, endIndex).cast<String>(),
          synonyms: _extractSynonyms(entry),
        );
      }
    } catch (e) {
      debugPrint('Error parsing Merriam-Webster response: $e');
    }
    return null;
  }

  // Fetch from WordsAPI as fallback
  Future<PronunciationWord?> _fetchFromWordsAPI(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$WORDS_API_BASE${Uri.encodeComponent(word)}'),
        headers: {
          'X-RapidAPI-Key': WORDS_API_KEY,
          'X-RapidAPI-Host': 'wordsapiv1.p.rapidapi.com'
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseWordsAPIResponse(word, response.body);
      }
    } catch (e) {
      debugPrint('WordsAPI error for $word: $e');
    }
    return null;
  }

  // Parse WordsAPI response
  PronunciationWord? _parseWordsAPIResponse(String word, String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);
      final List<dynamic> definitions = data['results'] ?? [];
      
      if (definitions.isNotEmpty) {
        final Map<String, dynamic> firstDef = definitions[0];
        return PronunciationWord(
          word: word,
          phonetic: data['pronunciation']?['all'] ?? '/${word.toLowerCase()}/',
          meaning: firstDef['definition'] ?? 'Definition not available',
          category: firstDef['partOfSpeech'] ?? 'General',
          difficulty: _currentLevel,
          audioUrl: '',
          context: _generateContext(word, firstDef['definition'] ?? ''),
          examples: firstDef['examples']?.cast<String>() ?? [],
          synonyms: firstDef['synonyms']?.cast<String>() ?? [],
        );
      }
    } catch (e) {
      debugPrint('Error parsing WordsAPI response: $e');
    }
    return null;
  }

  // Helper methods for word processing
  String _determineCategory(String word, String definition) {
    final List<String> categories = ['Noun', 'Verb', 'Adjective', 'Adverb', 'Preposition', 'Conjunction'];
    for (String category in categories) {
      if (definition.toLowerCase().contains(category.toLowerCase())) {
        return category;
      }
    }
    return 'General';
  }

  String _generateContext(String word, String definition) {
    return "Use '$word' when: ${definition.toLowerCase()}";
  }

  List<String> _extractSynonyms(Map<String, dynamic> entry) {
    try {
      final List<dynamic> syns = entry['meta']?['syns'] ?? [];
      if (syns.isNotEmpty && syns[0] is List) {
        // FIX: Use conditional logic instead of min
        int endIndex = 5;
        if (syns[0].length < 5) {
          endIndex = syns[0].length;
        }
        return syns[0].cast<String>().sublist(0, endIndex);
      }
    } catch (e) {
      debugPrint('Error extracting synonyms: $e');
    }
    return [];
  }

  // Get words appropriate for each level
  List<String> _getWordsForLevel(String level) {
    switch (level) {
      case 'beginner':
        return ['hello', 'water', 'food', 'family', 'friend', 'house', 'school', 'work', 'time', 'day'];
      case 'intermediate':
        return ['conversation', 'beautiful', 'important', 'different', 'restaurant', 'education', 'government', 'technology', 'environment', 'communication'];
      case 'advanced':
        return ['entrepreneur', 'pronunciation', 'nevertheless', 'approximately', 'characteristic', 'sophisticated', 'comprehensive', 'contemporary', 'philosophical', 'revolutionary'];
      default:
        return ['hello', 'world', 'english', 'learning', 'practice'];
    }
  }

  // Fallback words if API fails
  void _loadFallbackWordsForLevel(String level) {
    _currentWordList = _getFallbackWords()[level] ?? [];
    _cachedWords[level] = _currentWordList;
    notifyListeners();
  }

  void _loadFallbackWords() {
    _currentWordList = _getFallbackWords()[_currentLevel] ?? [_getFallbackWord()];
    notifyListeners();
  }

  Map<String, List<PronunciationWord>> _getFallbackWords() {
    return {
      'beginner': [
        PronunciationWord(
          word: 'Hello',
          phonetic: '/həˈloʊ/',
          meaning: 'A greeting or expression of goodwill',
          category: 'Greetings',
          difficulty: 'beginner',
          audioUrl: '',
          context: 'Meeting someone for the first time',
          examples: ['Hello, how are you?', 'She said hello to her neighbor.'],
          synonyms: ['Hi', 'Greetings', 'Salutations'],
        ),
        PronunciationWord(
          word: 'Water',
          phonetic: '/ˈwɔːtər/',
          meaning: 'A clear liquid essential for life',
          category: 'Basics',
          difficulty: 'beginner',
          audioUrl: '',
          context: 'Asking for a drink',
          examples: ['Can I have some water?', 'The water is cold.'],
          synonyms: ['H2O', 'Aqua', 'Liquid'],
        ),
        PronunciationWord(
          word: 'Food',
          phonetic: '/fuːd/',
          meaning: 'Any nutritious substance that people eat',
          category: 'Basics',
          difficulty: 'beginner',
          audioUrl: '',
          context: 'Ordering at a restaurant',
          examples: ['I love Italian food.', 'The food was delicious.'],
          synonyms: ['Meal', 'Cuisine', 'Dish'],
        ),
      ],
      'intermediate': [
        PronunciationWord(
          word: 'Conversation',
          phonetic: '/ˌkɑːnvərˈseɪʃən/',
          meaning: 'A talk between two or more people',
          category: 'Communication',
          difficulty: 'intermediate',
          audioUrl: '',
          context: 'Social interactions',
          examples: ['We had a long conversation about politics.', 'The conversation was very interesting.'],
          synonyms: ['Discussion', 'Dialogue', 'Chat'],
        ),
        PronunciationWord(
          word: 'Beautiful',
          phonetic: '/ˈbjuːtɪfəl/',
          meaning: 'Pleasing the senses or mind',
          category: 'Adjectives',
          difficulty: 'intermediate',
          audioUrl: '',
          context: 'Describing scenery or people',
          examples: ['She has a beautiful smile.', 'The sunset was beautiful.'],
          synonyms: ['Lovely', 'Gorgeous', 'Stunning'],
        ),
      ],
      'advanced': [
        PronunciationWord(
          word: 'Entrepreneur',
          phonetic: '/ˌɑːntrəprəˈnɜːr/',
          meaning: 'A person who starts businesses',
          category: 'Business',
          difficulty: 'advanced',
          audioUrl: '',
          context: 'Business discussions',
          examples: ['The young entrepreneur started a successful tech company.', 'Entrepreneurs often take financial risks.'],
          synonyms: ['Businessperson', 'Industrialist', 'Innovator'],
        ),
        PronunciationWord(
          word: 'Nevertheless',
          phonetic: '/ˌnevərðəˈles/',
          meaning: 'In spite of that; however',
          category: 'Connectors',
          difficulty: 'advanced',
          audioUrl: '',
          context: 'Formal writing and speech',
          examples: ['It was raining; nevertheless, we went for a walk.', 'The task was difficult; nevertheless, she completed it.'],
          synonyms: ['However', 'Nonetheless', 'Still'],
        ),
      ]
    };
  }

  // Save cached words to persistent storage
  Future<void> _saveCachedWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedMap = json.encode(_cachedWords.map((key, value) => 
        MapEntry(key, value.map((word) => word.toMap()).toList())
      ));
      await prefs.setString('cachedPronunciationWords', encodedMap);
    } catch (e) {
      debugPrint('Error saving cached words: $e');
    }
  }

  // Get current pronunciation word
  PronunciationWord getCurrentWord() {
    if (_currentWordList.isEmpty) return _getFallbackWord();
    return _currentWordList[_currentWordIndex % _currentWordList.length];
  }

  // Get all words for current level
  List<PronunciationWord> getWordsForLevel(String level) {
    return _cachedWords[level] ?? _getFallbackWords()[level] ?? [];
  }

  // Set current difficulty level
  Future<void> setDifficultyLevel(String level) async {
    if (level != _currentLevel) {
      _currentLevel = level;
      _currentWordIndex = 0;
      _pronunciationScore = 0.0;
      
      // Load words for the new level
      await _loadWordsForLevel(level);
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pronunciationLevel', level);
      
      notifyListeners();
    }
  }

  // Search for new words
  Future<void> searchWord(String word) async {
    if (word.trim().isEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      PronunciationWord? newWord = await _fetchWordFromAPI(word.trim());
      if (newWord != null) {
        // Add to current list and cache
        _currentWordList.add(newWord);
        if (!_cachedWords.containsKey(_currentLevel)) {
          _cachedWords[_currentLevel] = [];
        }
        _cachedWords[_currentLevel]!.add(newWord);
        await _saveCachedWords();
        
        _currentWordIndex = _currentWordList.length - 1;
        _errorMessage = '';
        
        // Speak confirmation
        await _speakFeedback('Added $word to your practice list');
      } else {
        _errorMessage = 'Word not found in dictionary';
        await _speakFeedback('Word $word not found. Please try another word.');
      }
    } catch (e) {
      _errorMessage = 'Error searching for word: ${e.toString()}';
      await _speakFeedback('Error searching for word. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Voice search method with proper error handling and TTS delay
Future<void> startVoiceSearch() async {
  try {
    if (_isListening) {
      await stopVoiceSearch();
      return;
    }

    // Stop any ongoing TTS first
    await _tts.stop();
    _isPlaying = false;

    // Re-initialize speech recognition to ensure it's ready
    bool available = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        notifyListeners();
      },
      onError: (errorNotification) {
        debugPrint('Speech recognition error: $errorNotification');
        _isListening = false;
        _errorMessage = 'Speech recognition error';
        notifyListeners();
      },
    );

    if (!available) {
      _errorMessage = 'Speech recognition not available';
      notifyListeners();
      await _speakFeedback('Speech recognition not available');
      return;
    }

    _isListening = true;
    _lastSpokenText = '';
    notifyListeners();

    // Wait a moment before starting to listen to avoid picking up TTS
    await Future.delayed(const Duration(milliseconds: 1000));

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _lastSpokenText = result.recognizedWords.trim().toLowerCase();
          debugPrint('Voice search result: $_lastSpokenText');
          
          // Filter out common false positives
          if (_isFalsePositive(_lastSpokenText)) {
            debugPrint('Ignoring false positive: $_lastSpokenText');
            _lastSpokenText = '';
            _isListening = false;
            notifyListeners();
            return;
          }
          
          // Process the result after a short delay
          if (_lastSpokenText.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _processVoiceSearch(_lastSpokenText);
            });
          }
        } else {
          // Update with partial results for real-time feedback
          _lastSpokenText = result.recognizedWords;
          notifyListeners();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en-US',
      onSoundLevelChange: (level) {
        // Optional: Add sound level feedback
        debugPrint('Sound level: $level');
      },
    );

    // Don't speak feedback that might be picked up by the microphone
    // Instead, use visual feedback only
    debugPrint('Voice search started - listening for input');

  } catch (e) {
    debugPrint('Error starting voice search: $e');
    _errorMessage = 'Error starting voice search: ${e.toString()}';
    _isListening = false;
    notifyListeners();
  }
}

// Add this method to filter out false positives
bool _isFalsePositive(String text) {
  final falsePositives = [
    'listening',
    'listening say a word to search',
    'say a word to search',
    'search',
    'word',
    'mic',
    'microphone',
    'voice',
    'speech'
  ];
  
  return falsePositives.contains(text.toLowerCase());
}

  // Process voice search result with better error handling
Future<void> _processVoiceSearch(String spokenText) async {
  try {
    // Check for false positives first
    if (_isFalsePositive(spokenText)) {
      debugPrint('Ignoring false positive voice input: $spokenText');
      _isListening = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Extract the word
    String extractedWord = _extractWordFromSpeech(spokenText);
    
    if (extractedWord.isNotEmpty && extractedWord.length > 1 && !_isFalsePositive(extractedWord)) {
      debugPrint('Processing voice search for: $extractedWord');
      await _speakFeedback('Searching for $extractedWord');
      
      // Call the search method
      await searchWord(extractedWord);
      
      // Auto-play the word after a short delay if search was successful
      if (_errorMessage.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        await playWordAudio();
      }
    } else {
      _errorMessage = 'No valid word detected. Please try again.';
      _isListening = false;
      notifyListeners();
      await _speakFeedback('No word detected. Please say a complete word like "water" or "hello"');
    }
    
  } catch (e) {
    debugPrint('Error processing voice search: $e');
    _errorMessage = 'Error processing voice search: ${e.toString()}';
    _isListening = false;
    notifyListeners();
    await _speakFeedback('Error processing your request. Please try again.');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // Extract word from speech with better filtering
String _extractWordFromSpeech(String speech) {
  if (speech.isEmpty) return '';
  
  List<String> words = speech.split(' ');
  
  // Filter out common command words and very short words
  List<String> filteredWords = words.where((word) {
    String cleanWord = word.trim().toLowerCase();
    return cleanWord.length > 1 && 
           !['search', 'find', 'look', 'for', 'the', 'a', 'an', 'please', 'word', '']
            .contains(cleanWord);
  }).toList();
  
  // Return the first valid word or the original speech if no filtering occurred
  return filteredWords.isNotEmpty ? filteredWords.first : 
         words.isNotEmpty ? words.first : speech;
}

  // Check if speech recognition is available
Future<bool> isSpeechAvailable() async {
  try {
    return await _speech.initialize(
      onError: (error) => debugPrint('Speech check error: $error')
    );
  } catch (e) {
    debugPrint('Error checking speech availability: $e');
    return false;
  }
}

  // Speak feedback to user
  Future<void> _speakFeedback(String message) async {
    try {
      await _tts.setSpeechRate(0.8);
      await _tts.speak(message);
    } catch (e) {
      debugPrint('Error speaking feedback: $e');
    }
  }

  // Stop voice search with proper cleanup
Future<void> stopVoiceSearch() async {
  try {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      await _speakFeedback('Stopped listening');
    }
  } catch (e) {
    debugPrint('Error stopping voice search: $e');
    _isListening = false;
    notifyListeners();
  }
}

  // Move to next word
  void nextWord() {
    if (_currentWordList.isNotEmpty) {
      _currentWordIndex = (_currentWordIndex + 1) % _currentWordList.length;
      _pronunciationScore = 0.0;
      notifyListeners();
    }
  }

  // Move to previous word
  void previousWord() {
    if (_currentWordList.isNotEmpty) {
      _currentWordIndex = (_currentWordIndex - 1) % _currentWordList.length;
      if (_currentWordIndex < 0) _currentWordIndex = _currentWordList.length - 1;
      _pronunciationScore = 0.0;
      notifyListeners();
    }
  }

  // playWordAudio method
  Future<void> playWordAudio() async {
    try {
      // If already playing, stop it
      if (_isPlaying) {
        await _tts.stop();
        _isPlaying = false;
        notifyListeners();
        return;
      }
      
      final currentWord = getCurrentWord();
      
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(true);
      
      _isPlaying = true;
      notifyListeners();
      
      // Speak the word clearly
      await _tts.speak(currentWord.word);
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Speak the meaning
      await _tts.speak("Meaning: ${currentWord.meaning}");
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Speak examples if available
      if (currentWord.examples.isNotEmpty) {
        await _tts.speak("Example: ${currentWord.examples[0]}");
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Speak phonetic transcription if audio context is enabled
      if (_audioContextEnabled) {
        await _tts.speak("Phonetic: ${currentWord.phonetic}");
        await Future.delayed(const Duration(milliseconds: 300));
        await _tts.speak("Context: ${currentWord.context}");
        
        // Speak synonyms if available
        if (currentWord.synonyms.isNotEmpty) {
          await _tts.speak("Similar words: ${currentWord.synonyms.take(3).join(', ')}");
        }
      }
      
      _isPlaying = false;
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error playing word audio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopAudio() async {
    try {
      await _tts.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // Add method to change speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate;
    notifyListeners();
    _speakFeedback('Speed set to ${rate}x');
  }

  // Toggle recording state
  void toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  // Start recording with real-time feedback
  Future<void> _startRecording() async {
    try {
      // For web, use a simulated recording
      if (kIsWeb) {
        _simulateWebRecording();
        return;
      }

      if (await _audioRecorder.isRecording()) {
        await _stopRecording();
        return;
      }
      
      // Create a temporary file path for recording
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/pronunciation_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: tempPath,
      );
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      
      // Start timer for recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  // Simulate recording for web
  void _simulateWebRecording() {
    _isRecording = true;
    _recordingDuration = Duration.zero;
    
    // Simulate amplitude changes - FIXED TYPE INFERENCE
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final int millisecond = DateTime.now().millisecond;
      _amplitudeLevel = 0.3 + (millisecond % 700) / 1000.0;
      notifyListeners();
    });
    
    // Timer for recording duration
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _recordingDuration += const Duration(seconds: 1);
      notifyListeners();
    });
    
    notifyListeners();
  }

  // Stop recording and analyze pronunciation
  Future<void> _stopRecording() async {
    try {
      if (_recordingTimer != null) {
        _recordingTimer!.cancel();
        _recordingTimer = null;
      }
      
      // For web, just simulate the analysis
      if (kIsWeb) {
        _isRecording = false;
        await _analyzeRecording("");
        return;
      }

      if (await _audioRecorder.isRecording()) {
        // Stop recording
        final path = await _audioRecorder.stop();
        
        if (path != null) {
          // Analyze the recording
          await _analyzeRecording(path);
        }
      }
      
      _isRecording = false;
      _recordingDuration = Duration.zero;
      _amplitudeLevel = 0.0;
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  // Simulated pronunciation analysis with Firebase integration
Future<void> _analyzeRecording(String audioPath) async {
  try {
    final currentWord = getCurrentWord();
    
    // Simulate analysis process with delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Realistic scoring algorithm
    const baseScore = 60.0;
    final wordComplexity = _getWordComplexity(currentWord.word);
    final randomVariation = (DateTime.now().millisecond % 40) - 20;
    
    // Calculate final score (0-100)
    _pronunciationScore = (baseScore + 
        (wordComplexity * 15) +
        randomVariation).clamp(0.0, 100.0);
    
    // Save to Firebase
    await FirebaseService.savePronunciationPractice(
      currentWord.word, 
      _pronunciationScore, 
      currentWord.phonetic, 
      currentWord.meaning
    );
    
    // Update user progress
    _updateUserProgress(_pronunciationScore);
    
    debugPrint('Pronunciation practice completed: ${currentWord.word}, Score: $_pronunciationScore');
    
    // Speak the score
    if (_pronunciationScore >= 80) {
      await _speakFeedback('Excellent! Your pronunciation score is ${_pronunciationScore.round()} percent');
    } else if (_pronunciationScore >= 60) {
      await _speakFeedback('Good job! Your score is ${_pronunciationScore.round()} percent');
    } else {
      await _speakFeedback('Your pronunciation score is ${_pronunciationScore.round()} percent. Keep practicing!');
    }
    
    notifyListeners();
    
  } catch (e) {
    debugPrint('Error analyzing recording: $e');
    _pronunciationScore = 0.0;
    notifyListeners();
  }
}

  // Helper method to determine word complexity
  double _getWordComplexity(String word) {
    final length = word.length;
    final syllableCount = _countSyllables(word);
    return (length * 0.3 + syllableCount * 0.7) / 10;
  }

  // Helper method to count syllables (approximate)
  int _countSyllables(String word) {
    word = word.toLowerCase();
    if (word.length <= 3) return 1;
    
    final vowels = ['a', 'e', 'i', 'o', 'u', 'y'];
    int count = 0;
    bool previousWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      if (vowels.contains(word[i])) {
        if (!previousWasVowel) count++;
        previousWasVowel = true;
      } else {
        previousWasVowel = false;
      }
    }
    
    return count > 0 ? count : 1;
  }

  // Toggle audio context
  void toggleAudioContext(bool value) {
    _audioContextEnabled = value;
    notifyListeners();
  }

  // Update user progress with new pronunciation score
  void _updateUserProgress(double score) {
    if (_userProgress != null) {
      // Update pronunciation stats
      final currentAccuracy = _userProgress!.pronunciation['accuracy'] ?? 0;
      final totalPractice = _userProgress!.pronunciation['totalPractice'] ?? 0;
      
      // Calculate new average accuracy
      final newAccuracy = ((currentAccuracy * totalPractice) + score) / (totalPractice + 1);
      
      _userProgress!.pronunciation['accuracy'] = newAccuracy.round();
      _userProgress!.pronunciation['totalPractice'] = totalPractice + 1;
      _userProgress!.pronunciation['lastPractice'] = DateTime.now().millisecondsSinceEpoch;
      
      // Save updated progress
      _saveUserProgress();
    }
  }

  // Save user progress to persistent storage
  Future<void> _saveUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userProgress != null) {
        await prefs.setString('userProgress', json.encode(_userProgress!.toMap()));
      }
    } catch (e) {
      debugPrint('Error saving user progress: $e');
    }
  }

  // Initialize TTS engine
  Future<void> initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Clean up TTS resources
  void disposeTts() {
    _tts.stop();
    _isPlaying = false;
    _speech.stop();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _recordingTimer?.cancel();
    if (!kIsWeb) {
      _audioRecorder.dispose();
    }
    _audioPlayer.dispose();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Refresh current word list
  Future<void> refreshWords() async {
    await _loadWordsForLevel(_currentLevel);
  }

  // Get word by index
  PronunciationWord getWordByIndex(int index) {
    if (_currentWordList.isEmpty) return _getFallbackWord();
    return _currentWordList[index % _currentWordList.length];
  }

  // Set current word by index
  void setCurrentWordIndex(int index) {
    if (_currentWordList.isNotEmpty) {
      _currentWordIndex = index % _currentWordList.length;
      _pronunciationScore = 0.0;
      notifyListeners();
    }
  }

  // Fallback word if no words are available
  PronunciationWord _getFallbackWord() {
    return PronunciationWord(
      word: 'Hello',
      phonetic: '/həˈloʊ/',
      meaning: 'A greeting',
      category: 'Greetings',
      difficulty: 'beginner',
      audioUrl: '',
      context: 'Basic greeting',
      examples: ['Hello, how are you?', 'She waved and said hello.'],
      synonyms: ['Hi', 'Greetings'],
    );
  }

  // Add these properties for progress tracking
  int _wordsPracticed = 0;
  double _averagePronunciationScore = 0.0;
  double _bestPronunciationScore = 0.0;

  // Add getters for these properties
  int get wordsPracticed => _wordsPracticed;
  double get averagePronunciationScore => _averagePronunciationScore;
  double get bestPronunciationScore => _bestPronunciationScore;
}

// PronunciationWord class
class PronunciationWord {
  final String word;
  final String phonetic;
  final String meaning;
  final String category;
  final String difficulty;
  final String audioUrl;
  final String context;
  final List<String> examples;
  final List<String> synonyms;

  PronunciationWord({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.category,
    required this.difficulty,
    required this.audioUrl,
    required this.context,
    this.examples = const [],
    this.synonyms = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'category': category,
      'difficulty': difficulty,
      'audioUrl': audioUrl,
      'context': context,
      'examples': examples,
      'synonyms': synonyms,
    };
  }

  static PronunciationWord fromMap(Map<String, dynamic> map) {
    return PronunciationWord(
      word: map['word'],
      phonetic: map['phonetic'],
      meaning: map['meaning'],
      category: map['category'],
      difficulty: map['difficulty'],
      audioUrl: map['audioUrl'],
      context: map['context'],
      examples: List<String>.from(map['examples'] ?? []),
      synonyms: List<String>.from(map['synonyms'] ?? []),
    );
  }
}

// UserModel and ProgressModel classes
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
    );
  }
}

class ProgressModel {
  final Map<String, dynamic> pronunciation;

  ProgressModel({required this.pronunciation});

  Map<String, dynamic> toMap() {
    return {
      'pronunciation': pronunciation,
    };
  }

  static ProgressModel fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      pronunciation: Map<String, dynamic>.from(map['pronunciation'] ?? {}),
    );
  }
}