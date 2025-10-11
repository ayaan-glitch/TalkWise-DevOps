// lib/pages/lesson_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import 'lessons_backend.dart';

class LessonDetailPage extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailPage({Key? key, required this.lesson}) : super(key: key);

  @override
  _LessonDetailPageState createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  // Track selected answers for each exercise
  final Map<String, String?> _selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson header
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(widget.lesson.description),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          label: Text('${widget.lesson.duration} min'),
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Text(widget.lesson.level),
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Text(widget.lesson.type),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Lesson content
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Lesson Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),

                  // Sections
                  ...widget.lesson.sections.map((section) => _buildSection(section)),

                  // Exercises
                  if (widget.lesson.exercises.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    ...widget.lesson.exercises.map((exercise) => _buildExercise(exercise)),
                  ],
                ],
              ),
            ),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _completeLesson(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Complete Lesson'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(LessonSection section) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(section.content),
            if (section.examples.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...section.examples.map((example) => Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('• $example'),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExercise(Exercise exercise) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.question,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            
            if (exercise.options.isNotEmpty) ...[
              // Radio buttons for multiple choice questions
              Column(
                children: exercise.options.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option,
                      style: TextStyle(fontSize: 14),
                    ),
                    value: option,
                    groupValue: _selectedAnswers[exercise.id],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedAnswers[exercise.id] = value;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              
              // Submit button for the exercise
              if (_selectedAnswers[exercise.id] != null)
                ElevatedButton(
                  onPressed: () => _submitExerciseAnswer(exercise),
                  child: Text('Submit Answer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
            
            if (exercise.hint != null) ...[
              SizedBox(height: 8),
              Text(
                'Hint: ${exercise.hint}',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue[700]),
              ),
            ],
            
            // Show result if answer was submitted
            if (_selectedAnswers[exercise.id] != null && 
                _selectedAnswers[exercise.id] == exercise.correctAnswer) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
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
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.close, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Incorrect',
                          style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Correct answer: ${exercise.correctAnswer}',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                    SizedBox(height: 4),
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

  void _submitExerciseAnswer(Exercise exercise) {
    final backend = Provider.of<LessonsBackend>(context, listen: false);
    final userAnswer = _selectedAnswers[exercise.id] ?? '';
    
    // Submit the exercise attempt
    backend.submitExerciseAttempt(
      widget.lesson.id,
      exercise.id,
      userAnswer,
    );

    // Show feedback
    final isCorrect = userAnswer == exercise.correctAnswer;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct! Well done!' : 'Try again!'),
        backgroundColor: isCorrect ? Colors.green : Colors.orange,
      ),
    );

    // Update the UI
    setState(() {});
  }

  void _completeLesson(BuildContext context) async {
    final backend = Provider.of<LessonsBackend>(context, listen: false);

    try {
      await backend.completeLesson(widget.lesson.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lesson completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing lesson: $e')),
      );
    }
  }
}