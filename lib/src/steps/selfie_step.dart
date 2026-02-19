import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../widgets/face_overlay.dart';
import '../widgets/step_button.dart';
import '../utils/file_utils.dart';
import '../utils/tts_helper.dart';
import '../utils/verif_id_constants.dart';

/// SelfieStep:
/// - initializes camera front
/// - shows preview (camera)
/// - takes a high-quality selfie image on button press
/// - simultaneously records a 5s guided video (background). The user is told we are recording.
/// - returns a Map: { 'selfie_path': ..., 'video_path': ..., 'selfie_meta': {...}, 'video_meta': {...} }
class SelfieStep extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> result) onComplete;
  final bool enableTts;

  const SelfieStep({
    super.key,
    required this.onComplete,
    this.enableTts = true,
  });

  @override
  State<SelfieStep> createState() => _SelfieStepState();
}

class _SelfieStepState extends State<SelfieStep> with WidgetsBindingObserver {
  CameraController? _controller;
  XFile? _lastSelfie;
  String? _videoPath;
  bool _isRecording = false;
  bool _busy = false;
  Timer? _countdownTimer;
  int _remaining = 0;
  final _tts = TtsHelper.instance;
  static const int _totalSeconds = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    if (widget.enableTts) {
      _speakIntro();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _speakIntro() async {
    await _tts.speakFrFemale(
      'Veuillez retirer tout ce qui pourrait cacher votre visage, comme un masque, des lunettes opaques ou une casquette. Assurez-vous d\'être dans un endroit bien éclairé. Placez bien votre visage à l\'intérieur de l\'ovale, puis appuyez sur le bouton. Une courte vidéo de cinq secondes sera enregistrée, puis le selfie sera pris automatiquement.',
    );
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (widget.enableTts) {
        await _tts.speakFrFemale(
          'Impossible d\'initialiser la caméra. Vérifiez les permissions.',
        );
      }
    }
  }

  Future<XFile?> _startRecordingVideoAndAwaitStop(Duration duration) async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _remaining = duration.inSeconds;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _remaining -= 1;
        });
        if (_remaining <= 0) {
          t.cancel();
        }
      });

      await Future.delayed(duration);
      if (_controller != null && _controller!.value.isRecordingVideo) {
        final file = await _controller!.stopVideoRecording();
        _videoPath = file.path;
        setState(() {
          _isRecording = false;
        });
        return file;
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
    }
    return null;
  }

  Future<void> _takeSelfieAndRecord() async {
    if (_controller == null || !_controller!.value.isInitialized || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _startRecordingVideoAndAwaitStop(
        const Duration(seconds: _totalSeconds),
      );

      final selfie = await _controller!.takePicture();
      final compressed = await saveAndCompressImage(File(selfie.path));
      _lastSelfie = XFile(compressed.path);

      final selfieMeta = await getImageMetadata(File(_lastSelfie!.path));
      final videoMeta = _videoPath != null
          ? await getVideoMetadata(File(_videoPath!))
          : null;

      final result = {
        'selfie_path': _lastSelfie!.path,
        'selfie_meta': selfieMeta,
        'video_path': _videoPath,
        'video_meta': videoMeta,
      };

      if (widget.enableTts) {
        await _tts.speakFrFemale('Selfie pris. Passage à l\'étape suivante.');
      }

      widget.onComplete(result);
    } catch (e) {
      if (widget.enableTts) {
        await _tts.speakFrFemale(
          'Échec de la capture. Réessayez s\'il vous plaît.',
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Camera preview ──
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              const FaceOverlay(),

              // Recording indicator pill
              if (_isRecording)
                Positioned(
                  top: VerifIdConstants.sectionGap,
                  left: VerifIdConstants.sectionGap,
                  child: _RecordingIndicator(remaining: _remaining),
                ),

              // Progress bar
              if (_isRecording)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _RecordingProgress(
                    totalSeconds: _totalSeconds,
                    remainingSeconds: _remaining,
                  ),
                ),
            ],
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
              // Icon badge + title row
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
                      Icons.camera_front_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: VerifIdConstants.itemGap),
                  Expanded(
                    child: Text(
                      'Prenez un selfie',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VerifIdConstants.tinyGap),

              // Instruction text
              Text(
                'Placez votre visage dans l\'ovale. Une video de 5 s sera enregistree, puis le selfie sera pris.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: VerifIdConstants.sectionGap),

              // Capture button
              StepButton(
                key: const Key('selfie_take_button'),
                label: 'Prendre le selfie',
                isCircular: true,
                loading: _busy,
                onTap: _busy ? null : _takeSelfieAndRecord,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recording indicator pill ──
class _RecordingIndicator extends StatelessWidget {
  final int remaining;
  const _RecordingIndicator({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(VerifIdConstants.badgeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: VerifIdConstants.recordingDotSize,
            height: VerifIdConstants.recordingDotSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Enregistrement - ${remaining}s',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recording progress bar ──
class _RecordingProgress extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  const _RecordingProgress({
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = (totalSeconds - remainingSeconds).clamp(0, totalSeconds);
    final progress = totalSeconds == 0 ? 0.0 : elapsed / totalSeconds;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: Colors.black26,
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
