// pronunciation_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pronunciation_backend.dart';

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
    // Initialize when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = PronunciationBackend();
      // No need to initialize TTS separately as it's done in backend
    });
  }

  void _showSearchDialog(BuildContext context) {
    final backend = PronunciationBackend();
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
                      backend.setLevel(newValue);
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
                  // Refresh functionality - you might want to implement this in backend
                  backend.clearAnalysis();
                  backend.notifyListeners();
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
                            onPressed: () {
                              // Use a method to clear error instead of direct assignment
                              backend.clearError();
                            },
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
                              duration: Duration(milliseconds: 500),
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
                          '${backend.currentLevel[0].toUpperCase()}${backend.currentLevel.substring(1)} Level • ${currentWord.difficulty}',
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
                            Icon(Icons.arrow_back, size: 16),
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
                            Icon(Icons.arrow_forward, size: 16),
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
                              currentWord.definition,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: primaryText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User pronunciation if available
                            if (backend.userPronunciation.isNotEmpty) ...[
                              Divider(color: alternate, height: 1),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Pronunciation:',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${backend.userPronunciation}"',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: secondaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Pronunciation errors if available
                            if (backend.pronunciationErrors.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Divider(color: alternate, height: 1),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Areas to Improve:',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...backend.pronunciationErrors.take(3).map((error) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $error',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: accentColor,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ],

                            // Accent analysis if available
                            if (backend.detectedAccent != 'Unknown') ...[
                              const SizedBox(height: 16),
                              Divider(color: alternate, height: 1),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Accent Analysis:',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: infoColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${backend.detectedAccent} (${(backend.accentConfidence * 100).toStringAsFixed(1)}% confidence)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: infoColor,
                                      fontStyle: FontStyle.italic,
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
                      onPressed: backend.toggleRecording,
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

                  // Analysis details section
                  if (backend.pronunciationAnalysis.isNotEmpty) ...[
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
                                Icon(Icons.analytics, size: 20, color: primaryText),
                                const SizedBox(width: 8),
                                Text(
                                  'Detailed Analysis',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Waveform visualization if available
                            if (backend.audioWaveform.isNotEmpty) ...[
                              SizedBox(
                                height: 60,
                                child: CustomPaint(
                                  painter: WaveformPainter(backend.audioWaveform),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildAnalysisChip(
                                  'Speaking Rate',
                                  '${backend.speakingRate.toStringAsFixed(1)}x',
                                  infoColor,
                                ),
                                _buildAnalysisChip(
                                  'Stress Pattern',
                                  backend.stressPattern.isNotEmpty ? 'Analyzed' : 'N/A',
                                  successColor,
                                ),
                                _buildAnalysisChip(
                                  'Intonation',
                                  backend.intonationPattern.isNotEmpty ? 'Analyzed' : 'N/A',
                                  warningColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                                  final word = backend.currentWordList[index];
                                  final isCurrent = index == backend.currentWordIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      // Use a method to change word index instead of direct assignment
                                      backend.setCurrentWordIndex(index);
                                    },
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
                                            Icon(Icons.volume_up, size: 12, color: Colors.white),
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
                        _buildNavItem(Icons.home_rounded, 'Home', secondaryText, () {}),
                        _buildNavItem(Icons.menu_book_rounded, 'Lessons', secondaryText, () {}),
                        _buildNavItem(Icons.volume_up_rounded, 'Practice', primaryColor, () {}),
                        _buildNavItem(Icons.bar_chart_rounded, 'Progress', secondaryText, () {}),
                        _buildNavItem(Icons.settings_rounded, 'Settings', secondaryText, () {}),
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

  Widget _buildAnalysisChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
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

  Widget _buildNavItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  
  WaveformPainter(this.waveform);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    
    final paint = Paint()
      ..color = Color(0xFF4B39EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    final xStep = size.width / (waveform.length - 1);
    
    path.moveTo(0, size.height / 2 + waveform[0] * size.height / 2);
    
    for (int i = 1; i < waveform.length; i++) {
      final x = i * xStep;
      final y = size.height / 2 + waveform[i] * size.height / 2;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}