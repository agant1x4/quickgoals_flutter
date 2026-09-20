import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'geometry.dart';

class TaskPillCard extends StatelessWidget {
  final String title;
  final int durationMinutes;
  final Color subjectColor;
  final double width;
  final double height;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final DismissDirectionCallback? onDismissed;

  const TaskPillCard({
    super.key,
    required this.title,
    required this.durationMinutes,
    required this.subjectColor,
    this.width = 180.0,
    this.height = 72.0,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onTap,
    this.onLongPress,
    this.onDismissed,
  });

  String _formatDuration(int minutes) {
    if (minutes < 60) return "$minutes mins";
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return "$hours hr${hours > 1 ? 's' : ''}";
    return "$hours hr $remainingMins mins";
  }

  @override
  Widget build(BuildContext context) {
    const double effectiveRadius = 12.0;
    final BorderSide activeBorderSide = isSelected
        ? const BorderSide(color: Colors.white, width: 2.5)
        : BorderSide(color: Colors.white.withValues(alpha: 0.60), width: 1.2);

    final Widget pillContent = ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: ShapeDecoration(
            color: isSelected
                ? subjectColor.withValues(alpha: 0.95)
                : subjectColor.withValues(alpha: 0.75),
            shape: FigmaSmoothRectBorder(
              radius: effectiveRadius,
              smoothing: 0.60,
              side: activeBorderSide,
            ),
            shadows: [
              BoxShadow(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.40)
                    : subjectColor.withValues(alpha: 0.25),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: height > 60 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(durationMinutes),
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: subjectColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (isMultiSelectMode) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: pillContent,
      );
    }

    return Dismissible(
      key: ValueKey(title + durationMinutes.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: ShapeDecoration(
          color: const Color(0xFF53C580),
          shape: FigmaSmoothRectBorder(
            radius: effectiveRadius,
            smoothing: 0.60,
          ),
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: pillContent,
      ),
    );
  }
}
