// lib/pages/lesson_categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lessons_backend.dart';
import '../models/lesson_model.dart';
import 'lesson_detail_page.dart';

class LessonCategoriesPage extends StatelessWidget {
  final String level;

  const LessonCategoriesPage({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final lessonsBackend = Provider.of<LessonsBackend>(context);
    final levelLessons = lessonsBackend.getLessonsByLevel(level);
    
    // Group lessons by category
    final Map<String, List<Lesson>> lessonsByCategory = {};
    for (var lesson in levelLessons) {
      final category = lesson.category;
      if (!lessonsByCategory.containsKey(category)) {
        lessonsByCategory[category] = [];
      }
      lessonsByCategory[category]!.add(lesson);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$level Lessons - Categories'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: lessonsByCategory.length,
        itemBuilder: (context, index) {
          final category = lessonsByCategory.keys.elementAt(index);
          final categoryLessons = lessonsByCategory[category]!;
          
          return _buildCategoryCard(
            context, // Pass context here
            category,
            categoryLessons,
            lessonsBackend,
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, // Add context parameter
    String category,
    List<Lesson> lessons,
    LessonsBackend lessonsBackend,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  _formatCategoryName(category),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(category),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '${lessons.length} lessons available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            ...lessons.map((lesson) => _buildLessonItem(context, lesson, lessonsBackend)), // Pass context here
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem(
    BuildContext context, // Add context parameter
    Lesson lesson, 
    LessonsBackend lessonsBackend
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lesson.isUnlocked
              ? _getLessonColor(lesson.type)
              : Colors.grey,
          child: Icon(
            _getLessonIcon(lesson.type),
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: lesson.isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              lesson.description,
              style: TextStyle(
                fontSize: 12,
                color: lesson.isUnlocked ? Colors.black54 : Colors.grey,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${lesson.duration} min',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                SizedBox(width: 12),
                Icon(Icons.category, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  lesson.type,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: lesson.isUnlocked
            ? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
            : Icon(Icons.lock, size: 14, color: Colors.grey),
        onTap: lesson.isUnlocked
            ? () => _startLesson(context, lesson) // Now context is available
            : null,
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tenses': return Icons.timeline;
      case 'idioms': return Icons.lightbulb;
      case 'verbs': return Icons.dynamic_form;
      case 'phrases': return Icons.chat;
      case 'pronunciation': return Icons.record_voice_over;
      case 'vocabulary': return Icons.wordpress;
      case 'conversation': return Icons.people;
      case 'grammar': return Icons.article;
      case 'business': return Icons.business;
      case 'writing': return Icons.edit;
      case 'reading': return Icons.menu_book;
      default: return Icons.school;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tenses': return Colors.blue;
      case 'idioms': return Colors.orange;
      case 'verbs': return Colors.green;
      case 'phrases': return Colors.purple;
      case 'pronunciation': return Colors.red;
      case 'vocabulary': return Colors.teal;
      case 'conversation': return Colors.pink;
      case 'grammar': return Colors.indigo;
      case 'business': return Colors.brown;
      case 'writing': return Colors.cyan;
      case 'reading': return Colors.deepOrange;
      default: return Colors.blueGrey;
    }
  }

  Color _getLessonColor(String type) {
    switch (type) {
      case 'grammar': return Colors.blue;
      case 'vocabulary': return Colors.green;
      case 'pronunciation': return Colors.orange;
      case 'conversation': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'grammar': return Icons.article;
      case 'vocabulary': return Icons.wordpress;
      case 'pronunciation': return Icons.record_voice_over;
      case 'conversation': return Icons.chat;
      default: return Icons.school;
    }
  }

  void _startLesson(BuildContext context, Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailPage(lesson: lesson),
      ),
    );
  }
}