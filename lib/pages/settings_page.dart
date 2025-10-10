import 'package:flutter/material.dart';
import 'settings_backend.dart';
import 'theme_provider.dart'; 
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key}); // Make sure this is const

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsBackend _settingsBackend = SettingsBackend();
  Map<String, dynamic> settings = {
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _settingsBackend.initializeTts();
    _settingsBackend.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsBackend.removeListener(_onSettingsChanged);
    _settingsBackend.disposeTts();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      settings = Map<String, dynamic>.from(_settingsBackend.settings);
      
      // Apply dark mode theme change using ThemeProvider
      if (settings['darkMode'] != null) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.toggleTheme(settings['darkMode']);
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      // Wait for the backend to load settings
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        settings = Map<String, dynamic>.from(_settingsBackend.settings);
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  void updateSetting(String key, dynamic value) {
    _settingsBackend.updateSetting(key, value);
  }

  void testVoice() {
    _settingsBackend.testVoice();
  }

  void resetSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to reset all settings to default?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _settingsBackend.resetAllSettings();
                // Settings will update automatically via the listener
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Voice Settings Card
            _buildVoiceSettingsCard(isDarkMode),
            const SizedBox(height: 16),
            
            // Microphone Settings Card
            _buildMicrophoneSettingsCard(isDarkMode),
            const SizedBox(height: 16),
            
            // Accessibility Settings Card
            _buildAccessibilitySettingsCard(isDarkMode),
            const SizedBox(height: 16),
            
            // Learning Settings Card
            _buildLearningSettingsCard(isDarkMode),
            const SizedBox(height: 16),
            
            // App Settings Card
            _buildAppSettingsCard(isDarkMode),
            const SizedBox(height: 16),
            
            // Help & Support Card
            _buildHelpSupportCard(isDarkMode),
            const SizedBox(height: 16),
            
            // Reset Settings Card
            _buildResetSettingsCard(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Voice Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure text-to-speech settings',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            // Voice Volume
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voice Volume', style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                    Text('${settings['voiceVolume'][0]}%', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings['voiceVolume'][0].toDouble(),
                  onChanged: (value) => updateSetting('voiceVolume', [value.round()]),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  activeColor: isDarkMode ? Colors.blue[300] : Colors.blue,
                  inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Voice Gender
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Gender', style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settings['voiceGender'],
                  onChanged: (value) => updateSetting('voiceGender', value),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                  ],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[700] : null,
                  ),
                  dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test Voice Button
            OutlinedButton.icon(
              onPressed: testVoice,
              icon: Icon(Icons.volume_up, size: 16, color: isDarkMode ? Colors.blue[300] : Colors.blue),
              label: Text('Test Voice Settings', style: TextStyle(color: isDarkMode ? Colors.blue[300] : Colors.blue)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: isDarkMode ? Colors.blue[300]! : Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneSettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Microphone & Recording',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure speech recognition settings',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            // Mic Sensitivity
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Microphone Sensitivity', style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                    Text('${settings['micSensitivity'][0]}%', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings['micSensitivity'][0].toDouble(),
                  onChanged: (value) => updateSetting('micSensitivity', [value.round()]),
                  min: 25,
                  max: 100,
                  divisions: 15,
                  activeColor: isDarkMode ? Colors.blue[300] : Colors.blue,
                  inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pronunciation Strictness
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pronunciation Feedback', style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settings['pronunciationStrictness'],
                  onChanged: (value) => updateSetting('pronunciationStrictness', value),
                  items: const [
                    DropdownMenuItem(value: 'lenient', child: Text('Lenient - More forgiving')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium - Balanced')),
                    DropdownMenuItem(value: 'strict', child: Text('Strict - Native-like precision')),
                  ],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[700] : null,
                  ),
                  dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Accessibility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enhance your learning experience',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            _buildSwitchSetting(
              'Extended Audio Descriptions',
              'Detailed spoken descriptions of visual elements',
              settings['extendedAudioDescriptions'],
              (value) => updateSetting('extendedAudioDescriptions', value),
              isDarkMode,
            ),
            _buildSwitchSetting(
              'Screen Reader Mode',
              'Optimized for screen reader compatibility',
              settings['screenReaderMode'],
              (value) => updateSetting('screenReaderMode', value),
              isDarkMode,
            ),
            _buildSwitchSetting(
              'Vibrate on Success',
              'Haptic feedback for correct answers',
              settings['vibrateOnSuccess'],
              (value) => updateSetting('vibrateOnSuccess', value),
              isDarkMode,
            ),
            _buildSwitchSetting(
              'Auto-play Audio',
              'Automatically play lesson audio',
              settings['autoPlay'],
              (value) => updateSetting('autoPlay', value),
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Learning Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your learning experience',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            _buildSwitchSetting(
              'Auto-advance Lessons',
              'Automatically proceed to next exercise',
              settings['autoAdvance'],
              (value) => updateSetting('autoAdvance', value),
              isDarkMode,
            ),
            _buildSwitchSetting(
              'Daily Reminders',
              'Get reminded to practice daily',
              settings['dailyReminders'],
              (value) => updateSetting('dailyReminders', value),
              isDarkMode,
            ),
            _buildSwitchSetting(
              'Offline Mode',
              'Download lessons for offline use',
              settings['offlineMode'],
              (value) => updateSetting('offlineMode', value),
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(settings['darkMode'] ? Icons.dark_mode : Icons.light_mode, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'App Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSwitchSetting(
              'Dark Mode',
              'Use dark theme for better visibility',
              settings['darkMode'],
              (value) => updateSetting('darkMode', value),
              isDarkMode,
            ),
            
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interface Language', style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settings['language'],
                  onChanged: (value) => updateSetting('language', value),
                  items: const [
                    DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                    DropdownMenuItem(value: 'en-GB', child: Text('English (UK)')),
                    DropdownMenuItem(value: 'es-ES', child: Text('Spanish')),
                    DropdownMenuItem(value: 'fr-FR', child: Text('French')),
                    DropdownMenuItem(value: 'de-DE', child: Text('German')),
                  ],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[700] : null,
                  ),
                  dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSupportCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Help & Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildHelpButton('Voice Command Tutorial', Icons.volume_up, isDarkMode),
            const SizedBox(height: 8),
            _buildHelpButton('Privacy Settings', Icons.security, isDarkMode),
            const SizedBox(height: 8),
            _buildHelpButton('Help & FAQ', Icons.help_outline, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSettingsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isDarkMode ? Colors.red.withOpacity(0.4) : Colors.red.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton(
          onPressed: resetSettings,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: isDarkMode ? Colors.red.withOpacity(0.4) : Colors.red.withOpacity(0.2)),
          ),
          child: Text(
            'Reset All Settings',
            style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String description, bool value, Function(bool) onChanged, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDarkMode ? Colors.blue[300] : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton(String text, IconData icon, bool isDarkMode) {
    return OutlinedButton.icon(
      onPressed: () {
        // Implement help functionality
      },
      icon: Icon(icon, size: 16, color: isDarkMode ? Colors.blue[300] : Colors.blue),
      label: Text(text, style: TextStyle(color: isDarkMode ? Colors.blue[300] : Colors.blue)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: isDarkMode ? Colors.blue[300]! : Colors.blue),
      ),
    );
  }
}