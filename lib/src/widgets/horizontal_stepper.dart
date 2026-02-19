import 'package:flutter/material.dart';

/// A lightweight, reusable horizontal stepper that only mounts the
/// content of the currently active step.
///
/// Step label bubbles auto-scroll to keep the active step visible.
class HorizontalStepper extends StatelessWidget {
  /// Zero-based index of the currently active step.
  final int currentStep;

  /// The list of steps.
  final List<Step> steps;

  /// Called when a step header is tapped.
  final ValueChanged<int>? onStepTapped;

  /// Optional padding around the content area.
  final EdgeInsetsGeometry contentPadding;

  const HorizontalStepper({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('horizontal_stepper_root'),
      children: [
        _Header(
          currentStep: currentStep,
          steps: steps,
          onStepTapped: null,
        ),
        Expanded(
          child: Padding(
            padding: contentPadding,
            child: _ActiveContent(steps: steps, currentStep: currentStep),
          ),
        ),
      ],
    );
  }
}

class _ActiveContent extends StatelessWidget {
  final List<Step> steps;
  final int currentStep;

  const _ActiveContent({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return steps[currentStep].content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — auto-scrolls to the active step
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatefulWidget {
  final int currentStep;
  final List<Step> steps;
  final ValueChanged<int>? onStepTapped;

  const _Header({
    required this.currentStep,
    required this.steps,
    required this.onStepTapped,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _stepKeys;

  @override
  void initState() {
    super.initState();
    _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(covariant _Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate keys if step count changed
    if (widget.steps.length != _stepKeys.length) {
      _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    }
    if (widget.currentStep != oldWidget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    if (!mounted) return;
    final idx = widget.currentStep;
    if (idx < 0 || idx >= _stepKeys.length) return;
    final keyContext = _stepKeys[idx].currentContext;
    if (keyContext == null) return;

    Scrollable.ensureVisible(
      keyContext,
      alignment: 0.5, // center the active chip
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        key: const Key('horizontal_stepper_scroll'),
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              return _Connector(
                isActiveOrComplete: index ~/ 2 < widget.currentStep,
                colorScheme: cs,
              );
            }
            final stepIndex = index ~/ 2;
            final step = widget.steps[stepIndex];
            final state = step.state;
            final isActive = stepIndex == widget.currentStep;
            final isComplete =
                state == StepState.complete || stepIndex < widget.currentStep;

            return _StepChip(
              key: _stepKeys[stepIndex],
              index: stepIndex,
              title: step.title,
              isActive: isActive,
              isComplete: isComplete,
              onTap: null,
              colorScheme: cs,
              textTheme: tt,
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step chip — pill-style label bubble
// ─────────────────────────────────────────────────────────────────────────────

class _StepChip extends StatelessWidget {
  final int index;
  final Widget title;
  final bool isActive;
  final bool isComplete;
  final ValueChanged<int>? onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _StepChip({
    super.key,
    required this.index,
    required this.title,
    required this.isActive,
    required this.isComplete,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Colors
    final Color bg;
    final Color fg;
    final Color iconBg;
    final Color iconFg;

    if (isActive) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
      iconBg = colorScheme.onPrimary.withValues(alpha: 0.2);
      iconFg = colorScheme.onPrimary;
    } else if (isComplete) {
      bg = colorScheme.primary.withValues(alpha: 0.1);
      fg = colorScheme.primary;
      iconBg = colorScheme.primary.withValues(alpha: 0.15);
      iconFg = colorScheme.primary;
    } else {
      bg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = colorScheme.onSurface.withValues(alpha: 0.45);
      iconBg = colorScheme.onSurface.withValues(alpha: 0.08);
      iconFg = colorScheme.onSurface.withValues(alpha: 0.35);
    }

    return GestureDetector(
      key: Key('horizontal_stepper_step_$index'),
      onTap: onTap == null ? null : () => onTap!(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? null
              : Border.all(
                  color: isComplete
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step indicator circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Center(
                child: isComplete
                    ? Icon(Icons.check_rounded, size: 14, color: iconFg)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: iconFg,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            DefaultTextStyle(
              style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                color: fg,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
              child: title,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connector line between steps
// ─────────────────────────────────────────────────────────────────────────────

class _Connector extends StatelessWidget {
  final bool isActiveOrComplete;
  final ColorScheme colorScheme;

  const _Connector({
    required this.isActiveOrComplete,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 20,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActiveOrComplete
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
