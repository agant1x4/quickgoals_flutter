import 'package:flutter/material.dart';

// Simple model structure matching your data needs
class DrawerTask {
  final String id;
  final String title;
  final String type; // 'Lesson', 'Quiz', 'Assignment'

  DrawerTask({required this.id, required this.title, required this.type});
}

class SubjectTasksDrawer extends StatefulWidget {
  final String subjectTitle;
  final List<DrawerTask> tasks;
  final Function(String taskId) onTaskCompleted;

  const SubjectTasksDrawer({
    super.key,
    required this.subjectTitle,
    required this.tasks,
    required this.onTaskCompleted,
  });

  @override
  State<SubjectTasksDrawer> createState() => _SubjectTasksDrawerState();
}

class _SubjectTasksDrawerState extends State<SubjectTasksDrawer> {
  @override
  Widget build(BuildContext context) {
    // Separate the incoming tasks into your 3 clean sections
    final lessons = widget.tasks.where((t) => t.type == 'Lesson').toList();
    final quizzes = widget.tasks.where((t) => t.type == 'Quiz').toList();
    final assignments = widget.tasks
        .where((t) => t.type == 'Assignment')
        .toList();

    return Container(
      // White, rounded-corner container mimicking your wireframe
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The grey grab handle pill at the top center
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject Title
            Text(
              widget.subjectTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Flexible content area
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lessons.isNotEmpty) ...[
                      _buildSectionHeader('Lessons'),
                      _buildTaskGroup(lessons),
                      const Divider(height: 32, thickness: 1),
                    ],
                    if (quizzes.isNotEmpty) ...[
                      _buildSectionHeader('Quiz'),
                      _buildTaskGroup(quizzes),
                      const Divider(height: 32, thickness: 1),
                    ],
                    if (assignments.isNotEmpty) ...[
                      _buildSectionHeader('Assignments'),
                      _buildTaskGroup(assignments),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Instructional Guide Button
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Swipe to complete',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTaskGroup(List<DrawerTask> sectionTasks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sectionTasks.length,
      itemBuilder: (context, index) {
        final task = sectionTasks[index];
        final bool isActive =
            index == 0; // First item is normal, others fade out

        return Opacity(
          opacity: isActive ? 1.0 : 0.4,
          child: Dismissible(
            key: Key(task.id),
            // Lock swipes on the locked/faded upcoming sequential links
            direction: isActive
                ? DismissDirection.startToEnd
                : DismissDirection.none,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              color: Colors.greenAccent[400],
              child: const Icon(Icons.check, color: Colors.white),
            ),
            onDismissed: (_) {
              widget.onTaskCompleted(task.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  // Dot system matching the wireframe
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isActive ? Colors.orange : Colors.blueAccent[100],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
