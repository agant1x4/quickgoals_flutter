import '../models/task_models.dart';

class SortingEngine {
  static void sortSubjects(List<SubjectTaskData> subjects, String strategy) {
    if (subjects.isEmpty) return;

    subjects.sort((a, b) {
      // Safe check for overdue presence - zero overdue items stay at the bottom
      if (a.totalOverdueTasks == 0 && b.totalOverdueTasks > 0) return 1;
      if (a.totalOverdueTasks > 0 && b.totalOverdueTasks == 0) return -1;
      if (a.totalOverdueTasks == 0 && b.totalOverdueTasks == 0) return 0;

      switch (strategy) {
        case 'Ice Cream':
          int scoreA = a.motivationLevel -
              (a.lessonDifficulty + a.quizDifficulty + a.assignmentDifficulty) -
              a.averageDurationMins;
          int scoreB = b.motivationLevel -
              (b.lessonDifficulty + b.quizDifficulty + b.assignmentDifficulty) -
              b.averageDurationMins;
          return scoreB.compareTo(scoreA); // Easiest floats to the top
        case 'Skyscraper':
          int scoreA = (a.lessonDifficulty +
                  a.quizDifficulty +
                  a.assignmentDifficulty) +
              a.averageDurationMins -
              a.motivationLevel;
          int scoreB = (b.lessonDifficulty +
                  b.quizDifficulty +
                  b.assignmentDifficulty) +
              b.averageDurationMins -
              b.motivationLevel;
          return scoreB.compareTo(scoreA); // Hardest floats to the top
        case 'Battleship':
          int scoreA = (a.totalOverdueTasks * 3) + a.overdueAge;
          int scoreB = (b.totalOverdueTasks * 3) + b.overdueAge;
          return scoreB.compareTo(scoreA); // Heaviest penalty overdue floats to the top
        default:
          return b.totalOverdueTasks.compareTo(a.totalOverdueTasks);
      }
    });
  }
}