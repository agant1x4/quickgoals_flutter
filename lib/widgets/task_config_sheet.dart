import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_models.dart';
import 'geometry.dart';

class TaskConfigSheet extends StatefulWidget {
  final List<SubjectTaskData> userSubjects;
  final Function(SubjectTaskData, TaskItem) onTaskCreated;

  const TaskConfigSheet({
    super.key,
    required this.userSubjects,
    required this.onTaskCreated,
  });

  @override
  State<TaskConfigSheet> createState() => _TaskConfigSheetState();
}

class _TaskConfigSheetState extends State<TaskConfigSheet> {
  int activeCarouselIndex = 0;
  int currentDrawerStep = 1;

  String selectedTaskType = 'Lesson';
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime selectedDueDate = DateTime.now().add(const Duration(days: 1));
  int selectedDurationMinutes = 30;
  int selectedDifficulty = 3;

  @override
  void dispose() {
    taskTitleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFB75E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E2841),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _submitTask() {
    if (widget.userSubjects.isEmpty) return;

    final subject = widget.userSubjects[activeCarouselIndex];
    final String title = taskTitleController.text.trim().isNotEmpty
        ? taskTitleController.text.trim()
        : '$selectedTaskType Session';

    final String id = 'task_${DateTime.now().millisecondsSinceEpoch}';

    final newTask = TaskItem(
      id: id,
      title: title,
      type: selectedTaskType,
      description: descriptionController.text.trim(),
      dueDate: selectedDueDate,
      difficulty: selectedDifficulty,
      isCompleted: false,
      durationMinutes: selectedDurationMinutes,
      subjectName: subject.name,
    );

    widget.onTaskCreated(subject, newTask);
  }

  @override
  Widget build(BuildContext context) {
    final activeSubject = widget.userSubjects.isNotEmpty
        ? widget.userSubjects[activeCarouselIndex]
        : null;

    return Padding(
      padding: EdgeInsets.only(
        top: 14,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (currentDrawerStep == 1) ...[
                Center(
                  child: Text(
                    'Choose a subject',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 145,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.userSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = widget.userSubjects[index];
                      final isChosen = activeCarouselIndex == index;

                      final Color cardColor = isChosen
                          ? subject.subjectColor
                          : subject.subjectColor.withValues(alpha: 0.75);

                      return GestureDetector(
                        onTap: () =>
                            setState(() => activeCarouselIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 165,
                          margin: const EdgeInsets.only(
                            right: 14,
                            bottom: 12,
                            top: 4,
                            left: 4,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: cardColor,
                            shape: const FigmaSmoothRectBorder(
                              radius: 24.0,
                              smoothing: 0.60,
                            ),
                            shadows: isChosen
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subject.name,
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '• ${subject.taskList.where((t) => !t.isCompleted).length} pending',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => setState(() => currentDrawerStep = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB75E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      'Configure Task Details',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],

              if (currentDrawerStep == 2) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black54),
                      onPressed: () => setState(() => currentDrawerStep = 1),
                    ),
                    Expanded(
                      child: Text(
                        'New Task for ${activeSubject?.name ?? ''}',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Task Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedTaskType,
                  decoration: InputDecoration(
                    labelText: 'Task Type',
                    labelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB75E),
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: ['Lesson', 'Quiz', 'Assignment', 'Project', 'Exam']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedTaskType = val ?? 'Lesson'),
                ),
                const SizedBox(height: 12),

                // Task Title
                TextField(
                  controller: taskTitleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g., Read Chapter 4 / Practice Problems',
                    labelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB75E),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description Field
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description / Notes (Optional)',
                    labelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB75E),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Deadline / Due Date Picker & Duration Row
                Row(
                  children: [
                    // Due Date Button
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDueDate(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deadline / Due Date',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Color(0xFFFFB75E),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _formatDate(selectedDueDate),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E2841),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Duration Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedDurationMinutes,
                        decoration: InputDecoration(
                          labelText: 'Est. Duration',
                          labelStyle: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: [15, 25, 30, 45, 60, 90, 120]
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m mins'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedDurationMinutes = v ?? 30),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Difficulty Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difficulty Level:',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            starValue <= selectedDifficulty
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFB75E),
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedDifficulty = starValue;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB75E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      'Create Task',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
