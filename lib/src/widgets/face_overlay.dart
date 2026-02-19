import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/verif_id_constants.dart';

/// A face overlay: dimmed background with a centered oval guide and animated
/// dashed border to help users align their face for a selfie.
class FaceOverlay extends StatefulWidget {
  const FaceOverlay({super.key});

  @override
  State<FaceOverlay> createState() => _FaceOverlayState();
}

class _FaceOverlayState extends State<FaceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _FaceOverlayPainter(
              dashOffset: _controller.value * 20,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final double dashOffset;

  _FaceOverlayPainter({required this.dashOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Dimmed overlay
    final paintDim = Paint()
      ..color = Colors.black.withValues(alpha: VerifIdConstants.overlayDimOpacity)
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;
    final path = Path()..addRect(rect);

    // Centered oval
    final ovalWidth = size.width * VerifIdConstants.ovalWidthFactor;
    final ovalHeight = size.height * VerifIdConstants.ovalHeightFactor;
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * VerifIdConstants.ovalCenterYFactor),
      width: ovalWidth,
      height: ovalHeight,
    );

    final ovalPath = Path()..addOval(ovalRect);
    final overlay = Path.combine(PathOperation.difference, path, ovalPath);
    canvas.drawPath(overlay, paintDim);

    // Animated dashed border around the oval
    _drawDashedOval(canvas, ovalRect);

    // Hint text at top of oval
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Placez votre visage',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textX = (size.width - textPainter.width) / 2;
    final textY = ovalRect.top - textPainter.height - 12;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  void _drawDashedOval(Canvas canvas, Rect ovalRect) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashLength = 10.0;
    const gapLength = 8.0;

    // Approximate oval perimeter
    final a = ovalRect.width / 2;
    final b = ovalRect.height / 2;
    final perimeter =
        math.pi * (3 * (a + b) - math.sqrt((3 * a + b) * (a + 3 * b)));
    final cx = ovalRect.center.dx;
    final cy = ovalRect.center.dy;

    double distance = dashOffset;
    bool drawing = true;

    while (distance < perimeter) {
      final segLen = drawing ? dashLength : gapLength;
      final start = distance;
      final end = (distance + segLen).clamp(0.0, perimeter);

      if (drawing) {
        final path = Path();
        bool first = true;
        for (double d = start; d <= end; d += 1.0) {
          final t = (d / perimeter) * 2 * math.pi;
          final x = cx + a * math.cos(t);
          final y = cy + b * math.sin(t);
          if (first) {
            path.moveTo(x, y);
            first = false;
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, borderPaint);
      }

      distance = end;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _FaceOverlayPainter oldDelegate) =>
      oldDelegate.dashOffset != dashOffset;
}
