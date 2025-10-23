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

    // Group lessons by type (using type as category)
    final Map<String, List<Lesson>> lessonsByType = {};
    for (var lesson in levelLessons) {
      final type = lesson.type;
      if (!lessonsByType.containsKey(type)) {
        lessonsByType[type] = [];
      }
      lessonsByType[type]!.add(lesson);
    }

    return Scaffold(
      appBar: AppBar(title: Text('$level Lessons - Categories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessonsByType.length,
        itemBuilder: (context, index) {
          final type = lessonsByType.keys.elementAt(index);
          final typeLessons = lessonsByType[type]!;

          return _buildCategoryCard(context, type, typeLessons, lessonsBackend);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String type,
    List<Lesson> lessons,
    LessonsBackend lessonsBackend,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 24),
                const SizedBox(width: 12),
                Text(
                  _formatTypeName(type),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${lessons.length} lessons available',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...lessons.map(
              (lesson) => _buildLessonItem(context, lesson, lessonsBackend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem(
    BuildContext context,
    Lesson lesson,
    LessonsBackend lessonsBackend,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            const SizedBox(height: 4),
            Text(
              lesson.description,
              style: TextStyle(
                fontSize: 12,
                color: lesson.isUnlocked ? Colors.black54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${lesson.duration} min',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.category, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  lesson.type,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: lesson.isUnlocked
            ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
            : const Icon(Icons.lock, size: 14, color: Colors.grey),
        onTap: lesson.isUnlocked ? () => _startLesson(context, lesson) : null,
      ),
    );
  }

  String _formatTypeName(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'grammar':
        return Icons.article;
      case 'vocabulary':
        return Icons.wordpress;
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'conversation':
        return Icons.chat;
      case 'listening':
        return Icons.headphones;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit;
      case 'business':
        return Icons.business;
      default:
        return Icons.school;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'grammar':
        return Colors.blue;
      case 'vocabulary':
        return Colors.green;
      case 'pronunciation':
        return Colors.orange;
      case 'conversation':
        return Colors.purple;
      case 'listening':
        return Colors.red;
      case 'reading':
        return Colors.teal;
      case 'writing':
        return Colors.pink;
      case 'business':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getLessonColor(String type) {
    switch (type) {
      case 'grammar':
        return Colors.blue;
      case 'vocabulary':
        return Colors.green;
      case 'pronunciation':
        return Colors.orange;
      case 'conversation':
        return Colors.purple;
      case 'listening':
        return Colors.red;
      case 'reading':
        return Colors.teal;
      case 'writing':
        return Colors.pink;
      case 'business':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'grammar':
        return Icons.article;
      case 'vocabulary':
        return Icons.wordpress;
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'conversation':
        return Icons.chat;
      case 'listening':
        return Icons.headphones;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit;
      case 'business':
        return Icons.business;
      default:
        return Icons.school;
    }
  }

  void _startLesson(BuildContext context, Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LessonDetailPage(lesson: lesson)),
    );
  }
}
