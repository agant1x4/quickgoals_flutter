import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';
import '../services/moodle_service.dart';
import '../widgets/geometry.dart';
import 'nav_drawer.dart';
import 'pomodoro.dart';

class ReviewPage extends StatefulWidget {
  final List<SubjectTaskData> userSubjects;

  const ReviewPage({super.key, this.userSubjects = const []});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

enum CalendarViewScope { day, week, month }

class _ReviewPageState extends State<ReviewPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  CalendarViewScope _currentView = CalendarViewScope.day;
  DateTime _selectedDate = DateTime.now();

  List<SubjectTaskData> _activeSubjects = [];
  _CalendarTaskWrapper? _selectedTask;

  // Colors matching design guidelines
  final Color _dayColor = const Color(0xFFFFB03B); // Warm Yellow/Orange
  final Color _weekColor = const Color(0xFF6C9EFF); // Soft Blue
  final Color _monthColor = const Color(0xFF9E9E9E); // Grey

  @override
  void initState() {
    super.initState();
    _activeSubjects = List.from(widget.userSubjects);
    _initializeCalendarAndSync();
  }

  Future<void> _initializeCalendarAndSync() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('moodle_token');

    // Load cached subject state if passed list was empty
    if (_activeSubjects.isEmpty) {
      final cachedJson = prefs.getString('quickgoals_user_subjects');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cachedJson);
          _activeSubjects = decoded
              .map((e) => SubjectTaskData.fromMap(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint("Failed to decode subject cache: $e");
        }
      }
    }

    // Default fallback subject if nothing exists
    if (_activeSubjects.isEmpty) {
      _activeSubjects = [
        SubjectTaskData(
          name: "General",
          subjectColor: const Color(0xFFFFB03B),
          taskList: [],
        ),
      ];
    }

    // Fetch live Moodle activities if token exists and perform smart mapping
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      try {
        final moodleService = MoodleService(token: savedToken.trim());
        final rawActivities = await moodleService.fetchMoodleActivities();
        _activeSubjects = moodleService.mapMoodleActivitiesToSubjects(
          rawActivities: rawActivities,
          userSubjects: _activeSubjects,
        );
        await _saveSubjectsCache();
      } catch (e) {
        debugPrint("Moodle direct sync error: $e");
      }
    }

    // Select initial task wrapper for side panel tablet view
    final todayTasks = _getTasksForSelectedScope();
    if (todayTasks.isNotEmpty) {
      _selectedTask = todayTasks.first;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSubjectsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _activeSubjects.map((s) => s.toMap()).toList();
    await prefs.setString('quickgoals_user_subjects', jsonEncode(jsonList));
  }

  List<_CalendarTaskWrapper> _getTasksForSelectedScope() {
    List<_CalendarTaskWrapper> items = [];
    for (var subject in _activeSubjects) {
      for (var task in subject.taskList) {
        if (task.dueDate == null) continue;

        bool include = false;
        if (_currentView == CalendarViewScope.day) {
          include = _isSameDay(task.dueDate!, _selectedDate);
        } else if (_currentView == CalendarViewScope.week) {
          final startOfWeek = _selectedDate.subtract(
            Duration(days: _selectedDate.weekday - 1),
          );
          final startOfDay = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final endOfWeek = startOfDay.add(
            const Duration(days: 6, hours: 23, minutes: 59),
          );
          include =
              task.dueDate!.isAfter(
                startOfDay.subtract(const Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfWeek);
        } else {
          include =
              task.dueDate!.month == _selectedDate.month &&
              task.dueDate!.year == _selectedDate.year;
        }

        if (include) {
          items.add(_CalendarTaskWrapper(subject: subject, task: task));
        }
      }
    }

    items.sort(
      (a, b) => (a.task.dueDate ?? DateTime.now()).compareTo(
        b.task.dueDate ?? DateTime.now(),
      ),
    );
    return items;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return "$minutes mins";
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return "$hours hr${hours > 1 ? 's' : ''}";
    }
    return "$hours hr $remainingMins mins";
  }

  void _showEditTaskModal(_CalendarTaskWrapper wrapper) {
    final titleController = TextEditingController(text: wrapper.task.title);
    final descController = TextEditingController(
      text: wrapper.task.description,
    );
    int selectedDuration = wrapper.task.durationMinutes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              title: Text(
                "Edit Activity",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Activity Title",
                        labelStyle: GoogleFonts.quicksand(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: GoogleFonts.quicksand(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "Duration:",
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value:
                              [
                                15,
                                30,
                                45,
                                60,
                                90,
                                120,
                              ].contains(selectedDuration)
                              ? selectedDuration
                              : 30,
                          items: [15, 30, 45, 60, 90, 120].map((m) {
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(_formatDuration(m)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedDuration = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.quicksand(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB03B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      wrapper.task.title = titleController.text.trim();
                      wrapper.task.description = descController.text.trim();
                      wrapper.task.durationMinutes = selectedDuration;
                    });
                    _saveSubjectsCache();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskDetailDrawer(_CalendarTaskWrapper wrapper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTaskDetailContent(wrapper, isModal: true),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: AppMenuDrawer(userSubjects: _activeSubjects),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB03B)),
              )
            : isTablet
            ? _buildTabletLayout()
            : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBar(),
        _buildViewSwitcher(),
        _buildDateHeader(),
        Expanded(child: _buildTimelineCanvasView()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Timeline Schedule Canvas
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewSwitcher(),
                    _buildDateHeader(),
                    Expanded(child: _buildTimelineCanvasView()),
                  ],
                ),
              ),
              Container(width: 1, color: const Color(0xFFEFEFEF)),
              // Right Column: Side Activity Detail Inspector Panel
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: _selectedTask != null
                      ? _buildTaskDetailContent(_selectedTask!)
                      : Center(
                          child: Text(
                            "Select an activity to view details",
                            style: GoogleFonts.quicksand(color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Calendar",
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
              color: Color(0xFF1E293B),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          _buildScopeChip("Day", CalendarViewScope.day, _dayColor),
          const SizedBox(width: 10),
          _buildScopeChip("Week", CalendarViewScope.week, _weekColor),
          const SizedBox(width: 10),
          _buildScopeChip("Month", CalendarViewScope.month, _monthColor),
        ],
      ),
    );
  }

  Widget _buildScopeChip(
    String label,
    CalendarViewScope scope,
    Color activeColor,
  ) {
    final bool isActive = _currentView == scope;
    return GestureDetector(
      onTap: () => setState(() => _currentView = scope),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: ShapeDecoration(
          color: isActive ? activeColor : const Color(0xFFE0E0E0),
          shape: const FigmaSmoothRectBorder(radius: 20, smoothing: 0.60),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF616161),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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

    String dayName = days[_selectedDate.weekday - 1];
    String monthName = months[_selectedDate.month - 1];
    String dateText = "$dayName  $monthName ${_selectedDate.day}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateText,
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "At a glance:",
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: const Color(0xFF64748B),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: const Color(0xFFFFB03B),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCanvasView() {
    final tasks = _getTasksForSelectedScope();
    final now = DateTime.now();
    final bool isToday = _isSameDay(_selectedDate, now);

    const double hourHeight = 72.0;
    const int startHour = 8;
    const int endHour = 18;
    final int totalHours = endHour - startHour + 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Stack(
        children: [
          // 1. Time Labels & Horizontal Grid Lines
          Column(
            children: List.generate(totalHours, (index) {
              final hour = startHour + index;
              final hourText = "${hour.toString().padLeft(2, '0')}:00";

              return SizedBox(
                height: hourHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          hourText,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // 2. Red Live Current Time Line Indicator
          if (isToday && now.hour >= startHour && now.hour <= endHour) ...[
            Builder(
              builder: (context) {
                final minutesFromStart =
                    ((now.hour - startHour) * 60) + now.minute;
                final topOffset = (minutesFromStart / 60.0) * hourHeight;

                return Positioned(
                  top: topOffset,
                  left: 48,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // 3. Dynamic Task Activity Pills scaled by duration
          ...List.generate(tasks.length, (index) {
            final item = tasks[index];
            final task = item.task;
            final subject = item.subject;

            final taskDate = task.dueDate ?? DateTime.now();
            final hour = taskDate.hour < startHour ? startHour : taskDate.hour;
            final minute = taskDate.minute;

            final minutesFromStart = ((hour - startHour) * 60) + minute;
            final topOffset = (minutesFromStart / 60.0) * hourHeight;

            // Height scaled to duration
            final double pillHeight =
                ((task.durationMinutes / 60.0) * hourHeight).clamp(48.0, 180.0);

            // Stagger horizontal position for overlapping slots
            final bool isShiftedRight = index % 2 == 1;
            final double leftPadding = isShiftedRight ? 190.0 : 68.0;
            final double pillWidth = isShiftedRight ? 160.0 : 180.0;

            final Color pillBgColor = subject.subjectColor;

            return Positioned(
              top: topOffset,
              left: leftPadding,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTask = item);
                  if (MediaQuery.of(context).size.width < 700) {
                    _showTaskDetailDrawer(item);
                  }
                },
                onDoubleTap: () => _showEditTaskModal(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: pillWidth,
                  height: pillHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: pillBgColor,
                    shape: const FigmaSmoothRectBorder(
                      radius: 16,
                      smoothing: 0.60,
                    ),
                    shadows: [
                      BoxShadow(
                        color: pillBgColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        maxLines: pillHeight > 60 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(task.durationMinutes),
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskDetailContent(
    _CalendarTaskWrapper wrapper, {
    bool isModal = false,
  }) {
    final task = wrapper.task;
    final subject = wrapper.subject;

    final String dueFormatted = task.dueDate != null
        ? "${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.year}"
        : "No Deadline";

    final String startTimeFormatted = task.dueDate != null
        ? "${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}"
        : "08:00";

    final String deadlineFormatted = task.dueDate != null
        ? "${task.dueDate!.add(Duration(minutes: task.durationMinutes)).hour.toString().padLeft(2, '0')}:${task.dueDate!.add(Duration(minutes: task.durationMinutes)).minute.toString().padLeft(2, '0')}"
        : "08:30";

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B)),
                onPressed: () => _showEditTaskModal(wrapper),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: ShapeDecoration(
              color: subject.subjectColor,
              shape: const FigmaSmoothRectBorder(radius: 12, smoothing: 0.60),
            ),
            child: Text(
              subject.name,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            task.description.isNotEmpty
                ? task.description
                : "concise description of activity",
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow("Duration:", _formatDuration(task.durationMinutes)),
          const SizedBox(height: 10),
          _buildDetailRow("Start Time:", startTimeFormatted),
          const SizedBox(height: 20),
          _buildDetailRow("Due date:", dueFormatted),
          const SizedBox(height: 10),
          _buildDetailRow("Deadline:", deadlineFormatted),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isModal) Navigator.pop(context);
                int sIndex = _activeSubjects.indexOf(subject);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PomodoroPage(
                      userSubjects: _activeSubjects,
                      initialSubjectIndex: sIndex < 0 ? 0 : sIndex,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                "Start Focus Session",
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB03B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _CalendarTaskWrapper {
  final SubjectTaskData subject;
  final TaskItem task;

  _CalendarTaskWrapper({required this.subject, required this.task});
}
