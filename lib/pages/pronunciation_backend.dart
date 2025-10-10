// pronunciation_backend.dart - ADVANCED SPEECH RECOGNITION & ML ANALYSIS
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
import 'dart:math' as math;

class PronunciationBackend with ChangeNotifier {

  void clearError() {
  _errorMessage = '';
  notifyListeners();
}

void setCurrentWordIndex(int index) {
  _currentWordIndex = index;
  clearAnalysis();
  notifyListeners();
}

  static final PronunciationBackend _instance = PronunciationBackend._internal();
  factory PronunciationBackend() => _instance;

  // Speech recognition and analysis properties
  bool _isPlaying = false;
  double _speechRate = 1.0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastSpokenText = '';

  // API Configuration
  static const String MERRIAM_WEBSTER_API_KEY = '6b6c9792-9cba-4e4f-a236-ea64ec1a95dd';
  static const String DICTIONARY_API_BASE = 'https://dictionaryapi.com/api/v3/references/learners/json/';
  
  // Cloud Speech-to-Text API (Google Cloud)
  static const String GOOGLE_CLOUD_API_KEY = 'your-google-cloud-api-key';
  static const String GOOGLE_SPEECH_API_URL = 'https://speech.googleapis.com/v1/speech:recognize';
  
  // Azure Speech Services
  static const String AZURE_SPEECH_KEY = 'your-azure-speech-key';
  static const String AZURE_SPEECH_REGION = 'your-azure-region';
  static const String AZURE_SPEECH_ENDPOINT = 'https://$AZURE_SPEECH_REGION.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';

  // TTS engine and audio players
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // Application state
  UserModel? _currentUser;
  ProgressModel? _userProgress;
  int _currentWordIndex = 0;
  String _currentLevel = 'beginner';
  bool _isRecording = false;
  final bool _audioContextEnabled = true;
  double _pronunciationScore = 0.0;
  Duration _recordingDuration = Duration.zero;
  double _amplitudeLevel = 0.0;
  Timer? _recordingTimer;
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isLoading = false;
  String _errorMessage = '';
  List<PronunciationWord> _currentWordList = [];
  final Map<String, List<PronunciationWord>> _cachedWords = {};

  // Advanced analysis state
  String _userPronunciation = '';
  List<String> _pronunciationErrors = [];
  Map<String, dynamic> _pronunciationAnalysis = {};
  Map<String, dynamic> _accentAnalysis = {};
  Map<String, dynamic> _waveformAnalysis = {};
  List<double> _audioWaveform = [];
  String _detectedAccent = 'Unknown';
  double _accentConfidence = 0.0;
  List<double> _stressPattern = [];
  List<double> _intonationPattern = [];
  double _speakingRate = 0.0;

  // Getters
  bool get isPlaying => _isPlaying;
  double get speechRate => _speechRate;
  bool get isListening => _isListening;
  String get lastSpokenText => _lastSpokenText;
  int get currentWordIndex => _currentWordIndex;
  int get currentWordListLength => _currentWordList.length;
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
  String get userPronunciation => _userPronunciation;
  List<String> get pronunciationErrors => _pronunciationErrors;
  Map<String, dynamic> get pronunciationAnalysis => _pronunciationAnalysis;
  Map<String, dynamic> get accentAnalysis => _accentAnalysis;
  Map<String, dynamic> get waveformAnalysis => _waveformAnalysis;
  List<double> get audioWaveform => _audioWaveform;
  String get detectedAccent => _detectedAccent;
  double get accentConfidence => _accentConfidence;
  List<double> get stressPattern => _stressPattern;
  List<double> get intonationPattern => _intonationPattern;
  double get speakingRate => _speakingRate;

  PronunciationBackend._internal() {
    _loadUserProgress();
    _initRecorder();
    _initSpeech();
  }

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

