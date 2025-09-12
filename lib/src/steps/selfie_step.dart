import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';
import '../widgets/camera_overlay.dart';
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
      'Veuillez vous placer face à la caméra. Appuyez sur le bouton pour prendre votre selfie. Nous allons enregistrer une courte vidéo de 15 secondes en parallèle.',
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
        ResolutionPreset.medium,
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

  Future<void> _startRecordingVideo(Duration duration) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      // final dir = await getTemporaryDirectory();
      // final path = '${dir.path}/${const Uuid().v4()}.mp4';
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

      // automatically stop after duration
      Future.delayed(duration, () async {
        if (_controller != null && _controller!.value.isRecordingVideo) {
          final file = await _controller!.stopVideoRecording();
          _videoPath = file.path;
          setState(() {
            _isRecording = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _takeSelfieAndRecord() async {
    if (_controller == null || !_controller!.value.isInitialized || _busy)
      return;
    setState(() => _busy = true);
    try {
      // start video recording in background (15s)
      await _startRecordingVideo(const Duration(seconds: 15));

      // small delay to let recording begin (so selfie and video overlap)
      await Future.delayed(const Duration(milliseconds: 300));

      final selfie = await _controller!.takePicture();
      final compressed = await saveAndCompressImage(File(selfie.path));
      _lastSelfie = XFile(compressed.path);

      // Wait for video recording to end (if still recording, wait)
      int retryMs = 0;
      while ((_isRecording) && retryMs < 20000) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryMs += 200;
      }

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
              const CameraOverlay(), // guides cropping/frame
              if (_isRecording)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Enregistrement - $_remaining s',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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
                'Appuyez sur le bouton pour prendre votre selfie. Une courte vidéo de 15 secondes sera enregistrée en parallèle (ne sera pas lue).',
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
