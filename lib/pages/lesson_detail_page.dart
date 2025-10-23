// lib/pages/lesson_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import 'lessons_backend.dart';
import '../services/progress_service.dart'; 
class LessonDetailPage extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailPage({super.key, required this.lesson});

  @override
  _LessonDetailPageState createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  // Track selected answers for each exercise
  final Map<String, String?> _selectedAnswers = {};
  bool _isListening = false;
  String _lastCommand = '';
  Timer? _commandTimer;
  double _currentSpeed = 1.0;
  bool _isTtsSpeaking = false;

  int _currentSectionIndex = 0;
  int _currentExerciseIndex = 0;
  bool _isReadingExercises = false;
  bool _isLessonActive = false;
  bool _waitingForUserAnswer = false;
  bool _allExercisesCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceNavigation();
  }

  void _initializeVoiceNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backend = Provider.of<LessonsBackend>(context, listen: false);
      backend.setSpeechRate(_currentSpeed);

      // Stop any current listening
      backend.stopListening();

      // Wait a moment before speaking and starting listening
      Future.delayed(const Duration(seconds: 1), () {
        backend.speak(
          'Lesson voice navigation activated. Say "start lesson" to begin, "next" to continue, or "start exercise" for practice questions.',
        );

        // Start listening only after TTS finishes
        _startListeningWithDelay(
          backend,
          4,
        ); // Wait 4 seconds for the message to finish
      });
    });
  }

  void _startListeningWithDelay(LessonsBackend backend, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted && !_isTtsSpeaking) {
        _startListening();
      }
    });
  }

  void _startListening() {
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    backend.stopListening(); // Ensure no previous listening session

    // Add a small delay before starting to listen
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        backend.listenForCommandWithFallback(_handleVoiceCommand);
        debugPrint('Now actively listening for voice commands...');
      }
    });
  }

  void _handleVoiceCommand(String command) {
    final backend = Provider.of<LessonsBackend>(context, listen: false);

    setState(() {
      _lastCommand = command;
      _isListening = false;
    });

    debugPrint('Lesson voice command: $command');

    // Clear previous timer
    _commandTimer?.cancel();

    // Clean the command - remove extra words and normalize
    final cleanCommand = _cleanCommand(command);
    debugPrint('Cleaned command: $cleanCommand');

    // Stop listening immediately when processing a command
    backend.stopListening();

    // Process lesson-specific commands
    if (cleanCommand.contains('start lesson') ||
        cleanCommand.contains('begin lesson')) {
      _startLessonContent(backend);
    } else if (cleanCommand.contains('start exercise') ||
        cleanCommand.contains('begin exercise')) {
      _startExercises(backend);
    } else if (cleanCommand.contains('next section') ||
        cleanCommand.contains('next') ||
        cleanCommand.contains('next question')) {
      _readNextSection(backend);
    } else if (cleanCommand.contains('previous section') ||
        cleanCommand.contains('previous') ||
        cleanCommand.contains('back') ||
        cleanCommand.contains('previous question')) {
      _readPreviousSection(backend);
    } else if (cleanCommand.contains('read question') ||
        cleanCommand.contains('current question') ||
        cleanCommand.contains('repeat question')) {
      _readCurrentExercise(backend);
    } else if (cleanCommand.contains('option') ||
        cleanCommand.contains('choose') ||
        cleanCommand.contains('select')) {
      _handleOptionSelection(command, backend);
    } else if (cleanCommand.contains('next lesson') ||
        cleanCommand.contains('go to next lesson')) {
      _goToNextLesson(backend);
    } else if (cleanCommand.contains('help') ||
        cleanCommand.contains('commands')) {
      _showLessonVoiceHelp(backend);
    } else if (cleanCommand.contains('repeat') ||
        cleanCommand.contains('again')) {
      _readCurrentExercise(backend);
    } else if (cleanCommand.contains('stop') ||
        cleanCommand.contains('end lesson') ||
        command.contains('pause')) {
      _stopLesson(backend);
    } else if (cleanCommand.contains('speed') ||
        command.contains('change speed') ||
        command.contains('set speed')) {
      _handleSpeedChange(command, backend);
    } else {
      // Check if it's a simple "start" command and route appropriately
      if (cleanCommand == 'start' || cleanCommand.contains('start')) {
        if (_isReadingExercises) {
          _readCurrentExercise(backend);
        } else {
          _startLessonContent(backend);
        }
      } else {
        // Don't restart listening immediately for unknown commands
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            backend.speak(
              'I didn\'t understand that command. Say "help" for available commands.',
            );
            _restartListeningWithDelay(3);
          }
        });
        return;
      }
    }

    // Auto-clear command feedback
    _commandTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastCommand = '';
        });
      }
    });
  }

  String _cleanCommand(String command) {
    // Remove common filler words and normalize the command
    return command
        .toLowerCase()
        .replaceAll(RegExp(r'\band\b'), '') // Remove "and"
        .replaceAll(RegExp(r'\bthe\b'), '') // Remove "the"
        .replaceAll(RegExp(r'\ba\b'), '') // Remove "a"
        .replaceAll(RegExp(r'\bto\b'), '') // Remove "to"
        .replaceAll(RegExp(r'\bfor\b'), '') // Remove "for"
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  void _startLessonContent(LessonsBackend backend) {
    setState(() {
      _currentSectionIndex = 0;
      _isReadingExercises = false;
      _isLessonActive = true;
      _waitingForUserAnswer = false;
      _allExercisesCompleted = false;
    });

    backend.speak('Starting lesson: ${widget.lesson.title}');
    _setTtsSpeaking(true);

    if (widget.lesson.sections.isNotEmpty) {
      _restartListeningWithDelay(3); // Wait for "Starting lesson" to finish
      Future.delayed(const Duration(seconds: 3), () {
        _readCurrentSection(backend);
      });
    } else {
      _restartListeningWithDelay(2);
    }
  }

  void _readCurrentSection(LessonsBackend backend) {
    if (!_isLessonActive ||
        _currentSectionIndex >= widget.lesson.sections.length) {
      return;
    }

    final section = widget.lesson.sections[_currentSectionIndex];

    backend.speak(
      'Section ${_currentSectionIndex + 1} of ${widget.lesson.sections.length}. ${section.title}',
    );
    _setTtsSpeaking(true);

    // Read content after a brief pause
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLessonActive) {
        backend.speak(section.content);
        _setTtsSpeaking(true);

        // Read examples if they exist
        if (section.examples.isNotEmpty) {
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && _isLessonActive) {
              backend.speak('Examples: ${section.examples.join('. ')}');
              _setTtsSpeaking(true);
              _restartListeningWithDelay(4);
            }
          });
        } else {
          _restartListeningWithDelay(3);
        }
      }
    });
  }

  void _readNextSection(LessonsBackend backend) {
    if (!_isLessonActive) {
      backend.speak('Please start the lesson first by saying "start lesson".');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
      return;
    }

    if (_isReadingExercises) {
      _nextExercise(backend);
      return;
    }

    if (_currentSectionIndex < widget.lesson.sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
      backend.speak('Moving to next section.');
      _setTtsSpeaking(true);
      Future.delayed(const Duration(seconds: 2), () {
        _readCurrentSection(backend);
      });
    } else {
      backend.speak(
        'This is the last section. Say "start exercise" to begin practice questions.',
      );
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }
  }

  void _readPreviousSection(LessonsBackend backend) {
    if (!_isLessonActive) {
      backend.speak('Please start the lesson first by saying "start lesson".');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
      return;
    }

    if (_isReadingExercises) {
      _previousExercise(backend);
      return;
    }

    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      backend.speak('Moving to previous section.');
      _setTtsSpeaking(true);
      Future.delayed(const Duration(seconds: 2), () {
        _readCurrentSection(backend);
      });
    } else {
      backend.speak('This is the first section.');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
    }
  }

  void _startExercises(LessonsBackend backend) {
    if (widget.lesson.exercises.isEmpty) {
      backend.speak('This lesson has no exercises.');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
      return;
    }

    setState(() {
      _currentExerciseIndex = 0;
      _isReadingExercises = true;
      _isLessonActive = true;
      _selectedAnswers.clear();
      _waitingForUserAnswer = false;
      _allExercisesCompleted = false;
    });

    backend.speak(
      'Starting exercises. There are ${widget.lesson.exercises.length} questions.',
    );
    _setTtsSpeaking(true);

    // Wait a bit before starting the first exercise
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isReadingExercises) {
        _readCurrentExercise(backend);
      }
    });
  }

  void _nextExercise(LessonsBackend backend) {
    if (!_isLessonActive || !_isReadingExercises) return;

    if (_currentExerciseIndex < widget.lesson.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _waitingForUserAnswer = false;
        _selectedAnswers.clear();
      });
      backend.speak('Moving to next question.');
      _setTtsSpeaking(true);
      Future.delayed(const Duration(seconds: 2), () {
        _readCurrentExercise(backend);
      });
    } else {
      // All exercises completed
      setState(() {
        _allExercisesCompleted = true;
        _waitingForUserAnswer = false;
      });
      backend.speak(
        'Congratulations! You have completed all exercises. Say "next lesson" to continue to the next lesson, or "start lesson" to review this lesson again.',
      );
      _setTtsSpeaking(true);
      _restartListeningWithDelay(5);
    }
  }

  void _previousExercise(LessonsBackend backend) {
    if (!_isLessonActive || !_isReadingExercises) return;

    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _waitingForUserAnswer = false;
        _selectedAnswers.clear();
        _allExercisesCompleted = false;
      });
      backend.speak('Moving to previous question.');
      _setTtsSpeaking(true);
      Future.delayed(const Duration(seconds: 2), () {
        _readCurrentExercise(backend);
      });
    } else {
      backend.speak('This is the first exercise.');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
    }
  }

  void _handleOptionSelection(String command, LessonsBackend backend) {
    if (!_isLessonActive) {
      backend.speak('Please start the lesson first by saying "start lesson".');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
      return;
    }
    if (!_isReadingExercises) {
      backend.speak('Please start exercises first by saying "start exercise".');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(2);
      return;
    }

    if (_currentExerciseIndex >= widget.lesson.exercises.length) return;

    final exercise = widget.lesson.exercises[_currentExerciseIndex];

    // Extract option number from command
    final regex = RegExp(r'option\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(command);

    int? optionNum;

    if (match != null) {
      optionNum = int.parse(match.group(1)!);
    } else {
      // Try to match just numbers
      final numberRegex = RegExp(r'\b(\d+)\b');
      final numberMatch = numberRegex.firstMatch(command);
      if (numberMatch != null) {
        optionNum = int.parse(numberMatch.group(1)!);
      }
    }

    if (optionNum != null) {
      if (optionNum >= 1 && optionNum <= exercise.options.length) {
        final selectedOption = exercise.options[optionNum - 1];
        setState(() {
          _selectedAnswers[exercise.id] = selectedOption;
        });

        // IMMEDIATELY CHECK THE ANSWER - NO SUBMIT NEEDED
        _checkAnswer(exercise, selectedOption, backend);
      } else {
        backend.speak(
          'Please choose an option between 1 and ${exercise.options.length}.',
        );
        _setTtsSpeaking(true);
        _restartListeningWithDelay(3);
      }
    } else {
      backend.speak(
        'Please say "option 1", "option 2", etc. to choose your answer.',
      );
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }
  }

  void _checkAnswer(
    Exercise exercise,
    String selectedOption,
    LessonsBackend backend,
  ) {
    final isCorrect = selectedOption == exercise.correctAnswer;

    // Submit the attempt
    backend.submitExerciseAttempt(
      widget.lesson.id,
      exercise.id,
      selectedOption,
    );

    // Provide immediate feedback
    if (isCorrect) {
      backend.speak('Correct answer! ${exercise.explanation}');
      _setTtsSpeaking(true);
      setState(() {
        _waitingForUserAnswer = false;
      });

      // Auto-advance to next question after correct answer
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted &&
            _isReadingExercises &&
            _currentExerciseIndex < widget.lesson.exercises.length - 1) {
          _nextExercise(backend);
        } else if (mounted && _isReadingExercises) {
          // This is the last exercise - mark as completed
          setState(() {
            _allExercisesCompleted = true;
          });
          backend.speak(
            'Congratulations! You have completed all exercises. Say "next lesson" to continue to the next lesson, or "start lesson" to review this lesson again.',
          );
          _setTtsSpeaking(true);
          _restartListeningWithDelay(4);
        }
      });
    } else {
      backend.speak(
        'Wrong answer. Please try again. The correct answer is ${exercise.correctAnswer}. ${exercise.explanation}',
      );
      _setTtsSpeaking(true);
      setState(() {
        _waitingForUserAnswer = false;
      });

      // After wrong answer, repeat the same question
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isReadingExercises) {
          backend.speak('Let\'s try this question again.');
          _setTtsSpeaking(true);
          _restartListeningWithDelay(1);
          // Re-read the same question
          Future.delayed(const Duration(seconds: 1), () {
            _readCurrentExercise(backend);
          });
        }
      });
    }
  }

  void _goToNextLesson(LessonsBackend backend) {
    debugPrint('Next lesson command received');

    // Check if we can proceed to next lesson
    bool canProceed = false;

    if (_isReadingExercises) {
      // In exercise mode, check if all exercises are completed or we're at the last one
      canProceed =
          _allExercisesCompleted ||
          _currentExerciseIndex >= widget.lesson.exercises.length - 1;
      debugPrint(
        'Exercise mode - canProceed: $canProceed, allCompleted: $_allExercisesCompleted, currentIndex: $_currentExerciseIndex, total: ${widget.lesson.exercises.length}',
      );
    } else {
      // In lesson mode, we can always proceed after reading sections
      canProceed = true;
      debugPrint('Lesson mode - canProceed: $canProceed');
    }

    if (canProceed) {
      backend.speak('Completing this lesson and moving to the next one.');
      _setTtsSpeaking(true);

      // Use a slight delay to ensure TTS starts before navigation
      Future.delayed(const Duration(seconds: 2), () {
        _completeLessonAndNavigateToNext(context);
      });
    } else {
      backend.speak(
        'Please complete all exercises first before moving to the next lesson. You have completed $_currentExerciseIndex out of ${widget.lesson.exercises.length} exercises.',
      );
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }
  }

  void _completeLessonAndNavigateToNext(BuildContext context) async {
    final backend = Provider.of<LessonsBackend>(context, listen: false);

    try {
      debugPrint('Completing lesson: ${widget.lesson.title}');

      // Complete the current lesson with context for quiz check
      await backend.completeLesson(widget.lesson.id, context: context);

      // Update progress tracking
      await ProgressService.updateLessonProgress(context, widget.lesson);

      // Get the updated lessons list to find the next unlocked lesson
      final allLessons = backend.lessons;

      // Find the next uncompleted, unlocked lesson
      Lesson? nextLesson = _findNextUnlockedLesson(allLessons, widget.lesson);

      // Navigate based on what we found
      if (nextLesson != null && nextLesson.id != widget.lesson.id) {
        backend.speak('Moving to next lesson: ${nextLesson.title}');
        _setTtsSpeaking(true);

        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LessonDetailPage(lesson: nextLesson),
            ),
          );
        });
      } else {
        backend.speak(
          'Congratulations! You have completed all available lessons. Returning to lesson categories.',
        );
        _setTtsSpeaking(true);

        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      debugPrint('Error in completeLessonAndNavigateToNext: $e');
      backend.speak('Error completing lesson. Please try again.');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }
  }

  Lesson? _findNextUnlockedLesson(
    List<Lesson> allLessons,
    Lesson currentLesson,
  ) {
    // Sort lessons by level and lesson number
    final sortedLessons = List<Lesson>.from(allLessons)
      ..sort((a, b) {
        final levelOrder = {'beginner': 0, 'intermediate': 1, 'advanced': 2};
        final levelCompare = levelOrder[a.level]!.compareTo(
          levelOrder[b.level]!,
        );
        if (levelCompare != 0) return levelCompare;
        return a.lessonNumber.compareTo(b.lessonNumber);
      });

    // Find current lesson index
    final currentIndex = sortedLessons.indexWhere(
      (lesson) => lesson.id == currentLesson.id,
    );
    if (currentIndex == -1) return null;

    // Look for the next unlocked lesson after current lesson
    for (int i = currentIndex + 1; i < sortedLessons.length; i++) {
      if (sortedLessons[i].isUnlocked && !sortedLessons[i].isCompleted) {
        return sortedLessons[i];
      }
    }

    return null;
  }

  void _stopLesson(LessonsBackend backend) {
    setState(() {
      _isLessonActive = false;
      _isReadingExercises = false;
      _waitingForUserAnswer = false;
    });
    backend.stopSpeaking();
    backend.stopListening();
    backend.speak('Lesson stopped. Say "start lesson" to begin again.');
    _setTtsSpeaking(true);
    _restartListeningWithDelay(3);
  }

  void _handleSpeedChange(String command, LessonsBackend backend) {
    double newSpeed = _currentSpeed;

    if (command.contains('0.5') ||
        command.contains('half') ||
        command.contains('slow')) {
      newSpeed = 0.5;
    } else if (command.contains('1.0') ||
        command.contains('normal') ||
        command.contains('one')) {
      newSpeed = 1.0;
    } else if (command.contains('1.5') || command.contains('fast')) {
      newSpeed = 1.5;
    } else if (command.contains('2.0') ||
        command.contains('two') ||
        command.contains('double') ||
        command.contains('fastest')) {
      newSpeed = 2.0;
    } else if (command.contains('speed') && command.contains('change') ||
        command.contains('set')) {
      // Handle commands like "change speed to 2x" or "set speed to 1.5"
      if (command.contains('2') ||
          command.contains('two') ||
          command.contains('double')) {
        newSpeed = 2.0;
      } else if (command.contains('1.5') ||
          command.contains('one point five')) {
        newSpeed = 1.5;
      } else if (command.contains('1.0') ||
          command.contains('one') ||
          command.contains('normal')) {
        newSpeed = 1.0;
      } else if (command.contains('0.5') ||
          command.contains('half') ||
          command.contains('slow')) {
        newSpeed = 0.5;
      }
    }

    if (newSpeed != _currentSpeed) {
      setState(() {
        _currentSpeed = newSpeed;
      });
      backend.setSpeechRate(newSpeed);
      backend.speak('Speech speed set to ${newSpeed}x');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    } else {
      backend.speak('Speech speed is already set to ${newSpeed}x');
      _setTtsSpeaking(true);
      _restartListeningWithDelay(3);
    }
  }

  void _showLessonVoiceHelp(LessonsBackend backend) {
    const helpMessage = '''
    Available voice commands:
    - "start lesson" - Begin the lesson
    - "start exercise" - Begin practice questions
    - "next" or "next question" - Go to next question
    - "previous" or "previous question" - Go to previous question
    - "option 1", "option 2", etc. - Choose answer (automatically checked)
    - "next lesson" - Move to next lesson after completing exercises
    - "read question" - Repeat current question
    - "repeat" - Repeat last content
    - "stop" - Stop the lesson
    - "speed 0.5", "speed 1.0", "speed 1.5", "speed 2.0" - Change speech speed
    - "change speed to 2x" - Change to specific speed
    - "help" - Show this help
    ''';

    backend.speak(helpMessage);
    _setTtsSpeaking(true);
    _restartListeningWithDelay(8); // Longer delay for help message
  }

  void _setTtsSpeaking(bool speaking) {
    setState(() {
      _isTtsSpeaking = speaking;
    });

    // Auto-reset after a reasonable time if not manually reset
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

      // Additional safety delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_isTtsSpeaking && !backend.isSpeaking) {
        debugPrint('Starting to listen for user response...');
        _startListening();
      } else if (mounted) {
        // If still speaking, wait a bit more and check again
        debugPrint('Still speaking, delaying listening...');
        _restartListeningWithDelay(1);
      }
    });
  }

  void _readCurrentExercise(LessonsBackend backend) {
    if (!_isLessonActive ||
        !_isReadingExercises ||
        _currentExerciseIndex >= widget.lesson.exercises.length) {
      debugPrint(
        'Cannot read exercise: isActive=$_isLessonActive, isReadingExercises=$_isReadingExercises, index=$_currentExerciseIndex',
      );
      return;
    }

    final exercise = widget.lesson.exercises[_currentExerciseIndex];
    debugPrint('Reading exercise: ${exercise.question}');

    setState(() {
      _waitingForUserAnswer = true;
    });

    // Use a more controlled timing approach
    _speakExerciseWithControlledTiming(backend, exercise);
  }

  void _speakExerciseWithControlledTiming(
    LessonsBackend backend,
    Exercise exercise,
  ) async {
    // Step 1: Announce question number
    await backend.speak(
      'Question ${_currentExerciseIndex + 1} of ${widget.lesson.exercises.length}.',
    );
    _setTtsSpeaking(true);

    // Wait for completion
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || !_isLessonActive || !_isReadingExercises) return;

    // Step 2: Read the actual question
    await backend.speak(exercise.question);
    _setTtsSpeaking(true);

    // Wait for completion
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || !_isLessonActive || !_isReadingExercises) return;

    // Step 3: Read options if they exist
    if (exercise.options.isNotEmpty) {
      final optionsText = exercise.options
          .asMap()
          .entries
          .map((e) {
            return 'Option ${e.key + 1}: ${e.value}';
          })
          .join('. ');

      await backend.speak('Options: $optionsText');
      _setTtsSpeaking(true);

      // Wait for options to be spoken completely
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted || !_isLessonActive || !_isReadingExercises) return;

      // Step 4: Instructions - give clear time to respond
      backend.speak(
        'Say "option 1", "option 2", etc. to choose your answer. I am now listening for your response.',
      );
      _setTtsSpeaking(true);

      // Start listening with adequate delay after instructions
      _restartListeningWithDelay(3);
    } else {
      // If no options, start listening immediately
      _restartListeningWithDelay(2);
    }
  }

  void _restartListening() {
    _restartListeningWithDelay(2);
  }

  @override
  void dispose() {
    _commandTimer?.cancel();
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    backend.stopListening();
    backend.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = Provider.of<LessonsBackend>(context);
    _isListening = backend.isListening;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // TTS status indicator
          if (_isTtsSpeaking) const Icon(Icons.volume_up, color: Colors.orange),

          // Speed control dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<double>(
              value: _currentSpeed,
              icon: const Icon(Icons.speed, color: Colors.black),
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              onChanged: (double? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentSpeed = newValue;
                  });
                  backend.setSpeechRate(newValue);
                  backend.speak('Speed set to ${newValue}x');
                  _setTtsSpeaking(true);
                  _restartListeningWithDelay(3);
                }
              },
              items: [0.5, 1.0, 1.5, 2.0].map<DropdownMenuItem<double>>((
                double value,
              ) {
                return DropdownMenuItem<double>(
                  value: value,
                  child: Text(
                    '${value}x',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
          // Stop lesson button
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.black),
            onPressed: () => _stopLesson(backend),
            tooltip: 'Stop Lesson',
          ),
          // Voice control button
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _isListening ? Colors.green : Colors.black,
            ),
            onPressed: () {
              if (_isListening) {
                backend.stopListening();
                setState(() {
                  _isListening = false;
                });
              } else {
                _startListening();
              }
            },
          ),
          // Voice help button
          IconButton(
            icon: const Icon(Icons.help, color: Colors.black),
            onPressed: () => _showLessonVoiceHelp(backend),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(widget.lesson.description),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(label: Text('${widget.lesson.duration} min')),
                            const SizedBox(width: 8),
                            Chip(label: Text(widget.lesson.level)),
                            const SizedBox(width: 8),
                            Chip(label: Text(widget.lesson.type)),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('${_currentSpeed}x'),
                              backgroundColor: Colors.blue[100],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isReadingExercises)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _waitingForUserAnswer
                                  ? Colors.orange[100]
                                  : _allExercisesCompleted
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _waitingForUserAnswer
                                  ? 'Waiting for your answer... Say "option 1", "option 2", etc.'
                                  : _allExercisesCompleted
                                  ? 'All exercises completed! Say "next lesson" to continue.'
                                  : 'Exercise Mode: Question ${_currentExerciseIndex + 1} of ${widget.lesson.exercises.length}',
                              style: TextStyle(
                                color: _waitingForUserAnswer
                                    ? Colors.orange[800]
                                    : _allExercisesCompleted
                                    ? Colors.green[800]
                                    : Colors.blue[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Voice status and lesson status indicators
                if (_isListening || !_isLessonActive || _isTtsSpeaking)
                  Column(
                    children: [
                      if (_isTtsSpeaking)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Speaking... Please wait',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      if (_isListening && !_isTtsSpeaking)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.mic, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Listening for voice commands...',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      if (!_isLessonActive)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.pause, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Lesson paused. Say "start lesson" to continue.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),

                const SizedBox(height: 20),

                // Lesson content - ALWAYS SHOW BOTH SECTIONS AND EXERCISES
                Expanded(
                  child: ListView(
                    children: [
                      // Always show sections
                      if (widget.lesson.sections.isNotEmpty) ...[
                        Text(
                          'Lesson Content',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...widget.lesson.sections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final section = entry.value;
                          return _buildSection(
                            section,
                            index == _currentSectionIndex &&
                                !_isReadingExercises,
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Always show exercises if they exist
                      if (widget.lesson.exercises.isNotEmpty) ...[
                        Text(
                          'Exercises',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...widget.lesson.exercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return _buildExercise(
                            exercise,
                            index == _currentExerciseIndex &&
                                _isReadingExercises,
                          );
                        }),
                      ] else if (widget.lesson.sections.isEmpty) ...[
                        // Show message if no content at all
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No lesson content available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Complete button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeLessonAndNavigate(context, false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Complete Lesson'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Voice command feedback
          if (_lastCommand.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: _buildCommandFeedback(),
            ),
        ],
      ),

      // Voice help banner
      bottomNavigationBar: _buildVoiceHelpBanner(),
    );
  }

  Widget _buildCommandFeedback() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.voice_chat, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Command: "$_lastCommand"',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceHelpBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: const Border(top: BorderSide(color: Colors.blue)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lesson Voice Control Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Say "start lesson", "next section", or "start exercise"',
                  style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
          if (_isListening && !_isTtsSpeaking)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(LessonSection section, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrent ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.blue : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(section.content),
            if (section.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...section.examples.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $example'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExercise(Exercise exercise, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrent ? Colors.orange[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCurrent ? Colors.orange[800] : null,
              ),
            ),
            const SizedBox(height: 12),

            if (exercise.options.isNotEmpty) ...[
              Column(
                children: exercise.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return RadioListTile<String>(
                    title: Text(
                      'Option ${index + 1}: $option',
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: option,
                    groupValue: _selectedAnswers[exercise.id],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedAnswers[exercise.id] = value;
                      });
                      // Automatically check answer when option is selected manually
                      if (value != null) {
                        final backend = Provider.of<LessonsBackend>(
                          context,
                          listen: false,
                        );
                        _checkAnswer(exercise, value, backend);
                      }
                    },
                  );
                }).toList(),
              ),
            ],

            if (exercise.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                'Hint: ${exercise.hint}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[700],
                ),
              ),
            ],

            // Show result if answer was submitted
            if (_selectedAnswers[exercise.id] != null &&
                _selectedAnswers[exercise.id] == exercise.correctAnswer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Correct! ${exercise.explanation}',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedAnswers[exercise.id] != null &&
                _selectedAnswers[exercise.id] != exercise.correctAnswer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.close, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Incorrect',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correct answer: ${exercise.correctAnswer}',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.explanation,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _completeLessonAndNavigate(
    BuildContext context,
    bool goToNextLesson,
  ) async {
    final backend = Provider.of<LessonsBackend>(context, listen: false);

    try {
      await backend.completeLesson(widget.lesson.id);

      // Update progress tracking
      await ProgressService.updateLessonProgress(context, widget.lesson);

      if (goToNextLesson) {
        // Navigate back to lessons page which should show the next unlocked lesson
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson completed! Next lesson unlocked.')),
        );
      } else {
        // Just complete the lesson and stay on the same page
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson completed successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing lesson: $e')));
    }
  }
}
