import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'lessons_backend.dart';
import '../models/lesson_model.dart';
import 'lesson_detail_page.dart';

class LessonsPage extends StatefulWidget {
  static const String routeName = '/lessons';

  const LessonsPage({super.key});

  @override
  _LessonsPageState createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isVoiceListening = false;
  String _lastSpokenCommand = '';
  Timer? _voiceFeedbackTimer;

  final Color primaryColor = const Color(0xFF4B39EF);
  final Color secondaryColor = const Color(0xFF39D2C0);
  final Color successColor = const Color(0xFF249689);
  final Color accentColor = const Color(0xFFFF5963);
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = const Color(0xFFFFFFFF);
  final Color primaryText = const Color(0xFF14181B);
  final Color secondaryText = const Color(0xFF57636C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLessons();
    _startVoiceListening();
  }

  void _loadLessons() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = Provider.of<LessonsBackend>(context, listen: false);
      backend.clearError();
      backend.loadLessons();
    });
  }

  void _startVoiceListening() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = Provider.of<LessonsBackend>(context, listen: false);
      // Start listening after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          backend.speak('Voice navigation activated. Say "start lesson" to begin, or "help" for commands.');
          _startListeningForCommands();
        }
      });
    });
  }

  void _startListeningForCommands() {
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    backend.listenForCommand(_handleVoiceCommand);
  }

  void _handleVoiceCommand(String command) {
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    
    setState(() {
      _lastSpokenCommand = command;
    });

    debugPrint('Voice command received: $command');

    // Clear previous timer
    _voiceFeedbackTimer?.cancel();

    // Process commands
    if (command.contains('start lesson') || command.contains('begin lesson')) {
      _startFirstAvailableLesson(backend);
    } else if (command.contains('next lesson') || command.contains('next')) {
      _navigateToNextLesson(backend);
    } else if (command.contains('previous lesson') || command.contains('previous') || command.contains('back')) {
      _navigateToPreviousLesson(backend);
    } else if (command.contains('beginner')) {
      _switchToLevel('beginner', backend);
    } else if (command.contains('intermediate')) {
      _switchToLevel('intermediate', backend);
    } else if (command.contains('advanced')) {
      _switchToLevel('advanced', backend);
    } else if (command.contains('help') || command.contains('commands')) {
      _showVoiceHelp(backend);
    } else if (command.contains('refresh') || command.contains('reload')) {
      _loadLessons();
      backend.speak('Refreshing lessons');
    } else {
      // Try to extract lesson number from command
      _tryExtractLessonNumber(command, backend);
    }

    // Auto-clear the command feedback after 3 seconds
    _voiceFeedbackTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastSpokenCommand = '';
        });
      }
    });

    // Restart listening after processing command
    _restartListening();
  }

  void _startFirstAvailableLesson(LessonsBackend backend) {
    final currentLevel = _getCurrentLevel();
    final levelLessons = backend.getLessonsByLevel(currentLevel);
    
    if (levelLessons.isEmpty) {
      backend.speak('No lessons available for $currentLevel level');
      return;
    }

    final firstUnlockedLesson = levelLessons.firstWhere(
      (lesson) => lesson.isUnlocked,
      orElse: () => levelLessons.first,
    );

    if (firstUnlockedLesson.isUnlocked) {
      _startLesson(firstUnlockedLesson, backend);
    } else {
      backend.speak('The first lesson is locked. Please complete prerequisite lessons.');
    }
  }

  void _navigateToNextLesson(LessonsBackend backend) {
    final currentLevel = _getCurrentLevel();
    final levelLessons = backend.getLessonsByLevel(currentLevel);
    
    if (levelLessons.isEmpty) {
      backend.speak('No lessons available');
      return;
    }

    // For simplicity, start the first lesson when saying "next lesson"
    final firstLesson = levelLessons.firstWhere(
      (lesson) => lesson.isUnlocked,
      orElse: () => levelLessons.first,
    );

    if (firstLesson.isUnlocked) {
      _startLesson(firstLesson, backend);
    } else {
      backend.speak('No unlocked lessons available. Complete previous lessons first.');
    }
  }

  void _navigateToPreviousLesson(LessonsBackend backend) {
    // Similar to next lesson, for simplicity go to first lesson
    backend.speak('Navigating to previous lesson');
    _startFirstAvailableLesson(backend);
  }

  void _switchToLevel(String level, LessonsBackend backend) {
    final levelIndex = ['beginner', 'intermediate', 'advanced'].indexOf(level);
    if (levelIndex != -1) {
      setState(() {
        _tabController.index = levelIndex;
      });
      backend.speak('Switched to $level level');
    }
  }

  void _tryExtractLessonNumber(String command, LessonsBackend backend) {
    // Extract numbers from command (e.g., "lesson 1", "start lesson 3")
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(command);
    
    if (match != null) {
      final lessonNumber = int.parse(match.group(1)!);
      _startLessonByNumber(lessonNumber, backend);
    } else {
      // If no number found, check for common lesson names
      _tryFindLessonByName(command, backend);
    }
  }

  void _startLessonByNumber(int lessonNumber, LessonsBackend backend) {
    final currentLevel = _getCurrentLevel();
    final levelLessons = backend.getLessonsByLevel(currentLevel);
    
    final lesson = levelLessons.firstWhere(
      (lesson) => lesson.lessonNumber == lessonNumber,
      orElse: () => levelLessons.firstWhere(
        (lesson) => lesson.isUnlocked,
        orElse: () => levelLessons.first,
      ),
    );

    if (lesson.isUnlocked) {
      _startLesson(lesson, backend);
    } else {
      backend.speak('Lesson $lessonNumber is locked. Complete previous lessons first.');
    }
  }

  void _tryFindLessonByName(String command, LessonsBackend backend) {
    final currentLevel = _getCurrentLevel();
    final levelLessons = backend.getLessonsByLevel(currentLevel);
    
    // Simple keyword matching for common lesson types
    final lowerCommand = command.toLowerCase();
    Lesson? foundLesson;

    if (lowerCommand.contains('grammar')) {
      foundLesson = levelLessons.firstWhere(
        (lesson) => lesson.type.toLowerCase().contains('grammar') && lesson.isUnlocked,
        orElse: () => levelLessons.firstWhere(
          (lesson) => lesson.isUnlocked,
          orElse: () => levelLessons.first,
        ),
      );
    } else if (lowerCommand.contains('vocabulary') || lowerCommand.contains('words')) {
      foundLesson = levelLessons.firstWhere(
        (lesson) => lesson.type.toLowerCase().contains('vocabulary') && lesson.isUnlocked,
        orElse: () => levelLessons.firstWhere(
          (lesson) => lesson.isUnlocked,
          orElse: () => levelLessons.first,
        ),
      );
    } else if (lowerCommand.contains('pronunciation') || lowerCommand.contains('speak')) {
      foundLesson = levelLessons.firstWhere(
        (lesson) => lesson.type.toLowerCase().contains('pronunciation') && lesson.isUnlocked,
        orElse: () => levelLessons.firstWhere(
          (lesson) => lesson.isUnlocked,
          orElse: () => levelLessons.first,
        ),
      );
    }

    if (foundLesson != null && foundLesson.isUnlocked) {
      _startLesson(foundLesson, backend);
    } else {
      backend.speak('I didn\'t understand that command. Say "help" for available commands.');
    }
  }

  void _showVoiceHelp(LessonsBackend backend) {
    final helpMessage = '''
    Available voice commands:
    - Say "start lesson" to begin the first available lesson
    - Say "beginner", "intermediate", or "advanced" to switch levels
    - Say "lesson 1" or "lesson 2" to start a specific lesson
    - Say "grammar lesson" or "vocabulary lesson" for specific types
    - Say "next lesson" or "previous lesson" to navigate
    - Say "refresh" to reload lessons
    ''';
    
    backend.speak(helpMessage);
  }

  String _getCurrentLevel() {
    switch (_tabController.index) {
      case 0: return 'beginner';
      case 1: return 'intermediate';
      case 2: return 'advanced';
      default: return 'beginner';
    }
  }

  void _restartListening() {
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    
    // Wait a bit before restarting listening to avoid feedback loop
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _startListeningForCommands();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonsBackend>(
      builder: (context, lessonsBackend, child) {
        _isVoiceListening = lessonsBackend.isListening;
        
        return Scaffold(
          backgroundColor: primaryBackground,
          appBar: AppBar(
            backgroundColor: primaryBackground,
            title: Text(
              'English Lessons',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: primaryText,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: secondaryText,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Beginner'),
                Tab(text: 'Intermediate'),
                Tab(text: 'Advanced'),
              ],
            ),
            actions: [
              // Voice command status indicator
              IconButton(
                icon: Icon(
                  _isVoiceListening ? Icons.mic_off : Icons.mic,
                  color: _isVoiceListening ? successColor : primaryText,
                ),
                onPressed: () {
                  if (_isVoiceListening) {
                    lessonsBackend.stopListening();
                  } else {
                    _startListeningForCommands();
                  }
                },
              ),
              // Voice help button
              IconButton(
                icon: Icon(Icons.help, color: primaryText),
                onPressed: () {
                  _showVoiceHelp(lessonsBackend);
                },
              ),
            ],
            elevation: 0,
          ),
          body: Stack(
            children: [
              // Main content
              TabBarView(
                controller: _tabController,
                children: [
                  _buildLevelTab('beginner', lessonsBackend),
                  _buildLevelTab('intermediate', lessonsBackend),
                  _buildLevelTab('advanced', lessonsBackend),
                ],
              ),
              
              // Voice command feedback overlay
              if (_lastSpokenCommand.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildVoiceCommandFeedback(),
                ),
            ],
          ),
          // Voice command help banner
          bottomNavigationBar: _buildVoiceHelpBanner(lessonsBackend),
        );
      },
    );
  }

  Widget _buildVoiceCommandFeedback() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.voice_chat, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Command: "$_lastSpokenCommand"',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: () {
              setState(() {
                _lastSpokenCommand = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceHelpBanner(LessonsBackend backend) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border(top: BorderSide(color: primaryColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: primaryColor, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voice Navigation Active',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Say "start lesson", "beginner", or "help"',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (_isVoiceListening)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: successColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelTab(String level, LessonsBackend lessonsBackend) {
    if (lessonsBackend.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
            const SizedBox(height: 16),
            Text(
              'Loading lessons...',
              style: GoogleFonts.inter(color: secondaryText),
            ),
          ],
        ),
      );
    }

    final levelLessons = lessonsBackend.getLessonsByLevel(level);

    if (levelLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: secondaryText),
            const SizedBox(height: 16),
            Text(
              'No $level lessons available',
              style: GoogleFonts.inter(fontSize: 18, color: secondaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content!',
              style: GoogleFonts.inter(color: secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: levelLessons.length,
      itemBuilder: (context, index) {
        final lesson = levelLessons[index];
        return _buildLessonCard(lesson, lessonsBackend);
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson, LessonsBackend lessonsBackend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: lesson.isUnlocked
              ? _getLessonColor(lesson.type)
              : Colors.grey,
          child: Icon(
            _getLessonIcon(lesson.type),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          lesson.title,
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: lesson.isUnlocked ? primaryText : secondaryText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lesson.description,
              style: GoogleFonts.inter(
                color: lesson.isUnlocked ? secondaryText : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: secondaryText),
                const SizedBox(width: 4),
                Text(
                  '${lesson.duration} min',
                  style: GoogleFonts.inter(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(width: 12),
                Icon(Icons.category, size: 14, color: secondaryText),
                const SizedBox(width: 4),
                Text(
                  lesson.type,
                  style: GoogleFonts.inter(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
            if (lesson.progress > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: lesson.progress,
                backgroundColor: Colors.grey[200],
                color: _getLessonColor(lesson.type),
                minHeight: 4,
              ),
            ],
          ],
        ),
        trailing: Icon(
          lesson.isUnlocked ? Icons.arrow_forward_ios : Icons.lock,
          size: 20,
          color: lesson.isUnlocked ? primaryColor : Colors.grey,
        ),
        onTap: lesson.isUnlocked
            ? () => _startLesson(lesson, lessonsBackend)
            : () => _showLockedMessage(lessonsBackend),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load lessons',
              style: GoogleFonts.interTight(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLessons,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLessonColor(String type) {
    switch (type) {
      case 'grammar':
        return const Color(0xFF4B39EF);
      case 'vocabulary':
        return const Color(0xFF39D2C0);
      case 'pronunciation':
        return const Color(0xFFEE8B60);
      case 'conversation':
        return const Color(0xFFFF5963);
      case 'listening':
        return const Color(0xFF249689);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'grammar':
        return Icons.article;
      case 'vocabulary':
        return Icons.library_books;
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'conversation':
        return Icons.chat;
      case 'listening':
        return Icons.headphones;
      default:
        return Icons.school;
    }
  }

  void _startLesson(Lesson lesson, LessonsBackend lessonsBackend) {
    lessonsBackend.speak('Starting ${lesson.title}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailPage(lesson: lesson),
      ),
    );
  }

  void _showLockedMessage(LessonsBackend lessonsBackend) {
    lessonsBackend.speak('This lesson is locked. Complete previous lessons to unlock it.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete previous lessons to unlock this one'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}