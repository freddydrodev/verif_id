import 'package:flutter/material.dart';

/// A simple, reusable face overlay: dimmed background with a centered oval
/// guide to help users align their face for a selfie.
class FaceOverlay extends StatelessWidget {
  const FaceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FaceOverlayPainter(Theme.of(context).colorScheme),
        size: Size.infinite,
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final ColorScheme colorScheme;
  _FaceOverlayPainter(this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDim = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;
    final path = Path()..addRect(rect);

    // Centered oval for the face, taller and narrower to better match a face
    final ovalWidth = size.width * 0.58;
    final ovalHeight = size.height * 0.70;
    final ovalRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: ovalWidth,
      height: ovalHeight,
    );

    final ovalPath = Path()..addOval(ovalRect);

    // Cut out the oval from the dimmed layer
    final overlay = Path.combine(PathOperation.difference, path, ovalPath);
    canvas.drawPath(overlay, paintDim);

    // Draw the oval border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
