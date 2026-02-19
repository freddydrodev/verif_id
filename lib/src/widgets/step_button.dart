import 'package:flutter/material.dart';
import '../utils/verif_id_constants.dart';

class StepButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  final IconData? icon;

  /// When true, renders as a 72px circular camera-shutter button
  /// (outer ring + filled inner circle). [label] is ignored visually.
  final bool isCircular;

  const StepButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
    this.loading = false,
    this.icon,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircular) return _buildCircular(context);
    return _buildRectangle(context);
  }

  Widget _buildCircular(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: VerifIdConstants.captureOuterSize,
          height: VerifIdConstants.captureOuterSize,
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.primary,
                    ),
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary,
                      width: VerifIdConstants.captureBorderWidth,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: VerifIdConstants.captureInnerSize,
                      height: VerifIdConstants.captureInnerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRectangle(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        primary ? theme.colorScheme.primary : Colors.transparent;
    final fg =
        primary ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
    final border = primary
        ? BorderSide.none
        : BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3));

    return SizedBox(
      width: double.infinity,
      height: VerifIdConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          elevation: primary ? 2 : 0,
          shadowColor: primary
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(VerifIdConstants.buttonRadius),
            side: border,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: fg,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ] else if (primary) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}
