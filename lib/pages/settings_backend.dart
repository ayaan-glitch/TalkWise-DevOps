// settings_backend.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SettingsBackend with ChangeNotifier {
  static final SettingsBackend _instance = SettingsBackend._internal();
  factory SettingsBackend() => _instance;
  SettingsBackend._internal() {
    _loadSettings();
  }

  // TTS engine for voice testing
  final FlutterTts _tts = FlutterTts();

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
  };

  Map<String, dynamic> get settings => _settings;

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
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Update a setting and persist it
  // settings_backend.dart (update the updateSetting method)
Future<void> updateSetting(String key, dynamic value) async {
  try {
    _settings[key] = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save based on value type
    if (value is List<int> && value.isNotEmpty) {
      await prefs.setInt(key, value[0]);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
      
      // If dark mode is changed, also update the theme provider
      if (key == 'darkMode') {
        // This will be handled by the SettingsScreen listener
      }
    }
  } catch (e) {
    debugPrint('Error updating setting: $e');
  }
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
        // Try to find a voice that matches the selected gender
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
        
        // If no specific voice found, use the first available voice
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
      await _tts.speak('This is a test of your voice settings. How does this sound?');
    } catch (e) {
      debugPrint('Error testing voice: $e');
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
      
      notifyListeners();
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
  }
}