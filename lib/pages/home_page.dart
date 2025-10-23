// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_routes.dart';
import '../services/notification_service.dart';
import 'home_backend.dart';
import '../services/app_state_manager.dart';
import '../pages/lessons_backend.dart'; // Add this import
import '../models/lesson_model.dart'; // Add this import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isVoiceListening = false;
  String _lastSpokenCommand = '';
  Timer? _voiceFeedbackTimer;
  bool _isTtsSpeaking = false;

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
    WidgetsBinding.instance.addObserver(this);
    _initializeHomePage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceFeedbackTimer?.cancel();
    final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
    lessonsBackend.stopListening();
    lessonsBackend.stopSpeaking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart voice listening when app resumes
      _restartVoiceListening();
    }
  }

  Future<void> _initializeHomePage() async {
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.checkAndShowSmartReminder();
    
    // Load home backend data
    final homeBackend = Provider.of<HomeBackend>(context, listen: false);
    await homeBackend.refreshData();

    // Load lessons data for TTS/STT
    final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
    await lessonsBackend.loadLessons();

    // Start voice navigation after a delay
    _startVoiceNavigation();
  }

  void _startVoiceNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          lessonsBackend.speak(
            'Home page voice navigation activated. Say "continue lesson", "practice pronunciation", "view progress", "today\'s lessons", "your progress", or "go to settings" to navigate.',
          );
          _setTtsSpeaking(true);
          _startListeningForCommands();
        }
      });
    });
  }

  void _restartVoiceListening() {
    final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
    lessonsBackend.stopListening();
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startListeningForCommands();
      }
    });
  }

  void _startListeningForCommands() {
    final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
    lessonsBackend.listenForCommandWithFallback(_handleVoiceCommand);
  }

  void _handleVoiceCommand(String command) {
    final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);

    setState(() {
      _lastSpokenCommand = command;
      _isVoiceListening = false;
    });

    debugPrint('Home voice command: $command');

    // Clear previous timer
    _voiceFeedbackTimer?.cancel();

    // Stop listening immediately when processing a command
    lessonsBackend.stopListening();

    // Process home page commands
    final cleanCommand = _cleanCommand(command);
    
    if (cleanCommand.contains('continue lesson') || 
        cleanCommand.contains('continue') || 
        cleanCommand.contains('resume lesson')) {
      _navigateToContinueLesson(lessonsBackend);
    } else if (cleanCommand.contains('practice pronunciation') || 
               cleanCommand.contains('pronunciation') || 
               cleanCommand.contains('speak')) {
      _navigateToPronunciation(lessonsBackend);
    } else if (cleanCommand.contains('view progress') || 
               cleanCommand.contains('progress') || 
               cleanCommand.contains('achievements')) {
      _navigateToProgress(lessonsBackend);
    } else if (cleanCommand.contains('today\'s lessons') || 
               cleanCommand.contains('today lessons') || 
               cleanCommand.contains('lessons today')) {
      _showTodaysLessons(lessonsBackend);
    } else if (cleanCommand.contains('your progress') || 
               cleanCommand.contains('my progress')) {
      _showYourProgress(lessonsBackend);
    } else if (cleanCommand.contains('go to settings') || 
               cleanCommand.contains('settings') || 
               cleanCommand.contains('configuration')) {
      _navigateToSettings(lessonsBackend);
    } else if (cleanCommand.contains('help') || 
               cleanCommand.contains('commands')) {
      _showVoiceHelp(lessonsBackend);
    } else {
      // Unknown command
      lessonsBackend.speak(
        'I didn\'t understand that command. Say "help" for available commands.',
      );
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }

    // Auto-clear command feedback
    _voiceFeedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastSpokenCommand = '';
        });
      }
    });
  }

  String _cleanCommand(String command) {
    return command
        .toLowerCase()
        .replaceAll(RegExp(r'\band\b'), '')
        .replaceAll(RegExp(r'\bthe\b'), '')
        .replaceAll(RegExp(r'\ba\b'), '')
        .replaceAll(RegExp(r'\bto\b'), '')
        .replaceAll(RegExp(r'\bfor\b'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _navigateToContinueLesson(LessonsBackend backend) {
    backend.speak('Navigating to continue your lesson');
    _setTtsSpeaking(true);
    _restartListeningWithDelay(2);
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, AppRoutes.lessons);
    });
  }

  void _navigateToPronunciation(LessonsBackend backend) {
    backend.speak('Opening pronunciation practice');
    _setTtsSpeaking(true);
    _restartListeningWithDelay(2);
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, AppRoutes.pronunciation);
    });
  }

  void _navigateToProgress(LessonsBackend backend) {
    backend.speak('Showing your progress overview');
    _setTtsSpeaking(true);
    _restartListeningWithDelay(2);
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, AppRoutes.progress);
    });
  }

  void _navigateToSettings(LessonsBackend backend) {
    backend.speak('Opening settings');
    _setTtsSpeaking(true);
    _restartListeningWithDelay(2);
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, AppRoutes.settings);
    });
  }

  void _showTodaysLessons(LessonsBackend backend) {
    final homeBackend = Provider.of<HomeBackend>(context, listen: false);
    final todaysLessons = _getNextUnlockedLessons();
    
    if (todaysLessons.isEmpty) {
      backend.speak('No lessons available for today. Please check your progress or complete previous lessons.');
    } else {
      final lessonTitles = todaysLessons.map((lesson) => lesson.title).join(', ');
      backend.speak('Today\'s recommended lessons are: $lessonTitles');
    }
    _setTtsSpeaking(true);
    _restartListeningWithDelay(4);
  }

  void _showYourProgress(LessonsBackend backend) {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    final homeBackend = Provider.of<HomeBackend>(context, listen: false);
    
    backend.speak(
      'Your current level is ${appState.userLevel}. '
      'You have completed ${appState.completedLessons} out of ${appState.totalLessons} lessons. '
      'Your daily streak is ${homeBackend.dayStreak} days. '
      'You have studied ${appState.todayStudyTime} minutes today.'
    );
    _setTtsSpeaking(true);
    _restartListeningWithDelay(5);
  }

  void _showVoiceHelp(LessonsBackend backend) {
    const helpMessage = '''
    Available voice commands on home page:
    - "continue lesson" - Resume your last lesson
    - "practice pronunciation" - Open pronunciation practice
    - "view progress" - See your progress overview
    - "today's lessons" - Hear today's recommended lessons
    - "your progress" - Get your current progress summary
    - "go to settings" - Open app settings
    - "help" - Show this help message
    ''';

    backend.speak(helpMessage);
    _setTtsSpeaking(true);
    _restartListeningWithDelay(8);
  }

  void _setTtsSpeaking(bool speaking) {
    setState(() {
      _isTtsSpeaking = speaking;
    });

    // Auto-reset after a reasonable time
    if (speaking) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isTtsSpeaking) {
          setState(() {
            _isTtsSpeaking = false;
          });
        }
      });
    }
  }

  void _restartListeningWithDelay(int seconds) {
    final backend = Provider.of<LessonsBackend>(context, listen: false);

    Future.delayed(Duration(seconds: seconds), () async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_isTtsSpeaking && !backend.isSpeaking) {
        _startListeningForCommands();
      } else if (mounted) {
        _restartListeningWithDelay(1);
      }
    });
  }

  // Get the next 3 unlocked lessons (replacement for dummy data)
  List<Lesson> _getNextUnlockedLessons() {
    try {
      final lessonsBackend = Provider.of<LessonsBackend>(context, listen: false);
      final allLessons = lessonsBackend.lessons;
      
      // Get all unlocked but not completed lessons
      final unlockedLessons = allLessons.where((lesson) => 
        lesson.isUnlocked && !lesson.isCompleted
      ).toList();
      
      // Sort by level and lesson number
      unlockedLessons.sort((a, b) {
        final levelOrder = {'beginner': 0, 'intermediate': 1, 'advanced': 2};
        final levelCompare = levelOrder[a.level]!.compareTo(levelOrder[b.level]!);
        if (levelCompare != 0) return levelCompare;
        return a.lessonNumber.compareTo(b.lessonNumber);
      });
      
      // Return the next 3 lessons (or all if less than 3)
      return unlockedLessons.length <= 3 
          ? unlockedLessons 
          : unlockedLessons.sublist(0, 3);
    } catch (e) {
      debugPrint('Error getting next unlocked lessons: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<HomeBackend, AppStateManager, LessonsBackend>(
      builder: (context, homeBackend, appState, lessonsBackend, child) {
        _isVoiceListening = lessonsBackend.isListening;

        // Get REAL data from AppStateManager
        final realUserLevel = appState.userLevel;
        final realCompletedLessons = appState.completedLessons;
        final realTodayStudyTime = appState.todayStudyTime;
        final realLastLessonTitle = appState.lastAccessedLessonTitle;
        final realLastLessonProgress = appState.lastLessonProgress;
        final realOverallProgress = appState.overallProgress;
        const realPronunciationAccuracy = 75.0;

        // Use REAL data in progress summary
        final progressSummary = homeBackend.getProgressSummary(
          realUserLevel, 
          realCompletedLessons, 
          realOverallProgress, 
          realPronunciationAccuracy, 
          realTodayStudyTime
        );

        // Update continue lesson with REAL data
        final continueLessonTitle = realLastLessonTitle.isNotEmpty 
            ? realLastLessonTitle 
            : 'Basic Greetings';
        final continueLessonProgress = '${(realLastLessonProgress * 100).toInt()}% completed';

        // Get motivational message with REAL data
        final motivationalMessage = homeBackend.getMotivationalMessage(
          realTodayStudyTime, 
          homeBackend.dailyGoalCompleted
        );

        // Get next unlocked lessons for Today's Lessons section
        final nextUnlockedLessons = _getNextUnlockedLessons();

        return Scaffold(
          backgroundColor: primaryBackground,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Voice command status indicator
                      if (_isVoiceListening || _isTtsSpeaking || _lastSpokenCommand.isNotEmpty)
                        _buildVoiceStatusIndicator(),

                      // Welcome Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    motivationalMessage.split('\n')[0],
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      lessonsBackend.speak(motivationalMessage);
                                      _setTtsSpeaking(true);
                                    },
                                    child: Icon(
                                      Icons.volume_up,
                                      color: secondaryText,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                motivationalMessage.split('\n')[1],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress Section
                      GestureDetector(
                        onTap: () {
                          lessonsBackend.speak(
                            'Your progress. Level: ${progressSummary['level']}. '
                            'Completed: ${progressSummary['completedLessons']}. '
                            'Day streak: ${progressSummary['dayStreak']} days. '
                            'Pronunciation accuracy: ${(progressSummary['pronunciationAccuracy'] as double).toStringAsFixed(0)} percent. '
                            'Study time today: ${progressSummary['todayStudyTime']} minutes.'
                          );
                          _setTtsSpeaking(true);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(
                                      Icons.track_changes,
                                      color: Color(0xFF14181B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Progress',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Level: ${progressSummary['level']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: primaryText,
                                      ),
                                    ),
                                    Text(
                                      progressSummary['completedLessons'].toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
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
                                    width: MediaQuery.of(context).size.width * (progressSummary['progressPercentage'] / 100),
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Text('🔥'),
                                            const SizedBox(width: 4),
                                            Text(
                                              progressSummary['dayStreak'].toString(),
                                              style: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                                color: primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Day Streak',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Text('🎯'),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${(progressSummary['pronunciationAccuracy'] as double).toStringAsFixed(0)}%',
                                              style: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                                color: secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pronunciation',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Text('⏱️'),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${progressSummary['todayStudyTime']}m',
                                              style: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                                color: primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Time Today',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: secondaryText,
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
                      const SizedBox(height: 20),

                      // Quick Actions Section
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              _buildActionCard(
                                Icons.play_arrow,
                                'Continue Lesson',
                                continueLessonTitle,
                                continueLessonProgress,
                                primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.lessons);
                                },
                                onVoiceTap: () {
                                  lessonsBackend.speak('Continue lesson: $continueLessonTitle. $continueLessonProgress');
                                  _setTtsSpeaking(true);
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                Icons.mic,
                                'Pronunciation Practice',
                                'Work on your accent',
                                'Improve fluency',
                                secondaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.pronunciation);
                                },
                                onVoiceTap: () {
                                  lessonsBackend.speak('Pronunciation practice. Work on your accent and improve fluency.');
                                  _setTtsSpeaking(true);
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                Icons.bar_chart,
                                'View Progress',
                                'See your achievements',
                                'Track growth',
                                tertiaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.progress);
                                },
                                onVoiceTap: () {
                                  lessonsBackend.speak('View progress. See your achievements and track your growth.');
                                  _setTtsSpeaking(true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Today's Lessons Section
                      GestureDetector(
                        onTap: () {
                          if (nextUnlockedLessons.isNotEmpty) {
                            final lessonTitles = nextUnlockedLessons.map((lesson) => lesson.title).join(', ');
                            lessonsBackend.speak('Today\'s lessons: $lessonTitles');
                            _setTtsSpeaking(true);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(
                                      Icons.book,
                                      color: Color(0xFF14181B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Today\'s Lessons',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (nextUnlockedLessons.isNotEmpty)
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: nextUnlockedLessons
                                        .map((lesson) => _buildLessonItem(
                                              lesson.title,
                                              '${lesson.duration} min',
                                              lesson.isCompleted ? 'Complete' : 'Start',
                                              lesson.isCompleted ? secondaryColor : primaryText,
                                            ))
                                        .toList(),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No lessons available. Complete previous lessons to unlock more.',
                                      style: GoogleFonts.inter(
                                        color: secondaryText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Daily Goal Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: homeBackend.dailyGoalCompleted 
                              ? successColor.withOpacity(0.2)
                              : infoColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    homeBackend.dailyGoalCompleted 
                                        ? Icons.emoji_events 
                                        : Icons.flag,
                                    color: primaryText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    homeBackend.dailyGoalCompleted 
                                        ? 'Daily Goal Completed! 🎉'
                                        : 'Daily Goal',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                homeBackend.dailyGoalCompleted
                                    ? 'You studied $realTodayStudyTime minutes today!'
                                    : '$realTodayStudyTime/${homeBackend.dailyGoalMinutes} minutes completed',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                              if (!homeBackend.dailyGoalCompleted) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: realTodayStudyTime / homeBackend.dailyGoalMinutes,
                                  backgroundColor: alternate,
                                  valueColor: AlwaysStoppedAnimation<Color>(infoColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Voice Commands Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(
                                    Icons.mic,
                                    color: Color(0xFF14181B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Voice Commands',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Say "Continue lesson", "Practice pronunciation", "Show progress", "Today\'s lessons", "Your progress", or "Go to settings" to navigate quickly.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Navigation Bar
                      Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: secondaryBackground,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavItem(Icons.home, 'Home', primaryColor, AppRoutes.home),
                              _buildNavItem(Icons.book, 'Lessons', secondaryText, AppRoutes.lessons),
                              _buildNavItem(Icons.chat, 'Assistant', secondaryText, AppRoutes.chatbot),
                              _buildNavItem(Icons.volume_up, 'Practice', secondaryText, AppRoutes.pronunciation),
                              _buildNavItem(Icons.bar_chart, 'Progress', secondaryText, AppRoutes.progress),
                              _buildNavItem(Icons.settings, 'Settings', secondaryText, AppRoutes.settings),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Voice command feedback overlay
                if (_lastSpokenCommand.isNotEmpty)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: _buildCommandFeedback(),
                  ),
              ],
            ),
          ),

          // Voice control floating action button
          floatingActionButton: _buildVoiceControlFab(lessonsBackend),
        );
      },
    );
  }

  Widget _buildVoiceStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isTtsSpeaking 
            ? warningColor.withOpacity(0.1)
            : _isVoiceListening 
                ? successColor.withOpacity(0.1)
                : primaryColor.withOpacity(0.1),
        border: Border.all(
          color: _isTtsSpeaking 
              ? warningColor
              : _isVoiceListening 
                  ? successColor
                  : primaryColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isTtsSpeaking 
                ? Icons.volume_up
                : _isVoiceListening 
                    ? Icons.mic
                    : Icons.mic_none,
            color: _isTtsSpeaking 
                ? warningColor
                : _isVoiceListening 
                    ? successColor
                    : primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isTtsSpeaking 
                  ? 'Speaking...'
                  : _isVoiceListening 
                      ? 'Listening for commands...'
                      : 'Voice commands available',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isTtsSpeaking 
                    ? warningColor
                    : _isVoiceListening 
                        ? successColor
                        : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandFeedback() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.voice_chat, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Command: "$_lastSpokenCommand"',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControlFab(LessonsBackend backend) {
    return FloatingActionButton(
      onPressed: () {
        if (_isVoiceListening) {
          backend.stopListening();
        } else {
          _startListeningForCommands();
        }
      },
      backgroundColor: _isVoiceListening ? successColor : primaryColor,
      tooltip: _isVoiceListening ? 'Stop Listening' : 'Start Voice Commands',
      child: Icon(
        _isVoiceListening ? Icons.mic_off : Icons.mic,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon, 
    String title, 
    String subtitle, 
    String progress, 
    Color color, 
    {VoidCallback? onTap, 
    VoidCallback? onVoiceTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onVoiceTap,
                child: Icon(
                  Icons.volume_up,
                  color: secondaryText,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonItem(String title, String duration, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, String route) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
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
      ),
    );
  }
}