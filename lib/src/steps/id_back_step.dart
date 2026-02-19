import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../widgets/camera_overlay.dart';
import '../widgets/step_button.dart';
import '../utils/file_utils.dart';
import '../utils/tts_helper.dart';
import '../utils/verif_id_constants.dart';

class IdBackStep extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> result) onComplete;
  final bool enableTts;
  final VoidCallback? onBack;

  const IdBackStep({
    super.key,
    required this.onComplete,
    this.enableTts = true,
    this.onBack,
  });

  @override
  State<IdBackStep> createState() => _IdBackStepState();
}

class _IdBackStepState extends State<IdBackStep> {
  CameraController? _controller;
  bool _busy = false;
  final _tts = TtsHelper.instance;

  @override
  void initState() {
    super.initState();
    _init();
    if (widget.enableTts) {
      _tts.speakFrFemale(
        'Veuillez cadrer la face arrière de votre carte d\'identité et appuyez sur le bouton.',
      );
    }
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    _controller = CameraController(
      back,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureBack() async {
    if (_controller == null || !_controller!.value.isInitialized || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picture = await _controller!.takePicture();
      final compressed = await saveAndCompressImage(File(picture.path));
      final meta = await getImageMetadata(File(compressed.path));
      widget.onComplete({
        'id_back_path': compressed.path,
        'id_back_meta': meta,
      });
    } catch (e) {
      if (widget.enableTts) {
        await _tts.speakFrFemale(
          'Échec de la capture. Réessayez, s\'il vous plaît.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // ── Camera preview ──
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [CameraPreview(_controller!), const CameraOverlay()],
          ),
        ),

        // ── Instruction card ──
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VerifIdConstants.cardRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(
            VerifIdConstants.pagePadding,
            VerifIdConstants.pagePadding,
            VerifIdConstants.pagePadding,
            VerifIdConstants.pagePadding + 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge + title
              Row(
                children: [
                  Container(
                    width: VerifIdConstants.iconBadgeSize,
                    height: VerifIdConstants.iconBadgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: VerifIdConstants.itemGap),
                  Expanded(
                    child: Text(
                      'Verso de la carte',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VerifIdConstants.tinyGap),

              Text(
                'Cadrez la face arriere de votre carte d\'identite dans le cadre, puis appuyez sur le bouton.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: VerifIdConstants.sectionGap),

              // Capture button
              StepButton(
                label: 'Prendre la photo',
                isCircular: true,
                loading: _busy,
                onTap: _busy ? null : _captureBack,
              ),
              if (widget.onBack != null) ...[
                const SizedBox(height: VerifIdConstants.tinyGap),
                TextButton(
                  onPressed: widget.onBack,
                  child: Text(
                    'Retour',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
