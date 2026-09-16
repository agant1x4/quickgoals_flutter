import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main app/dashboard_phone.dart';
import '../main app/pomodoro.dart';
import '../main app/settings.dart';
import '../main app/review.dart'; // Calendar Schedule Page
import '../main app/weakness_tracker.dart'; // Strength & Weakness Tracker
import '../models/task_models.dart';

class AppMenuDrawer extends StatelessWidget {
  final List<SubjectTaskData>? userSubjects;

  const AppMenuDrawer({super.key, this.userSubjects});

  @override
  Widget build(BuildContext context) {
    final cleanSubjects = userSubjects ?? const [];
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width clamping
    final drawerWidth = (screenWidth * 0.75).clamp(280.0, 360.0);

    return SizedBox(
      width: drawerWidth,
      child: Material(
        elevation: 16,
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            bottomLeft: Radius.circular(30.0),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ROW ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3B55),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF2D3B55),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEFEFEF)),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  children: [
                    // Link 1: Dashboard
                    _buildMenuTile(
                      context,
                      icon: Icons.grid_view_rounded,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Link 2: Pomodoro Timer
                    _buildMenuTile(
                      context,
                      icon: Icons.timer_outlined,
                      title: 'Focus Timer',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PomodoroPage(userSubjects: cleanSubjects),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Link 3: Weakness & Strength Tracker
                    _buildMenuTile(
                      context,
                      icon: Icons.insights_rounded,
                      title: 'Weakness Tracker',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeaknessTrackerScreen(
                              userSubjects: cleanSubjects,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Link 4: Calendar Schedule
                    _buildMenuTile(
                      context,
                      icon: Icons.calendar_month_rounded,
                      title: 'Calendar',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReviewPage(userSubjects: cleanSubjects),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Link 5: Settings
                    _buildMenuTile(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2D3B55), size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3B55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}