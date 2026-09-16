import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';

class MoodleService {
  final String baseUrl;
  final String token;

  MoodleService({
    required this.token,
    this.baseUrl = 'https://www.winguacademy.co.za',
  });

  static Future<String?> authenticateAndFetchToken({
    required String username,
    required String password,
    String portalUrl = 'https://www.winguacademy.co.za',
  }) async {
    final formattedUrl = portalUrl.endsWith('/')
        ? portalUrl.substring(0, portalUrl.length - 1)
        : portalUrl;
    final url = Uri.parse('$formattedUrl/login/token.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username.trim(),
          'password': password,
          'service': 'moodle_mobile_app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('token')) {
          return data['token'].toString().trim();
        }
      }
    } catch (e) {
      debugPrint('[Moodle Auth Exception]: $e');
    }
    return null;
  }

  bool _hasMatchingSubsequence(String str1, String str2, {int minLength = 3}) {
    final s1 = str1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final s2 = str2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (s1.length < minLength || s2.length < minLength) {
      return s1.contains(s2) || s2.contains(s1);
    }

    for (int i = 0; i <= s1.length - minLength; i++) {
      final sub = s1.substring(i, i + minLength);
      if (s2.contains(sub)) {
        return true;
      }
    }
    return false;
  }

  List<SubjectTaskData> mapMoodleActivitiesToSubjects({
    required List<Map<String, dynamic>> rawActivities,
    required List<SubjectTaskData> userSubjects,
  }) {
    if (rawActivities.isEmpty || userSubjects.isEmpty) return userSubjects;

    for (var raw in rawActivities) {
      final String rawCourseName = raw['course'] ?? '';
      final String rawTitle = raw['title'] ?? 'Moodle Task';
      final String description = raw['description'] ?? '';
      final DateTime dueDate = raw['dueDate'] as DateTime? ?? DateTime.now();
      final int duration = raw['durationMinutes'] as int? ?? 30;

      // Smart fuzzy match with >= 3 consecutive character overlap
      SubjectTaskData targetSubject = userSubjects.firstWhere(
        (subject) => _hasMatchingSubsequence(subject.name, rawCourseName, minLength: 3),
        orElse: () => userSubjects.first,
      );

      bool alreadyExists = targetSubject.taskList.any(
        (t) => t.title.trim().toLowerCase() == rawTitle.trim().toLowerCase(),
      );

      if (!alreadyExists) {
        targetSubject.taskList.add(
          TaskItem(
            id: raw['id'] ?? 'moodle_${DateTime.now().microsecondsSinceEpoch}',
            title: rawTitle,
            type: rawTitle.toLowerCase().contains('quiz')
                ? 'Quiz'
                : (rawTitle.toLowerCase().contains('assignment')
                    ? 'Assignment'
                    : 'Lesson'),
            description: description,
            dueDate: dueDate,
            durationMinutes: duration,
          ),
        );
      }
    }

    return userSubjects;
  }

  Future<http.Response?> _safePost(
    String wsFunction,
    Map<String, String> bodyFields,
  ) async {
    final formattedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$formattedBaseUrl/webservice/rest/server.php');

    final Map<String, String> payload = {
      'wstoken': token.trim(),
      'wsfunction': wsFunction,
      'moodlewsrestformat': 'json',
      ...bodyFields,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: payload,
      );
      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      debugPrint('[Network EXCEPTION] $wsFunction: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchMoodleActivities() async {
    List<Map<String, dynamic>> activities = [];

    try {
      final siteInfoRes = await _safePost('core_webservice_get_site_info', {});
      if (siteInfoRes == null) return _generateFallbackMockActivities();

      final siteData = jsonDecode(siteInfoRes.body);
      final int? userId = siteData['userid'];
      if (userId == null) return _generateFallbackMockActivities();

      final coursesRes = await _safePost('core_enrol_get_users_courses', {
        'userid': userId.toString(),
      });
      if (coursesRes == null) return _generateFallbackMockActivities();

      final dynamicCourses = jsonDecode(coursesRes.body);
      if (dynamicCourses is! List) return _generateFallbackMockActivities();

      for (var c in dynamicCourses) {
        if (c is Map && c['id'] != null) {
          int courseId = c['id'];
          String courseTitle = c['fullname'] ?? 'General';

          // Fetch assignments
          final assignRes = await _safePost('mod_assign_get_assignments', {
            'courseids[0]': courseId.toString(),
          });
          if (assignRes != null) {
            final assignData = jsonDecode(assignRes.body);
            if (assignData is Map && assignData['courses'] != null) {
              for (var courseBlock in assignData['courses']) {
                for (var assign in (courseBlock['assignments'] ?? [])) {
                  DateTime? dueDate;
                  if (assign['duedate'] != null && assign['duedate'] > 0) {
                    dueDate = DateTime.fromMillisecondsSinceEpoch(assign['duedate'] * 1000);
                  }
                  activities.add({
                    'id': 'moodle_assign_${assign['id']}',
                    'title': assign['name'] ?? 'Assignment',
                    'course': courseTitle,
                    'type': 'Assignment',
                    'dueDate': dueDate ?? DateTime.now(),
                    'durationMinutes': 45,
                    'description': _stripHtml(assign['intro'] ?? ''),
                  });
                }
              }
            }
          }

          // Fetch quizzes
          final quizRes = await _safePost('mod_quiz_get_quizzes_by_courses', {
            'courseids[0]': courseId.toString(),
          });
          if (quizRes != null) {
            final quizData = jsonDecode(quizRes.body);
            if (quizData is Map && quizData['quizzes'] != null) {
              for (var quiz in quizData['quizzes']) {
                DateTime? timeClose;
                if (quiz['timeclose'] != null && quiz['timeclose'] > 0) {
                  timeClose = DateTime.fromMillisecondsSinceEpoch(quiz['timeclose'] * 1000);
                }
                activities.add({
                  'id': 'moodle_quiz_${quiz['id']}',
                  'title': quiz['name'] ?? 'Quiz',
                  'course': courseTitle,
                  'type': 'Quiz',
                  'dueDate': timeClose ?? DateTime.now(),
                  'durationMinutes': 30,
                  'description': _stripHtml(quiz['intro'] ?? ''),
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Moodle pipeline error: $e');
    }

    if (activities.isEmpty) {
      return _generateFallbackMockActivities();
    }

    return activities;
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<Map<String, dynamic>> _generateFallbackMockActivities() {
    final now = DateTime.now();
    return [
      {
        'id': 'moodle_fallback_1',
        'title': 'Quiz 1: Data Structures Overview',
        'course': 'Computer Science',
        'type': 'Quiz',
        'description': 'Online quiz covering stacks, queues, and complexity analysis.',
        'dueDate': DateTime(now.year, now.month, now.day, 10, 0),
        'durationMinutes': 45,
      },
      {
        'id': 'moodle_fallback_2',
        'title': 'Assignment 2: Vector Calculus Set',
        'course': 'Mathematics',
        'type': 'Assignment',
        'description': 'Complete exercises from chapter 4. Upload scan to Moodle.',
        'dueDate': DateTime(now.year, now.month, now.day, 13, 30),
        'durationMinutes': 60,
      },
    ];
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('moodle_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('moodle_token', token.trim());
  }

  static Future<void> clearSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moodle_token');
  }
}
