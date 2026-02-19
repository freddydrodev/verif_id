import 'package:flutter/material.dart';
import '../utils/verif_id_constants.dart';

/// Overlay with dimmed background, rounded-rect cutout, and corner bracket
/// guides for document scanning.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DocOverlayPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _DocOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Dimmed background with rounded-rect cutout ──
    final cutoutW = size.width * VerifIdConstants.docWidthFactor;
    final cutoutH = size.height * VerifIdConstants.docHeightFactor;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: cutoutW,
      height: cutoutH,
    );
    final rrect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(VerifIdConstants.bracketCornerRadius),
    );

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: VerifIdConstants.overlayDimOpacity)
      ..style = PaintingStyle.fill;

    final fullPath = Path()..addRect(Offset.zero & size);
    final cutoutPath = Path()..addRRect(rrect);
    final overlay =
        Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(overlay, dimPaint);

    // ── Corner brackets ──
    final bracketPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = VerifIdConstants.bracketStroke
      ..strokeCap = StrokeCap.round;

    const len = VerifIdConstants.bracketLength;
    const r = VerifIdConstants.bracketCornerRadius;
    final l = cutoutRect.left;
    final t = cutoutRect.top;
    final ri = cutoutRect.right;
    final b = cutoutRect.bottom;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + r)
        ..quadraticBezierTo(l, t, l + r, t)
        ..lineTo(l + len, t),
      bracketPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(ri - len, t)
        ..lineTo(ri - r, t)
        ..quadraticBezierTo(ri, t, ri, t + r)
        ..lineTo(ri, t + len),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(l, b - len)
        ..lineTo(l, b - r)
        ..quadraticBezierTo(l, b, l + r, b)
        ..lineTo(l + len, b),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(ri - len, b)
        ..lineTo(ri - r, b)
        ..quadraticBezierTo(ri, b, ri, b - r)
        ..lineTo(ri, b - len),
      bracketPaint,
    );

    // ── Guide text below cutout ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Cadrez votre document',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        cutoutRect.bottom + 12,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
