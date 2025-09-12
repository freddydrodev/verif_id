import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';
import '../widgets/face_overlay.dart';
import '../widgets/step_button.dart';
import '../utils/file_utils.dart';
import '../utils/tts_helper.dart';

/// SelfieStep:
/// - initializes camera front
/// - shows preview (camera)
/// - takes a high-quality selfie image on button press
/// - simultaneously records a 15s guided video (background). The user is told we are recording.
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
  static const int _totalSeconds = 8;

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
      'Veuillez retirer tout ce qui pourrait cacher votre visage, comme un masque, des lunettes opaques ou une casquette. Assurez-vous d’être dans un endroit bien éclairé. Placez bien votre visage à l’intérieur de l’ovale, puis appuyez sur le bouton. Une courte vidéo de huit secondes sera enregistrée, puis le selfie sera pris automatiquement.',
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
      // show error UI
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

      // wait duration then stop and return the video file
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
    if (_controller == null || !_controller!.value.isInitialized || _busy)
      return;
    setState(() => _busy = true);
    try {
      // 1) record video for 15s with visible progress
      await _startRecordingVideoAndAwaitStop(
        const Duration(seconds: _totalSeconds),
      );

      // 2) after recording finishes, take selfie
      final selfie = await _controller!.takePicture();
      final compressed = await saveAndCompressImage(File(selfie.path));
      _lastSelfie = XFile(compressed.path);

      // prepare metadata
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
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              const FaceOverlay(), // face-shaped guide
              if (_isRecording)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _RecordingIndicator(remaining: _remaining),
                ),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Prenez un selfie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Retirez toute obstruction (masque, lunettes opaques, casquette). Assurez-vous d’un bon éclairage. Alignez votre visage dans l’ovale. Une vidéo de 8 secondes sera enregistrée, puis le selfie sera pris automatiquement.',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StepButton(
                key: const Key('selfie_take_button'),
                label: _busy ? 'Traitement...' : 'Prendre le selfie',
                onTap: _busy ? null : _takeSelfieAndRecord,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final int remaining;
  const _RecordingIndicator({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 6),
          Text(
            'Enregistrement - $remaining s',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

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
