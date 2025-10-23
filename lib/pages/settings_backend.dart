// settings_backend.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class SettingsBackend with ChangeNotifier {
  static final SettingsBackend _instance = SettingsBackend._internal();
  factory SettingsBackend() => _instance;
  SettingsBackend._internal() {
    _loadSettings();
    _initSpeech();
  }

  // TTS engine for voice testing and accessibility
  final FlutterTts _tts = FlutterTts();
  
  // Speech recognition for voice commands
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastSpokenText = '';
  bool _voiceNavigationEnabled = true;
  
  // Navigation state
  int _currentSettingIndex = 0;
  final List<String> _settingSections = [
    'Voice Settings',
    'Microphone Settings', 
    'Accessibility Settings',
    'Learning Preferences',
    'App Preferences',
    'Help & Support',
    'Reset Settings'
  ];

  // Default settings
  final Map<String, dynamic> _settings = {
    'voiceVolume': [50],
    'voiceGender': 'female',
    'micSensitivity': [75],
    'pronunciationStrictness': 'medium',
    'extendedAudioDescriptions': false,
    'screenReaderMode': false,
    'vibrateOnSuccess': true,
    'autoPlay': true,
    'autoAdvance': true,
    'dailyReminders': false,
    'offlineMode': false,
    'darkMode': false,
    'language': 'en-US',
    'voiceNavigation': true, // New setting for voice navigation
  };

  // Getters
  Map<String, dynamic> get settings => _settings;
  bool get isListening => _isListening;
  String get lastSpokenText => _lastSpokenText;
  bool get voiceNavigationEnabled => _voiceNavigationEnabled;
  int get currentSettingIndex => _currentSettingIndex;
  List<String> get settingSections => _settingSections;

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Settings speech recognition error: $error');
          _isListening = false;
          notifyListeners();
        },
      );
      
      if (available) {
        debugPrint('Settings speech recognition initialized');
      } else {
        debugPrint('Settings speech recognition not available');
      }
    } catch (e) {
      debugPrint('Error initializing settings speech: $e');
    }
  }

  // Load settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load each setting if it exists
      if (prefs.containsKey('voiceVolume')) {
        _settings['voiceVolume'] = [prefs.getInt('voiceVolume')];
      }
      
      if (prefs.containsKey('voiceGender')) {
        _settings['voiceGender'] = prefs.getString('voiceGender');
      }
      
      if (prefs.containsKey('micSensitivity')) {
        _settings['micSensitivity'] = [prefs.getInt('micSensitivity')];
      }
      
      if (prefs.containsKey('pronunciationStrictness')) {
        _settings['pronunciationStrictness'] = prefs.getString('pronunciationStrictness');
      }
      
      if (prefs.containsKey('extendedAudioDescriptions')) {
        _settings['extendedAudioDescriptions'] = prefs.getBool('extendedAudioDescriptions');
      }
      
      if (prefs.containsKey('screenReaderMode')) {
        _settings['screenReaderMode'] = prefs.getBool('screenReaderMode');
      }
      
      if (prefs.containsKey('vibrateOnSuccess')) {
        _settings['vibrateOnSuccess'] = prefs.getBool('vibrateOnSuccess');
      }
      
      if (prefs.containsKey('autoPlay')) {
        _settings['autoPlay'] = prefs.getBool('autoPlay');
      }
      
      if (prefs.containsKey('autoAdvance')) {
        _settings['autoAdvance'] = prefs.getBool('autoAdvance');
      }
      
      if (prefs.containsKey('dailyReminders')) {
        _settings['dailyReminders'] = prefs.getBool('dailyReminders');
      }
      
      if (prefs.containsKey('offlineMode')) {
        _settings['offlineMode'] = prefs.getBool('offlineMode');
      }
      
      if (prefs.containsKey('darkMode')) {
        _settings['darkMode'] = prefs.getBool('darkMode');
      }
      
      if (prefs.containsKey('language')) {
        _settings['language'] = prefs.getString('language');
      }
      
      if (prefs.containsKey('voiceNavigation')) {
        _settings['voiceNavigation'] = prefs.getBool('voiceNavigation') ?? true;
      }
      
      _voiceNavigationEnabled = _settings['voiceNavigation'] ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Update a setting and persist it
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      _settings[key] = value;
      
      // Update voice navigation state
      if (key == 'voiceNavigation') {
        _voiceNavigationEnabled = value;
      }
      
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save based on value type
      if (value is List<int> && value.isNotEmpty) {
        await prefs.setInt(key, value[0]);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
      
      // Speak confirmation for important settings
      if (['voiceVolume', 'voiceGender', 'darkMode', 'voiceNavigation'].contains(key)) {
        await _speakFeedback('$key set to ${value is List ? value[0] : value}');
      }
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  // Voice navigation methods
  Future<void> startVoiceNavigation() async {
    if (!_voiceNavigationEnabled) return;
    
    try {
      if (_isListening) {
        await stopVoiceNavigation();
        return;
      }

      await _tts.stop();
      
      bool available = await _speech.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Voice navigation error: $error');
          _isListening = false;
          notifyListeners();
        },
      );

      if (!available) {
        await _speakFeedback('Voice navigation not available');
        return;
      }

      _isListening = true;
      _lastSpokenText = '';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastSpokenText = result.recognizedWords.trim().toLowerCase();
            debugPrint('Voice navigation command: $_lastSpokenText');
            
            if (_lastSpokenText.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _processVoiceCommand(_lastSpokenText);
              });
            }
          } else {
            _lastSpokenText = result.recognizedWords;
            notifyListeners();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en-US',
      );

      await _speakFeedback('Voice navigation active. Say commands like "next section", "previous", or "toggle dark mode"');

    } catch (e) {
      debugPrint('Error starting voice navigation: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopVoiceNavigation() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
        await _speakFeedback('Voice navigation stopped');
      }
    } catch (e) {
      debugPrint('Error stopping voice navigation: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  // Process voice commands
  Future<void> _processVoiceCommand(String command) async {
    try {
      debugPrint('Processing voice command: $command');
      
      // Navigation commands
      if (command.contains('next') || command.contains('down')) {
        await navigateToNextSection();
      } else if (command.contains('previous') || command.contains('up') || command.contains('back')) {
        await navigateToPreviousSection();
      } else if (command.contains('first') || command.contains('start')) {
        await navigateToSection(0);
      } else if (command.contains('last') || command.contains('end')) {
        await navigateToSection(_settingSections.length - 1);
      }
      
      // Section-specific commands
      else if (command.contains('voice setting')) {
        await navigateToSection(0);
      } else if (command.contains('microphone')) {
        await navigateToSection(1);
      } else if (command.contains('accessibility')) {
        await navigateToSection(2);
      } else if (command.contains('learning')) {
        await navigateToSection(3);
      } else if (command.contains('app') || command.contains('preference')) {
        await navigateToSection(4);
      } else if (command.contains('help')) {
        await navigateToSection(5);
      } else if (command.contains('reset')) {
        await navigateToSection(6);
      }
      
      // Toggle commands
      else if (command.contains('dark mode')) {
        final newValue = !_settings['darkMode'];
        updateSetting('darkMode', newValue);
        await _speakFeedback('Dark mode ${newValue ? 'enabled' : 'disabled'}');
      } else if (command.contains('voice navigation')) {
        final newValue = !_settings['voiceNavigation'];
        updateSetting('voiceNavigation', newValue);
        await _speakFeedback('Voice navigation ${newValue ? 'enabled' : 'disabled'}');
      } else if (command.contains('auto play')) {
        final newValue = !_settings['autoPlay'];
        updateSetting('autoPlay', newValue);
        await _speakFeedback('Auto play ${newValue ? 'enabled' : 'disabled'}');
      }
      
      // Volume control
      else if (command.contains('volume up') || command.contains('increase volume')) {
        final currentVolume = _settings['voiceVolume'][0];
        final newVolume = (currentVolume + 10).clamp(10, 100);
        updateSetting('voiceVolume', [newVolume]);
        await _speakFeedback('Volume increased to $newVolume percent');
      } else if (command.contains('volume down') || command.contains('decrease volume')) {
        final currentVolume = _settings['voiceVolume'][0];
        final newVolume = (currentVolume - 10).clamp(10, 100);
        updateSetting('voiceVolume', [newVolume]);
        await _speakFeedback('Volume decreased to $newVolume percent');
      }
      
      // Test commands
      else if (command.contains('test voice') || command.contains('test')) {
        await testVoice();
      } else if (command.contains('read current')) {
        await readCurrentSection();
      } else if (command.contains('help') || command.contains('what can i say')) {
        await _speakHelpCommands();
      }
      
      else {
        await _speakFeedback('Command not recognized. Say "help" for available commands');
      }
      
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      await _speakFeedback('Error processing command');
    }
  }

  // Navigation methods
  Future<void> navigateToNextSection() async {
    if (_currentSettingIndex < _settingSections.length - 1) {
      _currentSettingIndex++;
      notifyListeners();
      await readCurrentSection();
    } else {
      await _speakFeedback('You are at the last section');
    }
  }

  Future<void> navigateToPreviousSection() async {
    if (_currentSettingIndex > 0) {
      _currentSettingIndex--;
      notifyListeners();
      await readCurrentSection();
    } else {
      await _speakFeedback('You are at the first section');
    }
  }

  Future<void> navigateToSection(int index) async {
    if (index >= 0 && index < _settingSections.length) {
      _currentSettingIndex = index;
      notifyListeners();
      await readCurrentSection();
    }
  }

  // Read current section information
  Future<void> readCurrentSection() async {
    final currentSection = _settingSections[_currentSettingIndex];
    String description = '';
    
    switch (_currentSettingIndex) {
      case 0:
        description = 'Voice Settings. Configure text to speech settings. Current volume is ${_settings['voiceVolume'][0]} percent. Voice gender is ${_settings['voiceGender']}.';
        break;
      case 1:
        description = 'Microphone Settings. Configure speech recognition. Sensitivity is ${_settings['micSensitivity'][0]} percent.';
        break;
      case 2:
        description = 'Accessibility Settings. Extended audio descriptions are ${_settings['extendedAudioDescriptions'] ? 'on' : 'off'}. Screen reader mode is ${_settings['screenReaderMode'] ? 'on' : 'off'}.';
        break;
      case 3:
        description = 'Learning Preferences. Auto advance is ${_settings['autoAdvance'] ? 'on' : 'off'}. Daily reminders are ${_settings['dailyReminders'] ? 'on' : 'off'}.';
        break;
      case 4:
        description = 'App Preferences. Dark mode is ${_settings['darkMode'] ? 'on' : 'off'}. Language is ${_settings['language']}.';
        break;
      case 5:
        description = 'Help and Support. Get help with voice commands and app features.';
        break;
      case 6:
        description = 'Reset Settings. Reset all settings to default values.';
        break;
    }
    
    await _speakFeedback('$currentSection. $description');
  }

  // Speak help commands
  Future<void> _speakHelpCommands() async {
    const commands = '''
      Available voice commands:
      Navigation: say "next", "previous", "first", "last", or specific section names like "voice settings"
      Toggle settings: say "toggle dark mode", "toggle voice navigation", "toggle auto play"
      Volume control: say "volume up", "volume down"
      Actions: say "test voice", "read current", "help"
      To stop voice navigation, say "stop listening"
    ''';
    
    await _speakFeedback(commands);
  }

  // Test voice settings using TTS
  Future<void> testVoice() async {
    try {
      // Configure TTS with current settings
      await _tts.setVolume(_settings['voiceVolume'][0] / 100);
      
      // Set voice based on gender selection
      String? voice;
      final voices = await _tts.getVoices;
      
      if (voices != null) {
        final gender = _settings['voiceGender'];
        for (var v in voices) {
          final voiceName = v['name'].toString().toLowerCase();
          
          if (gender == 'female' && 
              (voiceName.contains('female') || 
               voiceName.contains('woman') || 
               voiceName.contains('samantha') || 
               voiceName.contains('karen'))) {
            voice = v['name'];
            break;
          } else if (gender == 'male' && 
              (voiceName.contains('male') || 
               voiceName.contains('man') || 
               voiceName.contains('daniel') || 
               voiceName.contains('david'))) {
            voice = v['name'];
            break;
          } else if (gender == 'neutral' && 
              (voiceName.contains('neutral') || 
               voiceName.contains('alex') || 
               voiceName.contains('voice') || 
               !voiceName.contains('female') && !voiceName.contains('male'))) {
            voice = v['name'];
            break;
          }
        }
        
        if (voice == null && voices.isNotEmpty) {
          voice = voices.first['name'];
        }
      }
      
      if (voice != null) {
        await _tts.setVoice({'name': voice, 'locale': _settings['language']});
      } else {
        await _tts.setLanguage(_settings['language']);
      }
      
      // Speak test phrase
      await _speakFeedback('This is a test of your voice settings. How does this sound? Current volume is ${_settings['voiceVolume'][0]} percent and voice gender is ${_settings['voiceGender']}.');
    } catch (e) {
      debugPrint('Error testing voice: $e');
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

  // Reset all settings to defaults
  Future<void> resetAllSettings() async {
    try {
      final defaultSettings = {
        'voiceVolume': [50],
        'voiceGender': 'female',
        'micSensitivity': [75],
        'pronunciationStrictness': 'medium',
        'extendedAudioDescriptions': false,
        'screenReaderMode': false,
        'vibrateOnSuccess': true,
        'autoPlay': true,
        'autoAdvance': true,
        'dailyReminders': false,
        'offlineMode': false,
        'darkMode': false,
        'language': 'en-US',
        'voiceNavigation': true,
      };
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all settings
      await prefs.clear();
      
      // Set defaults
      for (var key in defaultSettings.keys) {
        final value = defaultSettings[key];
        _settings[key] = value;
        
        if (value is List<int> && value.isNotEmpty) {
          await prefs.setInt(key, value[0]);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        }
      }
      
      _voiceNavigationEnabled = true;
      _currentSettingIndex = 0;
      
      notifyListeners();
      await _speakFeedback('All settings have been reset to default values');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  // Initialize TTS engine
  Future<void> initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(_settings['language']);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Clean up TTS resources
  void disposeTts() {
    _tts.stop();
    _speech.stop();
  }
}