import 'package:flutter/material.dart';

/// A lightweight, reusable horizontal stepper that only mounts the
/// content of the currently active step.
///
/// This widget renders a horizontal header with step indicators and
/// titles, and a single content area below for the active step's widget.
/// It avoids building inactive step contents for performance and side-effect
/// isolation.
class HorizontalStepper extends StatelessWidget {
  /// Zero-based index of the currently active step.
  final int currentStep;

  /// The list of steps. Uses Flutter's [Step] to keep a familiar API
  /// for title/content/state.
  final List<Step> steps;

  /// Called when a step header is tapped.
  final ValueChanged<int>? onStepTapped;

  /// Optional padding around the content area.
  final EdgeInsetsGeometry contentPadding;

  /// Creates a horizontal stepper.
  const HorizontalStepper({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      key: const Key('horizontal_stepper_root'),
      mainAxisSize: MainAxisSize.max,
      children: [
        _Header(
          currentStep: currentStep,
          steps: steps,
          onStepTapped: null,
          colorScheme: colorScheme,
          textTheme: theme.textTheme,
        ),
        const SizedBox(height: 12),
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
    // Only build the active step's content.
    return steps[currentStep].content;
  }
}

class _Header extends StatelessWidget {
  final int currentStep;
  final List<Step> steps;
  final ValueChanged<int>? onStepTapped;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Header({
    required this.currentStep,
    required this.steps,
    required this.onStepTapped,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          key: const Key('horizontal_stepper_scroll'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                return _Connector(
                  isActiveOrComplete: index ~/ 2 < currentStep,
                  colorScheme: colorScheme,
                );
              }
              final stepIndex = index ~/ 2;
              final step = steps[stepIndex];
              final state = step.state;
              final isActive = stepIndex == currentStep;
              final isComplete =
                  state == StepState.complete || stepIndex < currentStep;
              return _StepChip(
                index: stepIndex,
                title: step.title,
                isActive: isActive,
                isComplete: isComplete,
                onTap: null,
                colorScheme: colorScheme,
                textTheme: textTheme,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final int index;
  final Widget title;
  final bool isActive;
  final bool isComplete;
  final ValueChanged<int>? onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _StepChip({
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
    final bgColor = isActive
        ? colorScheme.primary
        : (isComplete
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceVariant);
    final fgColor = isActive
        ? colorScheme.onPrimary
        : (isComplete
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant);

    return InkWell(
      key: Key('horizontal_stepper_step_$index'),
      onTap: onTap == null ? null : () => onTap!(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: fgColor,
              child: Icon(
                isComplete
                    ? Icons.check
                    : (isActive ? Icons.radio_button_checked : Icons.circle),
                size: 12,
                color: bgColor,
              ),
            ),
            const SizedBox(width: 8),
            DefaultTextStyle(
              style: (textTheme.labelLarge ?? const TextStyle()).copyWith(
                color: fgColor,
              ),
              child: title,
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool isActiveOrComplete;
  final ColorScheme colorScheme;

  const _Connector({
    required this.isActiveOrComplete,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isActiveOrComplete
          ? colorScheme.primary
          : colorScheme.outlineVariant,
    );
  }
}
