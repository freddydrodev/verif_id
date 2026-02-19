import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/step_button.dart';
import '../utils/verif_id_constants.dart';

/// ReviewSubmitStep
/// - Shows preview of selfie, id front/back with gradient label overlays
/// - Scrollable (fixes overflow on small screens)
/// - Buttons: Soumettre (calls onSubmit), Recommencer (calls onReverify)
class ReviewSubmitStep extends StatefulWidget {
  final Map<String, dynamic>? selfie;
  final Map<String, dynamic>? idFront;
  final Map<String, dynamic>? idBack;
  final Future<void> Function() onSubmit;
  final VoidCallback onReverify;
  final VoidCallback? onBack;

  const ReviewSubmitStep({
    super.key,
    required this.onSubmit,
    required this.onReverify,
    this.selfie,
    this.idFront,
    this.idBack,
    this.onBack,
  });

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  bool _submitting = false;

  Future<void> _handleSubmit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final selfiePath =
        widget.selfie != null ? (widget.selfie!['selfie_path'] as String?) : null;
    final idFrontPath = widget.idFront != null
        ? (widget.idFront!['id_front_path'] as String?)
        : null;
    final idBackPath = widget.idBack != null
        ? (widget.idBack!['id_back_path'] as String?)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VerifIdConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Text(
            'Verifiez vos documents',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Assurez-vous que les photos sont nettes et lisibles avant de soumettre.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: VerifIdConstants.sectionGap + 4),

          // ── Selfie card ──
          _ImageCard(
            path: selfiePath,
            label: 'Selfie',
            aspectRatio: 1,
            placeholderIcon: Icons.person_rounded,
          ),
          const SizedBox(height: VerifIdConstants.itemGap),

          // ── ID cards side by side ──
          Row(
            children: [
              Expanded(
                child: _ImageCard(
                  path: idFrontPath,
                  label: 'Recto',
                  aspectRatio: 16 / 10,
                  placeholderIcon: Icons.credit_card_rounded,
                ),
              ),
              const SizedBox(width: VerifIdConstants.itemGap),
              Expanded(
                child: _ImageCard(
                  path: idBackPath,
                  label: 'Verso',
                  aspectRatio: 16 / 10,
                  placeholderIcon: Icons.credit_card_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: VerifIdConstants.sectionGap),

          // ── Info note ──
          Container(
            padding: const EdgeInsets.all(VerifIdConstants.itemGap),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(VerifIdConstants.imageRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: VerifIdConstants.tinyGap),
                Expanded(
                  child: Text(
                    'La video enregistree sera incluse dans les donnees de verification.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VerifIdConstants.sectionGap + 4),

          // ── Submit button ──
          StepButton(
            label: 'Soumettre',
            loading: _submitting,
            onTap: _submitting ? null : _handleSubmit,
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: VerifIdConstants.itemGap),

          // ── Restart button ──
          StepButton(
            label: 'Recommencer',
            primary: false,
            onTap: widget.onReverify,
            icon: Icons.refresh_rounded,
          ),

          // ── Back button ──
          if (widget.onBack != null) ...[
            const SizedBox(height: VerifIdConstants.tinyGap),
            Center(
              child: TextButton(
                onPressed: widget.onBack,
                child: Text(
                  'Retour',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],

          const SizedBox(height: VerifIdConstants.sectionGap),
        ],
      ),
    );
  }
}

/// Reusable image card with gradient label overlay.
class _ImageCard extends StatelessWidget {
  final String? path;
  final String label;
  final double aspectRatio;
  final IconData placeholderIcon;

  const _ImageCard({
    required this.path,
    required this.label,
    required this.aspectRatio,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VerifIdConstants.imageRadius),
          color: cs.surfaceContainerHighest,
        ),
        child: path != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                  ),
                  // Gradient label overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      child: Text(
                        label,
                        style: tt.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(placeholderIcon, size: 32, color: cs.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
