import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../widgets/camera_overlay.dart';
import '../widgets/step_button.dart';
import '../utils/file_utils.dart';
import '../utils/tts_helper.dart';

/// IdFrontStep:
/// - opens camera (rear ideally)
/// - captures front of ID
/// - compresses and returns path + metadata
class IdFrontStep extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> result) onComplete;
  final bool enableTts;

  const IdFrontStep({
    super.key,
    required this.onComplete,
    this.enableTts = true,
  });

  @override
  State<IdFrontStep> createState() => _IdFrontStepState();
}

class _IdFrontStepState extends State<IdFrontStep> {
  CameraController? _controller;
  bool _busy = false;
  final _tts = TtsHelper.instance;

  @override
  void initState() {
    super.initState();
    _init();
    if (widget.enableTts) {
      _tts.speakFrFemale(
        'Veuillez cadrer la partie recto de votre carte d\'identité et appuyez sur le bouton.',
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
      ResolutionPreset.medium,
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

  Future<void> _captureFront() async {
    if (_controller == null || !_controller!.value.isInitialized || _busy)
      return;
    setState(() => _busy = true);
    try {
      final picture = await _controller!.takePicture();
      final compressed = await saveAndCompressImage(File(picture.path));
      final meta = await getImageMetadata(File(compressed.path));
      widget.onComplete({
        'id_front_path': compressed.path,
        'id_front_meta': meta,
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
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [CameraPreview(_controller!), const CameraOverlay()],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Photo — Recto de la carte',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StepButton(
                label: _busy ? 'Traitement...' : 'Prendre la photo',
                onTap: _busy ? null : _captureFront,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
