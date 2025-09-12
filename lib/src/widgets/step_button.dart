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
    final btn = ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      icon: Text(label),
      label: Icon(Icons.arrow_forward),
    );

    return btn;
  }
}
