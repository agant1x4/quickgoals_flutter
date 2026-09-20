import 'package:flutter/foundation.dart';
import '../models/task_models.dart';
import '../models/task_load.dart';

class StreakEngineNotifier extends ChangeNotifier {
  List<TaskItem> _tasks = [];
  int _currentStreak = 0;
  int _bestStreak = 0;
  final double _burnoutSoftCap = 15.0;

  List<TaskItem> get tasks => _tasks;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  void setTasks(List<TaskItem> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime? dateA, DateTime dateB) {
    if (dateA == null) return false;
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  /// Calculates total cognitive load for today's tasks
  double get totalDailyLoad {
    final now = DateTime.now();
    return _tasks
        .where((t) => _isSameDay(t.dueDate, now))
        .fold(0.0, (sum, t) => sum + t.cognitiveLoad);
  }

  /// Triggers warning when planned cognitive burden exceeds soft cap (15.0)
  bool get isRiskOfBurnout => totalDailyLoad > _burnoutSoftCap;

  /// Combined weight of all planned tasks for today
  double get totalPlannedWeight {
    final now = DateTime.now();
    return _tasks
        .where((t) => _isSameDay(t.dueDate, now))
        .fold(0.0, (sum, t) => sum + t.streakWeight);
  }

  /// Combined weight of completed tasks for today
  double get totalCompletedWeight {
    final now = DateTime.now();
    return _tasks
        .where((t) => _isSameDay(t.dueDate, now) && t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.streakWeight);
  }

  /// Completion percentage (0.0 to 100.0)
  double get completionScore {
    if (totalPlannedWeight == 0) return 100.0;
    return (totalCompletedWeight / totalPlannedWeight) * 100.0;
  }

  /// Evaluates daily streak state using 3-Tier System
  bool evaluateStreakEnd() {
    final score = completionScore;

    if (score >= 75.0) {
      _passStreak();
      return true;
    } else if (score >= 50.0) {
      final now = DateTime.now();
      final unfinishedToday = _tasks.where(
        (t) => _isSameDay(t.dueDate, now) && !t.isCompleted,
      );

      final qualifiesForGrace = unfinishedToday.every((task) {
        final isLowDifficulty = task.difficulty <= 2;
        final isSafeLoad =
            task.load != TaskLoad.stressed && task.load != TaskLoad.melting;
        return isLowDifficulty && isSafeLoad;
      });

      if (qualifiesForGrace) {
        _passStreak();
        return true;
      } else {
        _resetStreak();
        return false;
      }
    } else {
      _resetStreak();
      return false;
    }
  }

  void _passStreak() {
    _currentStreak++;
    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
    }
    notifyListeners();
  }

  void _resetStreak() {
    _currentStreak = 0;
    notifyListeners();
  }
}
