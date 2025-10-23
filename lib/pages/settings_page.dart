import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/theme_provider.dart';
import 'settings_backend.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    'voiceNavigation': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Initialize TTS and add listener through Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = Provider.of<SettingsBackend>(context, listen: false);
      backend.initializeTts();
      backend.addListener(_onSettingsChanged);
      
      // Auto-start voice navigation if enabled
      if (backend.voiceNavigationEnabled) {
        backend.startVoiceNavigation();
      }
    });
  }

  @override
  void dispose() {
    // Remove listener and dispose TTS through Provider
    final backend = Provider.of<SettingsBackend>(context, listen: false);
    backend.removeListener(_onSettingsChanged);
    backend.disposeTts();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      final backend = Provider.of<SettingsBackend>(context, listen: false);
      settings = Map<String, dynamic>.from(backend.settings);

      // Apply dark mode theme change using ThemeProvider
      if (settings['darkMode'] != null) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.toggleTheme(settings['darkMode']);
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        final backend = Provider.of<SettingsBackend>(context, listen: false);
        settings = Map<String, dynamic>.from(backend.settings);

        // Sync initial theme state with provider
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        if (settings['darkMode'] != null) {
          themeProvider.toggleTheme(settings['darkMode']);
        }
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  void updateSetting(String key, dynamic value) {
    final backend = Provider.of<SettingsBackend>(context, listen: false);
    backend.updateSetting(key, value);
  }

  void testVoice() {
    final backend = Provider.of<SettingsBackend>(context, listen: false);
    backend.testVoice();
  }

  void resetSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E232D) : Colors.white,
          title: Text(
            'Reset Settings',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            'Are you sure you want to reset all settings to default?',
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final backend = Provider.of<SettingsBackend>(context, listen: false);
                await backend.resetAllSettings();
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
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

    return Consumer<SettingsBackend>(
      builder: (context, backend, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: TextStyle(color: theme.appBarTheme.foregroundColor),
            ),
            backgroundColor: theme.appBarTheme.backgroundColor,
            iconTheme: IconThemeData(color: theme.appBarTheme.foregroundColor),
            elevation: 0,
            actions: [
              // Voice navigation toggle button
              IconButton(
                icon: Icon(
                  backend.isListening ? Icons.mic_off : Icons.mic,
                  color: backend.isListening ? Colors.red : theme.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  if (backend.isListening) {
                    backend.stopVoiceNavigation();
                  } else {
                    backend.startVoiceNavigation();
                  }
                },
              ),
              // Read current section button
              IconButton(
                icon: Icon(Icons.volume_up, color: theme.appBarTheme.foregroundColor),
                onPressed: () => backend.readCurrentSection(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Voice Navigation Status
                if (backend.isListening) _buildVoiceNavigationStatus(isDarkMode),
                if (backend.lastSpokenText.isNotEmpty && !backend.isListening) 
                  _buildVoiceCommandResult(isDarkMode, backend.lastSpokenText),

                // Voice Settings Card
                _buildVoiceSettingsCard(isDarkMode, backend),
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
          // Floating action button for quick voice commands
          floatingActionButton: backend.voiceNavigationEnabled ? FloatingActionButton(
            onPressed: () => backend.startVoiceNavigation(),
            backgroundColor: backend.isListening ? Colors.red : theme.colorScheme.primary,
            child: Icon(backend.isListening ? Icons.mic_off : Icons.mic),
          ) : null,
        );
      },
    );
  }

  Widget _buildVoiceNavigationStatus(bool isDarkMode) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Voice Navigation Active',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Say commands like "next section", "toggle dark mode", or "help"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // Pulsing animation
          SizedBox(
            height: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCommandResult(bool isDarkMode, String command) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.voice_chat, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Command: "$command"',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettingsCard(bool isDarkMode, SettingsBackend backend) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Voice Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure text-to-speech settings',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            // Voice Navigation Toggle
            _buildSwitchSetting(
              'Voice Navigation',
              'Use voice commands to navigate settings',
              settings['voiceNavigation'],
              (value) => updateSetting('voiceNavigation', value),
            ),
            const SizedBox(height: 16),

            // Voice Volume
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voice Volume', style: theme.textTheme.bodyLarge),
                    Text('${settings['voiceVolume'][0]}%', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings['voiceVolume'][0].toDouble(),
                  onChanged: (value) => updateSetting('voiceVolume', [value.round()]),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Voice Gender
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Gender', style: theme.textTheme.bodyLarge),
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
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  dropdownColor: isDarkMode ? const Color(0xFF1E232D) : Colors.white,
                  style: theme.textTheme.bodyMedium,
                  icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Test Voice Button
            OutlinedButton.icon(
              onPressed: testVoice,
              icon: Icon(Icons.volume_up, size: 16, color: theme.colorScheme.primary),
              label: Text('Test Voice Settings', style: TextStyle(color: theme.colorScheme.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneSettingsCard(bool isDarkMode) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Microphone & Recording',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure speech recognition settings',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            // Mic Sensitivity
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Microphone Sensitivity', style: theme.textTheme.bodyLarge),
                    Text('${settings['micSensitivity'][0]}%', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings['micSensitivity'][0].toDouble(),
                  onChanged: (value) => updateSetting('micSensitivity', [value.round()]),
                  min: 25,
                  max: 100,
                  divisions: 15,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pronunciation Strictness
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pronunciation Feedback', style: theme.textTheme.bodyLarge),
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
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  dropdownColor: isDarkMode ? const Color(0xFF1E232D) : Colors.white,
                  style: theme.textTheme.bodyMedium,
                  icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySettingsCard(bool isDarkMode) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Accessibility',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enhance your learning experience',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            _buildSwitchSetting(
              'Extended Audio Descriptions',
              'Detailed spoken descriptions of visual elements',
              settings['extendedAudioDescriptions'],
                  (value) => updateSetting('extendedAudioDescriptions', value),
            ),
            _buildSwitchSetting(
              'Screen Reader Mode',
              'Optimized for screen reader compatibility',
              settings['screenReaderMode'],
                  (value) => updateSetting('screenReaderMode', value),
            ),
            _buildSwitchSetting(
              'Vibrate on Success',
              'Haptic feedback for correct answers',
              settings['vibrateOnSuccess'],
                  (value) => updateSetting('vibrateOnSuccess', value),
            ),
            _buildSwitchSetting(
              'Auto-play Audio',
              'Automatically play lesson audio',
              settings['autoPlay'],
                  (value) => updateSetting('autoPlay', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSettingsCard(bool isDarkMode) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Learning Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your learning experience',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            _buildSwitchSetting(
              'Auto-advance Lessons',
              'Automatically proceed to next exercise',
              settings['autoAdvance'],
                  (value) => updateSetting('autoAdvance', value),
            ),
            _buildSwitchSetting(
              'Daily Reminders',
              'Get reminded to practice daily',
              settings['dailyReminders'],
                  (value) => updateSetting('dailyReminders', value),
            ),
            _buildSwitchSetting(
              'Offline Mode',
              'Download lessons for offline use',
              settings['offlineMode'],
                  (value) => updateSetting('offlineMode', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard(bool isDarkMode) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(settings['darkMode'] ? Icons.dark_mode : Icons.light_mode, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'App Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSwitchSetting(
              'Dark Mode',
              'Use dark theme for better visibility',
              settings['darkMode'],
                  (value) => updateSetting('darkMode', value),
            ),

            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interface Language', style: theme.textTheme.bodyLarge),
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
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  dropdownColor: isDarkMode ? const Color(0xFF1E232D) : Colors.white,
                  style: theme.textTheme.bodyMedium,
                  icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSupportCard(bool isDarkMode) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Help & Support',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildHelpButton('Voice Command Tutorial', Icons.volume_up),
            const SizedBox(height: 8),
            _buildHelpButton('Privacy Settings', Icons.security),
            const SizedBox(height: 8),
            _buildHelpButton('Help & FAQ', Icons.help_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSettingsCard(bool isDarkMode) {
    final theme = Theme.of(context);

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
          child: const Text(
            'Reset All Settings',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String description, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton(String text, IconData icon) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () {
        // Implement help functionality
      },
      icon: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(text, style: TextStyle(color: theme.colorScheme.primary)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}