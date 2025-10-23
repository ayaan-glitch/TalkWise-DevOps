// pronunciation_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_routes.dart';
import 'pronunciation_backend.dart';
import 'dart:async';
import '../services/progress_service.dart';
import '../services/app_state_manager.dart';
import 'home_backend.dart';

class PronunciationPage extends StatefulWidget {
  const PronunciationPage({super.key});

  @override
  State<PronunciationPage> createState() => _PronunciationPageState();
}

class _PronunciationPageState extends State<PronunciationPage> {
  // Define colors similar to FlutterFlow theme
  final Color primaryColor = const Color(0xFF4B39EF);
  final Color secondaryColor = const Color(0xFF39D2C0);
  final Color tertiaryColor = const Color(0xFFEE8B60);
  final Color accentColor = const Color(0xFFFF5963);
  final Color successColor = const Color(0xFF249689);
  final Color warningColor = const Color(0xFFFFC107);
  final Color infoColor = const Color(0xFF17C1E8);
  
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = const Color(0xFFFFFFFF);
  final Color primaryText = const Color(0xFF14181B);
  final Color secondaryText = const Color(0xFF57636C);
  final Color alternate = const Color(0xFFE0E3E7);

  @override
  void initState() {
    super.initState(); 
  }

  @override
  void dispose() { 
    super.dispose();
  }