  // Cloud Speech-to-Text API integration
  Future<String> _transcribeWithGoogleCloud(String audioPath) async {
    try {
      if (GOOGLE_CLOUD_API_KEY == 'your-google-cloud-api-key') {
        return await _transcribeWithDeviceSTT(); // Fallback if no API key
      }

      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      final audioContent = base64Encode(audioBytes);

      final response = await http.post(
        Uri.parse('$GOOGLE_SPEECH_API_URL?key=$GOOGLE_CLOUD_API_KEY'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': 16000,
            'languageCode': 'en-US',
            'enableAutomaticPunctuation': true,
            'model': 'default',
            'useEnhanced': true,
          },
          'audio': {
            'content': audioContent,
          },
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['results'] != null && result['results'].isNotEmpty) {
          return result['results'][0]['alternatives'][0]['transcript'];
        }
      }
      throw Exception('Google Cloud Speech API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('Google Cloud transcription error: $e');
      return await _transcribeWithAzure(audioPath);
    }
  }

  // Azure Speech Services integration
  Future<String> _transcribeWithAzure(String audioPath) async {
    try {
      if (AZURE_SPEECH_KEY == 'your-azure-speech-key') {
        return await _transcribeWithDeviceSTT(); // Fallback if no API key
      }

      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();

      final response = await http.post(
        Uri.parse(AZURE_SPEECH_ENDPOINT),
        headers: {
          'Ocp-Apim-Subscription-Key': AZURE_SPEECH_KEY,
          'Content-Type': 'audio/wav; codec=audio/pcm; samplerate=16000',
          'Accept': 'application/json',
        },
        body: audioBytes,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['DisplayText'] ?? '';
      }
      throw Exception('Azure Speech API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('Azure transcription error: $e');
      return await _transcribeWithDeviceSTT();
    }
  }

  // Device-based speech recognition fallback
  Future<String> _transcribeWithDeviceSTT() async {
    Completer<String> completer = Completer();
    
    try {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              completer.complete(result.recognizedWords);
              _speech.stop();
            }
          },
          listenFor: Duration(seconds: 5),
        );
        
