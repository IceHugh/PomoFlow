
import 'dart:math';
import 'package:flutter/material.dart';

class ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  ProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 5.0;

    // Background Circle
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    // Only repaint if progress changed by more than 1% or colors changed
    final progressChanged = (oldDelegate.progress - progress).abs() > 0.01;
    final colorChanged = oldDelegate.color != color || oldDelegate.trackColor != trackColor;
    return progressChanged || colorChanged;
  }
}
