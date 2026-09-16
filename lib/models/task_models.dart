import 'package:flutter/material.dart';

// --- TASK ITEM DATA MODEL ---
class TaskItem {
  final String id; // Secure unique ID to prevent Dismissible swipe crashes
  String title;
  String type; // 'Lesson', 'Quiz', 'Assignment'
  String description;
  int difficulty;
  DateTime? dueDate;
  bool isCompleted;
  int durationMinutes; // Est. study block duration in minutes
  String? subjectName; // Link task directly to a specific subject name

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    this.description = '',
    this.difficulty = 3,
    this.dueDate,
    this.isCompleted = false,
    this.durationMinutes = 30,
    this.subjectName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'difficulty': difficulty,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'durationMinutes': durationMinutes,
      'subjectName': subjectName,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    final String fallbackId =
        '${DateTime.now().millisecondsSinceEpoch}_${(map['title'] ?? '').hashCode}';

    return TaskItem(
      id: map['id'] ?? fallbackId,
      title: map['title'] ?? '',
      type: map['type'] ?? 'Lesson',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 3,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      durationMinutes: map['durationMinutes'] ?? 30,
      subjectName: map['subjectName'],
    );
  }
}

// --- SUBJECT TASK DATA MODEL ---
class SubjectTaskData {
  final String name;
  final Color subjectColor;

  int lessonDifficulty;
  int quizDifficulty;
  int assignmentDifficulty;

  int motivationLevel;
  int averageDurationMins;

  // Streak tracking fields added safely without breaking legacy schema
  int currentStreak;
  int bestStreak;
  DateTime? lastCompletedDate;

  List<TaskItem> taskList;

  SubjectTaskData({
    required this.name,
    required this.subjectColor,
    this.lessonDifficulty = 3,
    this.quizDifficulty = 3,
    this.assignmentDifficulty = 3,
    this.motivationLevel = 3,
    this.averageDurationMins = 30,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
    List<TaskItem>? taskList,
  }) : taskList = taskList ?? [];

  // Register completion and update current/best streak counts
  void registerTaskCompletion() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastCompletedDate == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime(
        lastCompletedDate!.year,
        lastCompletedDate!.month,
        lastCompletedDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak += 1;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    }

    lastCompletedDate = now;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
  }

  // Compute total dynamic overdue tasks reactively
  int get totalOverdueTasks {
    final now = DateTime.now();
    return taskList
        .where(
          (t) =>
              !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now),
        )
        .length;
  }

  // Calculate overdue age in days safely
  int get overdueAge {
    final now = DateTime.now();
    int maxDays = 0;
    for (var task in taskList) {
      if (!task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.isBefore(now)) {
        final difference = now.difference(task.dueDate!).inDays;
        if (difference > maxDays) {
          maxDays = difference;
        }
      }
    }
    return maxDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subjectColor': subjectColor.toARGB32(),
      'lessonDifficulty': lessonDifficulty,
      'quizDifficulty': quizDifficulty,
      'assignmentDifficulty': assignmentDifficulty,
      'motivationLevel': motivationLevel,
      'averageDurationMins': averageDurationMins,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'taskList': taskList.map((t) => t.toMap()).toList(),
    };
  }

  factory SubjectTaskData.fromMap(Map<String, dynamic> map) {
    return SubjectTaskData(
      name: map['name'] ?? '',
      subjectColor: Color(map['subjectColor'] ?? 0xFFFFB75E),
      lessonDifficulty: map['lessonDifficulty'] ?? 3,
      quizDifficulty: map['quizDifficulty'] ?? 3,
      assignmentDifficulty: map['assignmentDifficulty'] ?? 3,
      motivationLevel: map['motivationLevel'] ?? 3,
      averageDurationMins: map['averageDurationMins'] ?? 30,
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'])
          : null,
      taskList: map['taskList'] != null
          ? List<TaskItem>.from(
              (map['taskList'] as List).map((t) => TaskItem.fromMap(t)),
            )
          : [],
    );
  }
}