  void _showSearchDialog(BuildContext context) {
    // Use Provider instead of creating new instance
  final backend = Provider.of<PronunciationBackend>(context, listen: false);
  String searchTerm = '';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
        title: Text(
          'Search Word',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: primaryText,
          ),
        ),
        content: TextField(
          onChanged: (value) => searchTerm = value,
          decoration: InputDecoration(
            hintText: 'Enter a word to practice',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (searchTerm.trim().isNotEmpty) {
                Navigator.pop(context);
                await backend.searchWord(searchTerm);
                
                // Show success/error message
                if (backend.errorMessage.isNotEmpty && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(backend.errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$searchTerm" added to practice list'),
                      backgroundColor: successColor,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Search',
              style: GoogleFonts.inter(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PronunciationBackend>(
      builder: (context, backend, child) {
        final currentWord = backend.getCurrentWord();
        
        return Scaffold(
          backgroundColor: primaryBackground,
          appBar: AppBar(
            backgroundColor: primaryBackground,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryText),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'TalkWise Pronunciation',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: primaryText,
              ),
            ),
            actions: [
              // Level selector dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<String>(
                  value: backend.currentLevel,
                  icon: Icon(Icons.arrow_drop_down, color: primaryText),
                  elevation: 16,
                  style: GoogleFonts.inter(color: primaryText),
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      backend.setDifficultyLevel(newValue);
                    }
                  },
                  items: <String>['beginner', 'intermediate', 'advanced']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value[0].toUpperCase() + value.substring(1),
                        style: GoogleFonts.inter(),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Voice search button
              IconButton(
                icon: Icon(
                  backend.isListening ? Icons.mic_off : Icons.mic,
                  color: backend.isListening ? accentColor : primaryText,
                ),
                onPressed: () {
                  if (backend.isListening) {
                    backend.stopVoiceSearch();
                  } else {
                    backend.startVoiceSearch();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.search, color: primaryText),
                onPressed: () {
                  _showSearchDialog(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: primaryText),
                onPressed: () {
                  backend.refreshWords();
                },
              ),
            ],
            centerTitle: false,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading indicator
                  if (backend.isLoading) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    ),
                  ],

                  // Error message
                  if (backend.errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backend.errorMessage,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: accentColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: accentColor),
                            onPressed: backend.clearError,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Voice search feedback
                  if (backend.isListening) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: infoColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: infoColor, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Listening... Speak now',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: infoColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Say a word like "water" or "hello"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: infoColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Pulsing animation for listening state
                          SizedBox(
                            height: 40,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              width: backend.isListening ? 40 : 20,
                              height: backend.isListening ? 40 : 20,
                              decoration: BoxDecoration(
                                color: infoColor.withOpacity(backend.isListening ? 0.6 : 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Voice search result
                  if (backend.lastSpokenText.isNotEmpty && !backend.isListening) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: successColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.voice_chat, color: successColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You said: "${backend.lastSpokenText}"',
                              style: GoogleFonts.inter(
                                color: successColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Lesson header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pronunciation Practice',
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${backend.currentLevel[0].toUpperCase()}${backend.currentLevel.substring(1)} Level • ${currentWord.category}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Word ${backend.currentWordIndex + 1} of ${backend.currentWordList.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pronunciation Score',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: primaryText,
                                ),
                              ),
                              Text(
                                '${backend.pronunciationScore.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(backend.pronunciationScore),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: backend.pronunciationScore / 100,
                            backgroundColor: alternate,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getScoreColor(backend.pronunciationScore),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getScoreFeedback(backend.pronunciationScore),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: secondaryText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigation buttons for words
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: backend.previousWord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryBackground,
                          foregroundColor: primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 16),
                            const SizedBox(width: 4),
                            Text('Previous', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: backend.nextWord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryBackground,
                          foregroundColor: primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next', style: GoogleFonts.inter()),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Word card
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: secondaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Word and phonetic
                            Text(
                              currentWord.word,
                              style: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                                fontSize: 32,
                                color: primaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentWord.phonetic,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: secondaryText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Meaning
                            Text(
                              currentWord.meaning,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: primaryText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Examples if available
                            if (currentWord.examples.isNotEmpty) ...[
                              Divider(color: alternate, height: 1),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Examples:',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...currentWord.examples.take(2).map((example) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '• $example',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: secondaryText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ],

                            // Synonyms if available
                            if (currentWord.synonyms.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Divider(color: alternate, height: 1),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Similar Words:',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentWord.synonyms.take(3).join(', '),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audio context toggle
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.headset_rounded,
                                color: primaryText,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Audio Context',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentWord.context,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Switch(
                                value: backend.audioContextEnabled,
                                onChanged: (value) {
                                  backend.toggleAudioContext(value);
                                },
                                activeThumbColor: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                backend.audioContextEnabled ? 'Enabled' : 'Disabled',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.info_outline,
                                color: infoColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hear phonetic and context',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: infoColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Speed selector and audio controls
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Speed selector
                          Row(
                            children: [
                              Icon(Icons.speed_rounded, size: 20, color: primaryText),
                              const SizedBox(width: 8),
                              Text(
                                'Playback Speed',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: primaryText,
                                ),
                              ),
                              const Spacer(),
                              ..._buildSpeedOptions(backend),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Audio control buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: backend.playWordAudio,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: backend.isPlaying ? accentColor : primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          backend.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          backend.isPlaying ? 'Stop Playing' : 'Play Audio',
                                          style: GoogleFonts.interTight(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recording visualization (when recording)
                  if (backend.isRecording) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Recording...',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Amplitude visualization
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(10, (index) {
                                  final amplitude = backend.amplitudeLevel;
                                  final barHeight = (amplitude * 30 * (index % 3 + 1) / 3).clamp(4.0, 30.0);
                                  return Container(
                                    width: 4,
                                    height: barHeight,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duration: ${backend.recordingDuration.inSeconds}s',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recording button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        backend.toggleRecording();
                        // Handle recording completion
                        if (!backend.isRecording) {
                          _handleRecordingComplete(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backend.isRecording ? accentColor : primaryText,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            backend.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            backend.isRecording ? 'Stop Recording' : 'Record Pronunciation',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Accessibility section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.accessibility_new, size: 20, color: primaryText),
                              const SizedBox(width: 8),
                              Text(
                                'Accessibility Features',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildAccessibilityChip(
                                'Voice Search',
                                Icons.mic,
                                backend.isListening ? accentColor : primaryColor,
                                () => backend.startVoiceSearch(),
                              ),
                              _buildAccessibilityChip(
                                'Repeat Audio',
                                Icons.replay,
                                primaryColor,
                                backend.playWordAudio,
                              ),
                              _buildAccessibilityChip(
                                'Slower Speed',
                                Icons.slow_motion_video,
                                primaryColor,
                                () => backend.setSpeechRate(0.5),
                              ),
                              _buildAccessibilityChip(
                                'Normal Speed',
                                Icons.speed,
                                primaryColor,
                                () => backend.setSpeechRate(1.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Word list preview
                  if (backend.currentWordList.length > 1) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.list, size: 20, color: primaryText),
                                const SizedBox(width: 8),
                                Text(
                                  'Practice Words',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: backend.currentWordList.length,
                                itemBuilder: (context, index) {
                                  final word = backend.getWordByIndex(index);
                                  final isCurrent = index == backend.currentWordIndex;
                                  return GestureDetector(
                                    onTap: () => backend.setCurrentWordIndex(index),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? primaryColor : alternate,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            word.word,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isCurrent ? Colors.white : primaryText,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(height: 2),
                                            const Icon(Icons.volume_up, size: 12, color: Colors.white),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bottom navigation
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home_rounded, 'Home', secondaryText, AppRoutes.home),
                        _buildNavItem(Icons.menu_book_rounded, 'Lessons', secondaryText, AppRoutes.lessons),
                        _buildNavItem(Icons.volume_up_rounded, 'Practice', primaryColor, AppRoutes.pronunciation),
                        _buildNavItem(Icons.bar_chart_rounded, 'Progress', secondaryText, AppRoutes.progress),
                        _buildNavItem(Icons.settings_rounded, 'Settings', secondaryText, AppRoutes.settings),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add this method to build speed option chips
  List<Widget> _buildSpeedOptions(PronunciationBackend backend) {
    final speeds = [
      {'speed': 0.5, 'label': '0.5x'},
      {'speed': 1.0, 'label': '1x'},
      {'speed': 1.5, 'label': '1.5x'},
      {'speed': 2.0, 'label': '2x'},
    ];
    
    return speeds.map((speedInfo) {
      final isSelected = backend.speechRate == speedInfo['speed'];
      return GestureDetector(
        onTap: () => backend.setSpeechRate(speedInfo['speed'] as double),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : alternate,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : alternate,
            ),
          ),
          child: Text(
            speedInfo['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : primaryText,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAccessibilityChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return successColor;
    if (score >= 60) return warningColor;
    return accentColor;
  }

  String _getScoreFeedback(double score) {
    if (score >= 80) return 'Excellent pronunciation! Keep up the good work!';
    if (score >= 60) return 'Good effort! Practice makes perfect.';
    if (score >= 40) return 'Keep practicing! You\'re getting better.';
    return 'Try again! Listen carefully to the audio.';
  }

 
// Add this method to handle recording completion with progress tracking 
Future<void> _handleRecordingComplete(BuildContext context) async {
  final backend = Provider.of<PronunciationBackend>(context, listen: false);
  final homeBackend = Provider.of<HomeBackend>(context, listen: false); 
  final appState = Provider.of<AppStateManager>(context, listen: false);
  final currentWord = backend.getCurrentWord();
  
  // Wait a bit for the analysis to complete
  await Future.delayed(const Duration(seconds: 3));

  // Update progress tracking
  final score = backend.pronunciationScore; // Get score from backend
  if (score > 0) {
    ProgressService.updatePronunciationProgress(
      context, 
      score, 
      currentWord.word,
      currentWord.phonetic,
      currentWord.meaning
    );

    // ADD THESE LINES TO UPDATE HOME BACKEND
    appState.incrementStudyTime(5); // 5 minutes for pronunciation practice
    await homeBackend.recordPronunciationSession(); // FIXED: No parameters
    await homeBackend.updateStudyTime(); // FIXED: No parameters
  }
}

  Widget _buildNavItem(IconData icon, String label, Color color, String route) {
    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );  
  }
}