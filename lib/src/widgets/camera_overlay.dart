import 'package:flutter/material.dart';

/// Simple overlay to guide user where to place face or ID.
/// Keep minimal and reusable.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // a centered rounded-rect guide
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.78,
          heightFactor: 0.46,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 2),
              color: Colors.black12.withOpacity(0.0),
            ),
          ),
        ),
      ),
    );
  }
}