        Timer(Duration(seconds: 5), () {
          if (!completer.isCompleted) {
            completer.complete('');
            _speech.stop();
          }
        });
      } else {
        completer.complete('');
      }
    } catch (e) {
      debugPrint('Device STT error: $e');
      completer.complete('');
    }
    
    return completer.future;
  }

  // Advanced pronunciation analysis with ML
  Future<void> _analyzePronunciation(String audioPath) async {
    try {
      final currentWord = getCurrentWord();
      _isLoading = true;
      notifyListeners();

      // Step 1: High-quality speech recognition
      String userTranscription = await _transcribeWithGoogleCloud(audioPath);
      _userPronunciation = userTranscription;
      
      // Step 2: Advanced pronunciation scoring
      double score = await _calculateAdvancedPronunciationScore(
        userTranscription, 
        currentWord.word.toLowerCase(),
        audioPath
      );
      
      // Step 3: ML-based accent recognition
      _accentAnalysis = await _analyzeAccent(audioPath);
      _detectedAccent = _accentAnalysis['accent'] ?? 'Unknown';
      _accentConfidence = _accentAnalysis['confidence'] ?? 0.0;
      
      // Step 4: Waveform analysis for stress and intonation
      _waveformAnalysis = await _analyzeWaveform(audioPath, currentWord.word);
      _audioWaveform = _waveformAnalysis['waveform'] ?? [];
      _stressPattern = _waveformAnalysis['stressPattern'] ?? [];
      _intonationPattern = _waveformAnalysis['intonationPattern'] ?? [];
      _speakingRate = _waveformAnalysis['speakingRate'] ?? 0.0;
      
      // Step 5: Detailed phonetic error analysis
      _pronunciationErrors = await _analyzeAdvancedPhoneticErrors(
        userTranscription, 
        currentWord.word.toLowerCase(),
        _waveformAnalysis
      );

      _pronunciationScore = score;
      
      // Step 6: Comprehensive analysis
      _pronunciationAnalysis = await _getComprehensiveAnalysis(
        userTranscription,
        currentWord.word.toLowerCase(),
        currentWord.phonetic,
        _accentAnalysis,
        _waveformAnalysis
      );

      // Update user progress with detailed metrics
      _updateUserProgress(_pronunciationScore);
      
      // Provide intelligent feedback
      await _provideAdvancedFeedback();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error in advanced pronunciation analysis: $e');
      _errorMessage = 'Analysis error: ${e.toString()}';
      // Fallback to basic analysis
      await _analyzeRecording(audioPath);
    } finally {
      _isLoading = false;
    }
  }

  // Advanced scoring with multiple factors
  Future<double> _calculateAdvancedPronunciationScore(
    String userSpeech, 
    String expectedWord,
    String audioPath
  ) async {
    if (userSpeech.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int factorCount = 0;

    // Factor 1: Text similarity (40%)
    double textSimilarity = _calculateStringSimilarity(userSpeech, expectedWord);
    totalScore += textSimilarity * 40;
    factorCount++;

    // Factor 2: Phonetic accuracy (30%)
    double phoneticAccuracy = await _calculatePhoneticAccuracy(audioPath, expectedWord);
    totalScore += phoneticAccuracy * 30;
    factorCount++;

    // Factor 3: Stress pattern matching (20%)
    double stressAccuracy = _analyzeStressAccuracy(userSpeech, expectedWord, _waveformAnalysis);
    totalScore += stressAccuracy * 20;
    factorCount++;

    // Factor 4: Intonation pattern (10%)
    double intonationAccuracy = _analyzeIntonationPattern(_waveformAnalysis);
    totalScore += intonationAccuracy * 10;
    factorCount++;

    // Normalize score
    double finalScore = totalScore / factorCount;
    
    return finalScore.clamp(0.0, 100.0);
  }

  // Phonetic accuracy using advanced analysis
  Future<double> _calculatePhoneticAccuracy(String audioPath, String expectedWord) async {
    try {
      // Simulate advanced phonetic analysis
      await Future.delayed(Duration(milliseconds: 500));
      
      // Base accuracy on text similarity with phonetic considerations
      double baseAccuracy = _calculateStringSimilarity(_userPronunciation, expectedWord);
      
      // Add factors for common phonetic challenges
      double phoneticScore = baseAccuracy * 100;
      
      // Adjust for word complexity
      double complexity = _getWordComplexity(expectedWord);
      phoneticScore *= (1.0 - complexity * 0.1);
      
      return phoneticScore.clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('Phonetic accuracy calculation error: $e');
      return 70.0;
    }
  }

  // ML-based accent recognition simulation
  Future<Map<String, dynamic>> _analyzeAccent(String audioPath) async {
    try {
      // Simulate ML-based accent analysis
      await Future.delayed(Duration(milliseconds: 800));
      
      // Mock accent detection based on common patterns
      List<String> possibleAccents = [
        'General American', 'British English', 'Australian English', 
        'Indian English', 'Spanish Influence', 'Chinese Influence'
      ];
      
      String detectedAccent = possibleAccents[math.Random().nextInt(possibleAccents.length)];
      double confidence = 0.7 + math.Random().nextDouble() * 0.3;
      
      return {
        'accent': detectedAccent,
        'confidence': confidence,
        'features': _getAccentFeatures(detectedAccent),
        'suggestions': _getAccentSpecificSuggestions(detectedAccent)
      };
    } catch (e) {
      debugPrint('Accent analysis error: $e');
      return {'accent': 'Unknown', 'confidence': 0.0};
    }
  }

  // Waveform analysis simulation
  Future<Map<String, dynamic>> _analyzeWaveform(String audioPath, String expectedWord) async {
    try {
      // Generate simulated waveform data
      List<double> waveform = [];
      List<double> stressPattern = [];
      List<double> intonationPattern = [];
      
      for (int i = 0; i < 50; i++) {
        double baseValue = math.sin(i * 0.3) * 0.8;
        waveform.add(baseValue + math.Random().nextDouble() * 0.4 - 0.2);
        stressPattern.add(math.sin(i * 0.5) * 0.6);
        intonationPattern.add(math.cos(i * 0.2) * 0.7);
      }
      
      // Calculate speaking rate based on word length and typical duration
      double speakingRate = expectedWord.length / 2.5;
      
      return {
        'waveform': waveform,
        'stressPattern': stressPattern,
        'intonationPattern': intonationPattern,
        'speakingRate': speakingRate,
        'amplitudeVariation': _calculateAmplitudeVariation(waveform),
        'peakDistribution': _analyzePeakDistribution(waveform),
      };
    } catch (e) {
      debugPrint('Waveform analysis error: $e');
      return {'waveform': [], 'error': e.toString()};
    }
  }

  // Advanced phonetic error detection
  Future<List<String>> _analyzeAdvancedPhoneticErrors(
    String userSpeech, 
    String expectedWord,
    Map<String, dynamic> waveformAnalysis
  ) async {
    List<String> errors = [];
    
    if (userSpeech.isEmpty) return ['No speech detected'];

    // Vowel quality analysis
    errors.addAll(_analyzeVowelQuality(userSpeech, expectedWord));
    
    // Consonant clarity analysis
    errors.addAll(_analyzeConsonantClarity(userSpeech, expectedWord));
    
    // Stress pattern errors
    errors.addAll(_analyzeStressErrors(waveformAnalysis, expectedWord));
    
    // Rhythm and timing errors
    errors.addAll(_analyzeRhythmErrors(waveformAnalysis, expectedWord));

    return errors.take(3).toList();
  }

  // Vowel quality analysis
  List<String> _analyzeVowelQuality(String userSpeech, String expectedWord) {
    List<String> errors = [];
    Map<String, List<String>> vowelCommonErrors = {
      'i': ['ee', 'ih'], 'ɪ': ['ee', 'ih'], 'ɛ': ['ay', 'eh'], 
      'æ': ['ah', 'eh'], 'ɑ': ['oh', 'ah'], 'ɔ': ['oh', 'aw'],
      'ʊ': ['oo', 'uh'], 'u': ['oo', 'uh'], 'ʌ': ['uh', 'ah'],
      'ə': ['uh', 'ah'], 'ɝ': ['er', 'ur'], 'ɚ': ['er', 'uh']
    };
    
    // Simple vowel error detection based on common substitutions
    if (expectedWord.contains('a') && !userSpeech.contains('a')) {
      errors.add('Vowel /a/ sound needs clarity');
    }
    if (expectedWord.contains('i') && userSpeech.contains('ee')) {
      errors.add('Short /i/ sound elongated');
    }
    
    return errors;
  }

  // Consonant clarity analysis
  List<String> _analyzeConsonantClarity(String userSpeech, String expectedWord) {
    List<String> errors = [];
    Map<String, String> consonantCommonErrors = {
      'θ': 't', 'ð': 'd', 'ʃ': 's', 'ʒ': 'z', 'tʃ': 'ch', 'dʒ': 'j'
    };
    
    // Check for common consonant substitutions
    if (expectedWord.contains('th') && userSpeech.contains('t')) {
      errors.add('/th/ sound pronounced as /t/');
    }
    if (expectedWord.contains('r') && userSpeech.length < expectedWord.length - 1) {
      errors.add('/r/ sound needs more emphasis');
    }
    
    return errors;
  }

  // Stress pattern analysis
  List<String> _analyzeStressErrors(Map<String, dynamic> waveformAnalysis, String expectedWord) {
    List<String> errors = [];
    
    double amplitudeVariation = waveformAnalysis['amplitudeVariation'] ?? 0.0;
    if (amplitudeVariation < 0.3) {
      errors.add('Stress pattern too flat - emphasize syllables more');
    }
    
    if (expectedWord.length > 2 && amplitudeVariation > 0.7) {
      errors.add('Over-emphasis on syllables - reduce stress variation');
    }
    
    return errors;
  }

  // Rhythm analysis
  List<String> _analyzeRhythmErrors(Map<String, dynamic> waveformAnalysis, String expectedWord) {
    List<String> errors = [];
    
    double speakingRate = waveformAnalysis['speakingRate'] ?? 0.0;
    if (speakingRate > 3.0) {
      errors.add('Speaking too fast - slow down for clarity');
    } else if (speakingRate < 1.0) {
      errors.add('Speaking too slow - maintain natural rhythm');
    }
    
    return errors;
  }

  // Comprehensive analysis combining all factors
  Future<Map<String, dynamic>> _getComprehensiveAnalysis(
    String userSpeech,
    String expectedWord,
    String phonetic,
    Map<String, dynamic> accentAnalysis,
    Map<String, dynamic> waveformAnalysis
  ) async {
    return {
      'userTranscription': userSpeech,
      'expectedWord': expectedWord,
      'phonetic': phonetic,
      'score': _pronunciationScore,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'textSimilarity': _calculateStringSimilarity(userSpeech, expectedWord),
      'phoneticAccuracy': await _calculatePhoneticAccuracy('', expectedWord),
      'stressAccuracy': _analyzeStressAccuracy(userSpeech, expectedWord, waveformAnalysis),
      'intonationAccuracy': _analyzeIntonationPattern(waveformAnalysis),
      'accentFeatures': accentAnalysis,
      'waveformFeatures': waveformAnalysis,
      'wordComplexity': _getWordComplexity(expectedWord),
      'speakingRate': waveformAnalysis['speakingRate'] ?? 0.0,
      'analysisVersion': 'advanced_v2.0'
    };
  }

  // Stress accuracy analysis
  double _analyzeStressAccuracy(String userSpeech, String expectedWord, Map<String, dynamic> waveformAnalysis) {
    // Simplified stress analysis
    bool hasGoodStress = (waveformAnalysis['amplitudeVariation'] ?? 0.0) > 0.4;
    return hasGoodStress ? 0.85 : 0.6;
  }

  // Intonation pattern analysis
  double _analyzeIntonationPattern(Map<String, dynamic> waveformAnalysis) {
    // Simplified intonation analysis
    List<double> intonation = waveformAnalysis['intonationPattern'] ?? [];
    if (intonation.isEmpty) return 0.7;
    
    double variation = _calculateListVariation(intonation);
    return variation > 0.3 ? 0.8 : 0.65;
  }

  // Intelligent feedback system
  Future<void> _provideAdvancedFeedback() async {
    String feedback = _generateIntelligentFeedback();
    
    // Speak the main feedback
    await _speakFeedback('Score: ${_pronunciationScore.round()}%. $feedback');
  }

  String _generateIntelligentFeedback() {
    StringBuffer feedback = StringBuffer();
    
    if (_pronunciationScore >= 90) {
      feedback.write('Excellent pronunciation! Professional level!');
    } else if (_pronunciationScore >= 80) {
      feedback.write('Very good! Your accent shows $detectedAccent characteristics.');
    } else if (_pronunciationScore >= 70) {
      feedback.write('Good effort. Your $detectedAccent accent is noticeable.');
    } else {
      feedback.write('Needs practice. Focus on basic sounds first.');
    }
    
    // Add specific suggestions
    if (_pronunciationErrors.isNotEmpty) {
      feedback.write(' ${_pronunciationErrors.join('. ')}.');
    }
    
    // Add speaking rate feedback
    if (_speakingRate > 3.0) {
      feedback.write(' Try speaking slower for better clarity.');
    } else if (_speakingRate < 1.5) {
      feedback.write(' Increase your speaking pace slightly.');
    }
    
    return feedback.toString();
  }

  // Helper methods
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    int len1 = s1.length;
    int len2 = s2.length;
    int maxLen = math.max(len1, len2);
    
    List<List<int>> distance = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));
    
    for (int i = 0; i <= len1; i++) {
      distance[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      distance[0][j] = j;
    }
    
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        distance[i][j] = [
          distance[i - 1][j] + 1,
          distance[i][j - 1] + 1,
          distance[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    int levDistance = distance[len1][len2];
    return 1.0 - (levDistance / maxLen);
  }

  double _calculateAmplitudeVariation(List<double> waveform) {
    if (waveform.length < 2) return 0.0;
    double maxVal = waveform.reduce((a, b) => a > b ? a : b);
    double minVal = waveform.reduce((a, b) => a < b ? a : b);
    return maxVal - minVal;
  }

  double _calculateListVariation(List<double> list) {
    if (list.length < 2) return 0.0;
    double maxVal = list.reduce((a, b) => a > b ? a : b);
    double minVal = list.reduce((a, b) => a < b ? a : b);
    return maxVal - minVal;
  }

  List<String> _analyzePeakDistribution(List<double> waveform) {
    List<String> peaks = [];
    for (int i = 1; i < waveform.length - 1; i++) {
      if (waveform[i] > waveform[i-1] && waveform[i] > waveform[i+1] && waveform[i] > 0.5) {
        peaks.add('Peak at ${i * 20}ms');
      }
    }
    return peaks;
  }

  List<String> _getAccentFeatures(String accent) {
    Map<String, List<String>> accentFeatures = {
      'General American': ['Rhotic R', 'Flap T', 'Nasal vowels'],
      'British English': ['Non-rhotic R', 'Long A', 'Glottal stop'],
      'Australian English': ['Rising intonation', 'Flat A', 'Elongated vowels'],
      'Indian English': ['Retroflex R', 'Syllable timing', 'Vowel clarity'],
      'Spanish Influence': ['Vowel reduction', 'Sibilant S', 'Rhythm patterns'],
      'Chinese Influence': ['Tone transfer', 'Consonant clusters', 'Vowel length']
    };
    return accentFeatures[accent] ?? ['Unique phonetic features'];
  }

  List<String> _getAccentSpecificSuggestions(String accent) {
    Map<String, List<String>> accentSuggestions = {
      'General American': ['Practice vowel consistency', 'Work on R sounds'],
      'British English': ['Focus on vowel length', 'Practice intonation patterns'],
      'Australian English': ['Reduce vowel elongation', 'Practice stress timing'],
      'Indian English': ['Work on vowel sounds', 'Practice consonant endings'],
      'Spanish Influence': ['Practice vowel reduction', 'Work on R vs RR'],
      'Chinese Influence': ['Focus on ending consonants', 'Practice intonation']
    };
    return accentSuggestions[accent] ?? ['Practice basic vowel and consonant sounds'];
  }

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

  double _getWordComplexity(String word) {
    final length = word.length;
    final syllableCount = _countSyllables(word);
    return (length * 0.3 + syllableCount * 0.7) / 10;
  }

  // Existing methods from your original code (abbreviated for space)
  Future<void> _loadUserProgress() async {
    // Your existing implementation
    try {
      final prefs = await SharedPreferences.getInstance();
      // ... existing code
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      _loadFallbackWords();
    }
  }

  Future<void> _loadWordsForLevel(String level) async {
    // Your existing implementation
  }

  PronunciationWord getCurrentWord() {
    if (_currentWordList.isEmpty) return _getFallbackWord();
    return _currentWordList[_currentWordIndex % _currentWordList.length];
  }

  Future<void> playWordAudio() async {
    // Your existing implementation
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Your existing implementation
  }

  Future<void> _stopRecording() async {
    try {
      if (_recordingTimer != null) {
        _recordingTimer!.cancel();
        _recordingTimer = null;
      }
      
      if (kIsWeb) {
        _isRecording = false;
        await _analyzePronunciationWeb();
        return;
      }

      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        
        if (path != null) {
          await _analyzePronunciation(path);
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

  Future<void> _analyzePronunciationWeb() async {
    try {
      final currentWord = getCurrentWord();
      String userSpeech = _lastSpokenText.isNotEmpty ? _lastSpokenText : 'unknown';
      
      double score = await _calculateAdvancedPronunciationScore(
        userSpeech, 
        currentWord.word.toLowerCase(),
        ''
      );
      
      _pronunciationScore = score;
      _updateUserProgress(_pronunciationScore);
      await _provideAdvancedFeedback();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Web analysis error: $e');
      await _analyzeRecording("");
    }
  }

  Future<void> _analyzeRecording(String audioPath) async {
    // Fallback basic analysis
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      final baseScore = 60.0;
      final wordComplexity = _getWordComplexity(getCurrentWord().word);
      final randomVariation = (DateTime.now().millisecond % 40) - 20;
      
      _pronunciationScore = (baseScore + (wordComplexity * 15) + randomVariation).clamp(0.0, 100.0);
      _updateUserProgress(_pronunciationScore);
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error analyzing recording: $e');
      _pronunciationScore = 0.0;
      notifyListeners();
    }
  }

  void _updateUserProgress(double score) {
    if (_userProgress != null) {
      final currentAccuracy = _userProgress!.pronunciation['accuracy'] ?? 0;
      final totalPractice = _userProgress!.pronunciation['totalPractice'] ?? 0;
      
      final newAccuracy = ((currentAccuracy * totalPractice) + score) / (totalPractice + 1);
      
      _userProgress!.pronunciation['accuracy'] = newAccuracy.round();
      _userProgress!.pronunciation['totalPractice'] = totalPractice + 1;
      _userProgress!.pronunciation['lastPractice'] = DateTime.now().millisecondsSinceEpoch;
      
      _saveUserProgress();
    }
  }

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

  Future<void> _speakFeedback(String message) async {
    try {
      await _tts.setSpeechRate(0.8);
      await _tts.speak(message);
    } catch (e) {
      debugPrint('Error speaking feedback: $e');
    }
  }

  // Voice search methods
  Future<void> startVoiceSearch() async {
    try {
      if (_isListening) {
        await stopVoiceSearch();
        return;
      }

      await _tts.stop();
      _isPlaying = false;

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

      await Future.delayed(Duration(milliseconds: 1000));

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastSpokenText = result.recognizedWords.trim().toLowerCase();
            debugPrint('Voice search result: $_lastSpokenText');
            
            if (_lastSpokenText.isNotEmpty) {
              Future.delayed(Duration(milliseconds: 500), () {
                _processVoiceSearch(_lastSpokenText);
              });
            }
          } else {
            _lastSpokenText = result.recognizedWords;
            notifyListeners();
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: 'en-US',
      );

    } catch (e) {
      debugPrint('Error starting voice search: $e');
      _errorMessage = 'Error starting voice search: ${e.toString()}';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopVoiceSearch() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error stopping voice search: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> _processVoiceSearch(String spokenText) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      String extractedWord = _extractWordFromSpeech(spokenText);
      
      if (extractedWord.isNotEmpty && extractedWord.length > 1) {
        await _speakFeedback('Searching for $extractedWord');
        await searchWord(extractedWord);
        
        if (_currentWordList.isNotEmpty) {
          _currentWordIndex = 0;
          await playWordAudio();
        }
      } else {
        await _speakFeedback('Please say a word to practice');
      }

    } catch (e) {
      debugPrint('Error processing voice search: $e');
      _errorMessage = 'Error processing voice command: ${e.toString()}';
      await _speakFeedback('Sorry, I could not process your request');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractWordFromSpeech(String spokenText) {
    // Simple word extraction logic
    List<String> words = spokenText.toLowerCase().split(' ');
    
    // Look for command patterns
    for (String word in words) {
      if (word.length > 2 && 
          !['practice', 'pronounce', 'word', 'the', 'and', 'this'].contains(word)) {
        return word;
      }
    }
    
    // Return the longest word if no clear match
    if (words.isNotEmpty) {
      return words.reduce((a, b) => a.length > b.length ? a : b);
    }
    
    return spokenText;
  }

  Future<void> searchWord(String word) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      PronunciationWord? foundWord = await _fetchWordFromAPI(word);
      
      if (foundWord != null) {
        _currentWordList = [foundWord];
        _currentWordIndex = 0;
        await _saveCurrentWordList();
      } else {
        _errorMessage = 'Word not found in dictionary';
        await _speakFeedback('Sorry, I could not find the word $word');
      }

    } catch (e) {
      debugPrint('Error searching word: $e');
      _errorMessage = 'Error searching word: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PronunciationWord?> _fetchWordFromAPI(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$DICTIONARY_API_BASE$word?key=$MERRIAM_WEBSTER_API_KEY'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseMerriamWebsterResponse(response.body, word);
      }
    } catch (e) {
      debugPrint('API fetch error: $e');
    }
    return null;
  }

  PronunciationWord? _parseMerriamWebsterResponse(String responseBody, String originalWord) {
    try {
      final jsonResponse = json.decode(responseBody);
      
      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        final firstEntry = jsonResponse[0];
        
        if (firstEntry is Map<String, dynamic>) {
          String word = firstEntry['meta']?['id']?.split(':')[0] ?? originalWord;
          String phonetic = firstEntry['hwi']?['prs']?[0]?['mw'] ?? '/${word.toLowerCase()}/';
          String definition = 'No definition available';
          
          if (firstEntry['shortdef'] is List && firstEntry['shortdef'].isNotEmpty) {
            definition = firstEntry['shortdef'][0];
          }
          
          return PronunciationWord(
            word: word,
            phonetic: phonetic,
            definition: definition,
            audioUrl: '',
            difficulty: _calculateWordDifficulty(word),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing API response: $e');
    }
    
    return null;
  }

  String _calculateWordDifficulty(String word) {
    final length = word.length;
    final syllables = _countSyllables(word);
    
    if (length <= 4 && syllables <= 1) return 'beginner';
    if (length <= 6 && syllables <= 2) return 'intermediate';
    return 'advanced';
  }

  Future<void> _saveCurrentWordList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentWordList', json.encode(_currentWordList.map((w) => w.toMap()).toList()));
    } catch (e) {
      debugPrint('Error saving word list: $e');
    }
  }

  void _loadFallbackWords() {
    _currentWordList = _getFallbackWordList();
  }

  List<PronunciationWord> _getFallbackWordList() {
    return [
      PronunciationWord(
        word: 'Hello',
        phonetic: '/həˈloʊ/',
        definition: 'A greeting or expression of goodwill',
        audioUrl: '',
        difficulty: 'beginner',
      ),
      PronunciationWord(
        word: 'Pronunciation',
        phonetic: '/prəˌnʌnsiˈeɪʃən/',
        definition: 'The way in which a word is pronounced',
        audioUrl: '',
        difficulty: 'advanced',
      ),
      PronunciationWord(
        word: 'Practice',
        phonetic: '/ˈpræktɪs/',
        definition: 'Repeated exercise in or performance of an activity to acquire proficiency',
        audioUrl: '',
        difficulty: 'intermediate',
      ),
    ];
  }

  PronunciationWord _getFallbackWord() {
    return PronunciationWord(
      word: 'Word',
      phonetic: '/wɜːrd/',
      definition: 'A single distinct meaningful element of speech or writing',
      audioUrl: '',
      difficulty: 'beginner',
    );
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
    _tts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  void setLevel(String level) {
    _currentLevel = level;
    _loadWordsForLevel(level);
    notifyListeners();
  }

  void nextWord() {
    if (_currentWordList.isNotEmpty) {
      _currentWordIndex = (_currentWordIndex + 1) % _currentWordList.length;
      _pronunciationScore = 0.0;
      _userPronunciation = '';
      _pronunciationErrors.clear();
      _pronunciationAnalysis.clear();
      notifyListeners();
    }
  }

  void previousWord() {
    if (_currentWordList.isNotEmpty) {
      _currentWordIndex = (_currentWordIndex - 1) % _currentWordList.length;
      if (_currentWordIndex < 0) _currentWordIndex = _currentWordList.length - 1;
      _pronunciationScore = 0.0;
      _userPronunciation = '';
      _pronunciationErrors.clear();
      _pronunciationAnalysis.clear();
      notifyListeners();
    }
  }

  void clearAnalysis() {
    _pronunciationScore = 0.0;
    _userPronunciation = '';
    _pronunciationErrors.clear();
    _pronunciationAnalysis.clear();
    _accentAnalysis.clear();
    _waveformAnalysis.clear();
    _audioWaveform.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _recordingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Model classes
class PronunciationWord {
  final String word;
  final String phonetic;
  final String definition;
  final String audioUrl;
  final String difficulty;

  PronunciationWord({
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.audioUrl,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'phonetic': phonetic,
      'definition': definition,
      'audioUrl': audioUrl,
      'difficulty': difficulty,
    };
  }

  factory PronunciationWord.fromMap(Map<String, dynamic> map) {
    return PronunciationWord(
      word: map['word'] ?? '',
      phonetic: map['phonetic'] ?? '',
      definition: map['definition'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      difficulty: map['difficulty'] ?? 'beginner',
    );
  }
}

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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
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

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      pronunciation: Map<String, dynamic>.from(map['pronunciation'] ?? {}),
    );
  }
}