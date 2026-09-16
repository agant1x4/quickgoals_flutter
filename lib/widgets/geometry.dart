import 'dart:math';
import 'package:flutter/material.dart';

class FigmaSmoothRectBorder extends OutlinedBorder {
  final double radius;
  final double smoothing;

  const FigmaSmoothRectBorder({
    this.radius = 30.0,
    this.smoothing = 0.60,
    super.side,
  });

  @override
  ShapeBorder scale(double t) {
    return FigmaSmoothRectBorder(
      radius: radius * t,
      smoothing: smoothing,
      side: side.scale(t),
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double w = rect.width;
    final double h = rect.height;
    final double r = radius;
    final double s = smoothing;

    double b = r * (1.0 + s);
    if (b > w / 2.0) b = w / 2.0;
    if (b > h / 2.0) b = h / 2.0;

    const double k = 0.58;
    final Path path = Path();

    path.moveTo(rect.left, rect.top + b);

    path.cubicTo(
      rect.left,
      rect.top + b - b * k,
      rect.left + b - b * k,
      rect.top,
      rect.left + b,
      rect.top,
    );

    path.lineTo(rect.right - b, rect.top);

    path.cubicTo(
      rect.right - b + b * k,
      rect.top,
      rect.right,
      rect.top + b - b * k,
      rect.right,
      rect.top + b,
    );

    path.lineTo(rect.right, rect.bottom - b);

    path.cubicTo(
      rect.right,
      rect.bottom - b + b * k,
      rect.right - b + b * k,
      rect.bottom,
      rect.right - b,
      rect.bottom,
    );

    path.lineTo(rect.left + b, rect.bottom);

    path.cubicTo(
      rect.left + b - b * k,
      rect.bottom,
      rect.left,
      rect.bottom - b + b * k,
      rect.left,
      rect.bottom - b,
    );

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid) {
      final paint = side.toPaint();
      final path = getOuterPath(rect, textDirection: textDirection);
      canvas.drawPath(path, paint);
    }
  }

  @override
  OutlinedBorder copyWith({
    BorderSide? side,
    double? radius,
    double? smoothing,
  }) {
    return FigmaSmoothRectBorder(
      radius: radius ?? this.radius,
      smoothing: smoothing ?? this.smoothing,
      side: side ?? this.side,
    );
  }
}

class SmoothPentagonPainter extends CustomPainter {
  final Color color;

  SmoothPentagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double cx = size.width / 2;
    final double cy = size.height / 2 + 0.5;
    final double r = size.width / 2;

    final List<Offset> vertices = [];
    for (int i = 0; i < 5; i++) {
      double angle = -1.57079632679 + (i * 2.0 * pi / 5.0);
      vertices.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }

    final Path path = Path();
    const double t = 0.22;

    final Offset initialMid = Offset.lerp(vertices[4], vertices[0], 0.5)!;
    path.moveTo(initialMid.dx, initialMid.dy);

    for (int i = 0; i < 5; i++) {
      final Offset current = vertices[i];
      final Offset next = vertices[(i + 1) % 5];
      final Offset prev = vertices[(i - 1 + 5) % 5];

      final Offset entryPoint = Offset.lerp(current, prev, t)!;
      final Offset exitPoint = Offset.lerp(current, next, t)!;

      path.lineTo(entryPoint.dx, entryPoint.dy);
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        exitPoint.dx,
        exitPoint.dy,
      );
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SmoothPentagonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
