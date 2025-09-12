import 'package:flutter/material.dart';

class StepButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const StepButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );

    return btn;
  }
}
