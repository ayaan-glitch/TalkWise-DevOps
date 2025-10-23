// lib/pages/quiz_page.dart
import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class QuizPage extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback onQuizPassed;
  final VoidCallback onQuizFailed;

  const QuizPage({
    super.key,
    required this.quiz,
    required this.onQuizPassed,
    required this.onQuizFailed,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  final Map<String, String?> _selectedAnswers = {};
  bool _quizCompleted = false;
  int _score = 0;
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Header
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.quiz.description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            '${widget.quiz.questions.length} Questions',
                          ),
                          backgroundColor: Colors.blue[100],
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${widget.quiz.passingScore}% to Pass'),
                          backgroundColor: Colors.orange[100],
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${widget.quiz.duration} min'),
                          backgroundColor: Colors.green[100],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!_quizCompleted && widget.quiz.questions.isNotEmpty) ...[
              // Progress indicator
              LinearProgressIndicator(
                value:
                    (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
              ),
              const SizedBox(height: 16),

              // Question counter
              Text(
                'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              // Current question
              Expanded(
                child: _buildQuestion(
                  widget.quiz.questions[_currentQuestionIndex],
                ),
              ),

              // Navigation buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: _previousQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  const Spacer(),
                  if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Submit Quiz',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ] else if (_quizCompleted && _showResults) ...[
              // Quiz Results
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            (_score / widget.quiz.questions.length) >=
                                (widget.quiz.passingScore / 100)
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (_score / widget.quiz.questions.length) >=
                                  (widget.quiz.passingScore / 100)
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (_score / widget.quiz.questions.length) >=
                                    (widget.quiz.passingScore / 100)
                                ? Icons.check_circle
                                : Icons.warning,
                            size: 64,
                            color:
                                (_score / widget.quiz.questions.length) >=
                                    (widget.quiz.passingScore / 100)
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (_score / widget.quiz.questions.length) >=
                                    (widget.quiz.passingScore / 100)
                                ? 'Quiz Passed! 🎉'
                                : 'Quiz Not Passed',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color:
                                      (_score / widget.quiz.questions.length) >=
                                          (widget.quiz.passingScore / 100)
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You scored $_score out of ${widget.quiz.questions.length} '
                            '(${(_score / widget.quiz.questions.length * 100).round()}%)',
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Passing score: ${widget.quiz.passingScore}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              if ((_score / widget.quiz.questions.length) >=
                                  (widget.quiz.passingScore / 100)) {
                                widget.onQuizPassed();
                              } else {
                                widget.onQuizFailed();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_score / widget.quiz.questions.length) >=
                                      (widget.quiz.passingScore / 100)
                                  ? Colors.green
                                  : Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              (_score / widget.quiz.questions.length) >=
                                      (widget.quiz.passingScore / 100)
                                  ? 'Continue Learning'
                                  : 'Review Lessons',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(QuizQuestion question) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  title: Text(option, style: const TextStyle(fontSize: 16)),
                  value: option,
                  groupValue: _selectedAnswers[question.id],
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswers[question.id] = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
        _currentQuestionIndex++;
      }
    });
  }

  void _previousQuestion() {
    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      }
    });
  }

  void _submitQuiz() {
    int score = 0;
    for (var question in widget.quiz.questions) {
      if (_selectedAnswers[question.id] == question.correctAnswer) {
        score++;
      }
    }

    setState(() {
      _score = score;
      _quizCompleted = true;
      _showResults = true;
    });
  }
}
