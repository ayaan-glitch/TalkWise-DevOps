import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'progress_backend.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // TTS and STT instances
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  // STT state
  bool _isListening = false;
  String _lastSpokenText = '';
  String _errorMessage = '';
  
  // TTS state
  bool _isSpeaking = false;
  double _speechRate = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeSpeech();
    
    // Load progress data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = Provider.of<ProgressBackend>(context, listen: false);
      backend.loadProgressData();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // Initialize TTS
  Future<void> _initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      
      // Set up completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        if (mounted) setState(() {});
      });
      
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Initialize speech recognition
  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          if (mounted) setState(() {});
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
          _errorMessage = 'Speech recognition error occurred';
          if (mounted) setState(() {});
        },
      );
      
      if (available) {
        debugPrint('Speech recognition initialized for progress page');
      } else {
        debugPrint('Speech recognition not available');
        _errorMessage = 'Speech recognition not available on this device';
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      _errorMessage = 'Failed to initialize speech recognition';
    }
    if (mounted) setState(() {});
  }

  // Start voice commands for progress page
  Future<void> _startVoiceCommands() async {
    try {
      if (_isListening) {
        await _stopVoiceCommands();
        return;
      }

      // Stop any ongoing TTS first
      await _tts.stop();
      _isSpeaking = false;

      // Re-initialize speech recognition to ensure it's ready
      bool available = await _speech.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          if (mounted) setState(() {});
        },
        onError: (errorNotification) {
          debugPrint('Speech recognition error: $errorNotification');
          _isListening = false;
          _errorMessage = 'Speech recognition error';
          if (mounted) setState(() {});
        },
      );

      if (!available) {
        _errorMessage = 'Speech recognition not available';
        if (mounted) setState(() {});
        await _speakFeedback('Speech recognition not available');
        return;
      }

      _isListening = true;
      _lastSpokenText = '';
      if (mounted) setState(() {});

      // Wait a moment before starting to listen
      await Future.delayed(const Duration(milliseconds: 1000));

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastSpokenText = result.recognizedWords.trim().toLowerCase();
            debugPrint('Voice command: $_lastSpokenText');
            
            // Process the voice command
            if (_lastSpokenText.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _processVoiceCommand(_lastSpokenText);
              });
            }
          } else {
            // Update with partial results for real-time feedback
            _lastSpokenText = result.recognizedWords;
            if (mounted) setState(() {});
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en-US',
      );

      debugPrint('Voice commands started - listening for progress commands');

    } catch (e) {
      debugPrint('Error starting voice commands: $e');
      _errorMessage = 'Error starting voice commands: ${e.toString()}';
      _isListening = false;
      if (mounted) setState(() {});
    }
  }

  // Process voice commands for progress page
  Future<void> _processVoiceCommand(String command) async {
    try {
      _isListening = false;
      if (mounted) setState(() {});

      final backend = Provider.of<ProgressBackend>(context, listen: false);
      
      // Convert command to lowercase for easier matching
      command = command.toLowerCase();
      
      // Progress-related commands
      if (command.contains('overall progress') || command.contains('total progress')) {
        await _speakProgressSummary(backend);
      }
      else if (command.contains('lessons') || command.contains('lesson progress')) {
        await _speakLessonsProgress(backend);
      }
      else if (command.contains('pronunciation') || command.contains('speaking')) {
        await _speakPronunciationProgress(backend);
      }
      else if (command.contains('streak') || command.contains('current streak')) {
        await _speakFeedback('Your current streak is ${backend.currentStreak} days');
      }
      else if (command.contains('time studied') || command.contains('study time')) {
        await _speakFeedback('You have studied for ${backend.totalTimeStudied} minutes total');
      }
      else if (command.contains('recent activity') || command.contains('latest activity')) {
        await _speakRecentActivities(backend);
      }
      else if (command.contains('reset') && command.contains('progress')) {
        await _speakConfirmationDialog('Are you sure you want to reset all progress?');
      }
      else {
        await _speakFeedback('I heard: $command. Available commands: overall progress, lessons, pronunciation, streak, time studied, recent activity');
      }
      
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      _errorMessage = 'Error processing command: ${e.toString()}';
      if (mounted) setState(() {});
      await _speakFeedback('Error processing your command. Please try again.');
    }
  }

  // Speak overall progress summary
  Future<void> _speakProgressSummary(ProgressBackend backend) async {
    final progress = backend.overallProgress;
    final streak = backend.currentStreak;
    final studyTime = backend.totalTimeStudied;
    
    String message = 'Your overall progress is ${progress.toStringAsFixed(1)} percent. ';
    message += 'You have a $streak day streak. ';
    message += 'Total study time is $studyTime minutes. ';
    
    if (progress >= 80) {
      message += 'Excellent progress! Keep up the great work!';
    } else if (progress >= 50) {
      message += 'Good progress! You are doing well.';
    } else {
      message += 'Keep practicing to improve your progress.';
    }
    
    await _speakFeedback(message);
  }

  // Speak lessons progress
  Future<void> _speakLessonsProgress(ProgressBackend backend) async {
    final completed = backend.completedLessonsCount;
    final total = backend.totalLessonsCount;
    final beginner = backend.getBeginnerProgress();
    final intermediate = backend.getIntermediateProgress();
    final advanced = backend.getAdvancedProgress();
    
    String message = 'You have completed $completed out of $total lessons. ';
    message += 'Beginner level: ${beginner.toStringAsFixed(1)} percent complete. ';
    message += 'Intermediate level: ${intermediate.toStringAsFixed(1)} percent complete. ';
    message += 'Advanced level: ${advanced.toStringAsFixed(1)} percent complete.';
    
    await _speakFeedback(message);
  }

  // Speak pronunciation progress
  Future<void> _speakPronunciationProgress(ProgressBackend backend) async {
    final wordsPracticed = backend.wordsPracticed;
    final averageScore = backend.averagePronunciationScore;
    final bestScore = backend.bestPronunciationScore;
    final sessions = backend.practiceSessions;
    
    String message = 'You have practiced $wordsPracticed words. ';
    message += 'Your average pronunciation score is ${averageScore.toStringAsFixed(1)} percent. ';
    message += 'Your best score is ${bestScore.toStringAsFixed(1)} percent. ';
    message += 'You have completed $sessions practice sessions.';
    
    if (averageScore >= 80) {
      message += ' Excellent pronunciation skills!';
    } else if (averageScore >= 60) {
      message += ' Good pronunciation. Keep practicing!';
    } else {
      message += ' Practice more to improve your pronunciation.';
    }
    
    await _speakFeedback(message);
  }

  // Speak recent activities
  Future<void> _speakRecentActivities(ProgressBackend backend) async {
    final activities = backend.recentActivities;
    
    if (activities.isEmpty) {
      await _speakFeedback('No recent activities found.');
      return;
    }
    
    String message = 'Your recent activities: ';
    
    for (int i = 0; i < activities.length && i < 3; i++) {
      final activity = activities[i];
      message += '${activity.description}. ';
    }
    
    await _speakFeedback(message);
  }

  // Speak confirmation dialog for destructive actions
  Future<void> _speakConfirmationDialog(String message) async {
    await _speakFeedback(message);
    // In a real app, you might want to implement a voice-based confirmation flow
  }

  // Stop voice commands
  Future<void> _stopVoiceCommands() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        if (mounted) setState(() {});
        await _speakFeedback('Stopped listening');
      }
    } catch (e) {
      debugPrint('Error stopping voice commands: $e');
      _isListening = false;
      if (mounted) setState(() {});
    }
  }

  // Speak feedback to user
  Future<void> _speakFeedback(String message) async {
    try {
      await _tts.setSpeechRate(_speechRate);
      _isSpeaking = true;
      if (mounted) setState(() {});
      
      await _tts.speak(message);
      // Note: The completion handler will set _isSpeaking to false
      
    } catch (e) {
      debugPrint('Error speaking feedback: $e');
      _isSpeaking = false;
      if (mounted) setState(() {});
    }
  }

  // Stop speaking
  Future<void> _stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  // Set speech rate
  void _setSpeechRate(double rate) {
    _speechRate = rate;
    if (mounted) setState(() {});
    _speakFeedback('Speech speed set to ${rate}x');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressBackend>(
      builder: (context, backend, child) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        
        // Use theme colors
        final primaryBackground = theme.scaffoldBackgroundColor;
        final secondaryBackground = theme.cardColor;
        final primaryText = theme.textTheme.bodyLarge!.color!;
        final secondaryText = theme.textTheme.bodyMedium!.color!;
        final alternate = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E3E7);

        // Accent colors
        const primaryColor = Color(0xFF4B39EF);
        const secondaryColor = Color(0xFF39D2C0);
        const tertiaryColor = Color(0xFFEE8B60);
        const accentColor = Color(0xFFFF5963);
        const successColor = Color(0xFF249689);
        const warningColor = Color(0xFFFFC107);
        const infoColor = Color(0xFF17C1E8);

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
              'Learning Progress',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: primaryText,
              ),
            ),
            actions: [
              // Voice command button
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? accentColor : primaryText,
                ),
                onPressed: () {
                  if (_isListening) {
                    _stopVoiceCommands();
                  } else {
                    _startVoiceCommands();
                  }
                },
              ),
              // Stop speaking button
              if (_isSpeaking)
                IconButton(
                  icon: const Icon(Icons.stop, color: accentColor),
                  onPressed: _stopSpeaking,
                ),
              // Speech speed selector
              PopupMenuButton<double>(
                icon: Icon(Icons.speed, color: primaryText),
                onSelected: _setSpeechRate,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0.5,
                    child: Row(
                      children: [
                        Icon(Icons.slow_motion_video, size: 20),
                        SizedBox(width: 8),
                        Text('0.5x Speed'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 1.0,
                    child: Row(
                      children: [
                        Icon(Icons.speed, size: 20),
                        SizedBox(width: 8),
                        Text('1.0x Normal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 1.5,
                    child: Row(
                      children: [
                        Icon(Icons.fast_forward, size: 20),
                        SizedBox(width: 8),
                        Text('1.5x Fast'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            elevation: 0,
          ),
          body: backend.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                      const SizedBox(height: 16),
                      Text(
                        'Loading progress...',
                        style: GoogleFonts.inter(color: secondaryText),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  top: true,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Voice command status
                          if (_isListening) ...[
                            _buildVoiceCommandStatus(infoColor, primaryText),
                            const SizedBox(height: 16),
                          ],

                          // Error message
                          if (_errorMessage.isNotEmpty) ...[
                            _buildErrorMessage(accentColor, primaryText),
                            const SizedBox(height: 16),
                          ],

                          // Voice command result
                          if (_lastSpokenText.isNotEmpty && !_isListening) ...[
                            _buildVoiceResult(successColor, primaryText),
                            const SizedBox(height: 16),
                          ],

                          // Voice commands help
                          _buildVoiceCommandsHelp(primaryColor, secondaryBackground, primaryText, secondaryText),
                          const SizedBox(height: 16),

                          // Overall Progress Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: alternate,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Overall Progress',
                                            style: GoogleFonts.interTight(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: primaryText,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, size: 20, color: primaryColor),
                                          onPressed: () => _speakProgressSummary(backend),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${backend.overallProgress.toStringAsFixed(1)}% Complete',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: alternate,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Container(
                                            width: MediaQuery.of(context).size.width * (backend.overallProgress / 100),
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Combined progress across all lessons and pronunciation',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Icon(
                                              Icons.emoji_events,
                                              color: warningColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${backend.currentStreak} day streak',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                color: primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              color: infoColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${backend.totalTimeStudied}min total',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                color: primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Lessons Progress Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: alternate,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Lessons Progress',
                                            style: GoogleFonts.interTight(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: primaryText,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, size: 20, color: primaryColor),
                                          onPressed: () => _speakLessonsProgress(backend),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildProgressItem(
                                          'Completed Lessons',
                                          backend.completedLessonsCount,
                                          backend.totalLessonsCount,
                                          primaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildProgressItem(
                                          'Beginner Level',
                                          backend.beginnerCompleted,
                                          backend.beginnerTotal,
                                          secondaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildProgressItem(
                                          'Intermediate Level',
                                          backend.intermediateCompleted,
                                          backend.intermediateTotal,
                                          tertiaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildProgressItem(
                                          'Advanced Level',
                                          backend.advancedCompleted,
                                          backend.advancedTotal,
                                          accentColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Pronunciation Progress Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: alternate,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pronunciation Progress',
                                            style: GoogleFonts.interTight(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: primaryText,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, size: 20, color: primaryColor),
                                          onPressed: () => _speakPronunciationProgress(backend),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildPronunciationStats(
                                          'Words Practiced',
                                          '${backend.wordsPracticed} words',
                                          Icons.record_voice_over,
                                          primaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPronunciationStats(
                                          'Average Score',
                                          '${backend.averagePronunciationScore.toStringAsFixed(1)}%',
                                          Icons.score,
                                          successColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPronunciationStats(
                                          'Best Score',
                                          '${backend.bestPronunciationScore.toStringAsFixed(1)}%',
                                          Icons.emoji_events,
                                          warningColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPronunciationStats(
                                          'Practice Sessions',
                                          '${backend.practiceSessions} sessions',
                                          Icons.access_time,
                                          infoColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Recent Activity Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: alternate,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Recent Activity',
                                            style: GoogleFonts.interTight(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: primaryText,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, size: 20, color: primaryColor),
                                          onPressed: () => _speakRecentActivities(backend),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (backend.recentActivities.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No recent activity',
                                          style: GoogleFonts.inter(
                                            color: secondaryText,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      Column(
                                        children: backend.recentActivities
                                            .take(5)
                                            .map((activity) => _buildActivityItem(activity, backend))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  // Voice command status widget
  Widget _buildVoiceCommandStatus(Color color, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                'Listening for commands...',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Try saying: "overall progress", "lessons", "pronunciation"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color,
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
              width: _isListening ? 40 : 20,
              height: _isListening ? 40 : 20,
              decoration: BoxDecoration(
                color: color.withOpacity(_isListening ? 0.6 : 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Error message widget
  Widget _buildErrorMessage(Color color, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: color),
            onPressed: () {
              _errorMessage = '';
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // Voice result widget
  Widget _buildVoiceResult(Color color, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.voice_chat, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Command: "$_lastSpokenText"',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Voice commands help widget
  Widget _buildVoiceCommandsHelp(Color color, Color backgroundColor, Color textColor, Color secondaryTextColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
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
                Icon(Icons.voice_over_off, size: 20, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Voice Commands',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCommandChip('Overall Progress', Icons.bar_chart, color),
                _buildCommandChip('Lessons', Icons.menu_book, color),
                _buildCommandChip('Pronunciation', Icons.volume_up, color),
                _buildCommandChip('Streak', Icons.emoji_events, color),
                _buildCommandChip('Study Time', Icons.schedule, color),
                _buildCommandChip('Recent Activity', Icons.history, color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the microphone icon and speak a command',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Command chip widget
  Widget _buildCommandChip(String label, IconData icon, Color color) {
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
          Icon(icon, size: 14, color: color),
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
    );
  }

  // Rest of your existing widget methods remain the same...
  Widget _buildProgressItem(String title, int completed, int total, Color color) {
    final percentage = total > 0 ? (completed / total * 100) : 0;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: const Color(0xFF14181B),
                    ),
                  ),
                  Text(
                    '$completed/$total',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E7),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * (percentage / 100),
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(1)}% complete',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF57636C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPronunciationStats(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF57636C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity, ProgressBackend backend) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                backend.getActivityIcon(activity.type),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    Text(
                      activity.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF57636C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}