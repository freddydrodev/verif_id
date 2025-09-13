import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:verif_id/verif_id.dart';
import 'steps/selfie_step.dart';
import 'steps/id_front_step.dart';
import 'steps/id_back_step.dart';
import 'steps/review_submit_step.dart';
import 'utils/permissions.dart';
import 'widgets/permission_denied_view.dart';
import 'widgets/horizontal_stepper.dart';
import 'utils/tts_helper.dart';

/// Main public widget for the verif_id package.
///
/// Example:
/// ```dart
/// VerifId(
///   sessionId: 'abc123',
///   onSubmit: (result) => print(result),
/// )
/// ```
class VerifId extends StatefulWidget {
  final String sessionId;
  final Future<void> Function(KYCData result) onSubmit;
  final bool enableTts;
  final Locale locale;

  const VerifId({
    super.key,
    required this.onSubmit,
    required this.sessionId,
    this.enableTts = true,
    this.locale = const Locale('fr', 'FR'),
  });

  @override
  State<VerifId> createState() => _VerifIdState();
}

class _VerifIdState extends State<VerifId> {
  int _currentStep = 0;
  final Map<String, dynamic> _data = {};
  bool _permissionsGranted = false;
  bool _permissionsLoading = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🚀 VerifId initState: Starting permission request...');
    }
    _requestPermissions();
  }

  @override
  void dispose() {
    TtsHelper.instance.stop();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      if (kDebugMode) {
        print('🔐 VerifId: Requesting permissions...');
      }

      final granted = await requestCameraAndMicPermissions();

      if (kDebugMode) {
        print('🔐 VerifId: Permission result: $granted');
      }

      setState(() {
        _permissionsGranted = granted;
        _permissionsLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ VerifId: Permission error: $e');
      }
      setState(() {
        _permissionsGranted = false;
        _permissionsLoading = false;
      });
    }
  }

  void _retryPermissions() {
    if (kDebugMode) {
      print('🔄 VerifId: Retry permissions requested');
    }

    setState(() {
      _permissionsLoading = true;
    });

    // Directly request permissions again
    requestCameraAndMicPermissions()
        .then((granted) {
          if (kDebugMode) {
            print('🔄 VerifId: Retry permission result: $granted');
          }
          setState(() {
            _permissionsGranted = granted;
            _permissionsLoading = false;
          });
        })
        .catchError((e) {
          if (kDebugMode) {
            print('❌ VerifId: Retry permission error: $e');
          }
          setState(() {
            _permissionsGranted = false;
            _permissionsLoading = false;
          });
        });
  }

  void _nextStep() {
    TtsHelper.instance.stop();
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 3));
  }

  void _previousStep() {
    TtsHelper.instance.stop();
    setState(() => _currentStep = (_currentStep - 1).clamp(0, 3));
  }

  void _onStepComplete(String key, dynamic value) {
    _data[key] = value;
    _nextStep();
  }

  Future<void> _handleSubmit() async {
    // Return gathered files + metadata; integrator handles upload.
    await widget.onSubmit(
      KYCData.fromJson({..._data, 'sessionId': widget.sessionId}),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
        '🏗️ VerifId build: loading=$_permissionsLoading, granted=$_permissionsGranted',
      );
    }

    if (_permissionsLoading) {
      if (kDebugMode) {
        print('⏳ Showing loading indicator');
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionsGranted) {
      if (kDebugMode) {
        print('🚫 Showing permission denied view');
      }
      return PermissionDeniedView(onRetry: _retryPermissions);
    }

    if (kDebugMode) {
      print('✅ Showing main stepper interface');
    }

    final steps = [
      Step(
        title: const Text('Selfie & vidéo'),
        content: SelfieStep(
          key: const Key('selfie_step'),
          enableTts: widget.enableTts,
          onComplete: (result) async => _onStepComplete('selfie', result),
        ),
        isActive: _currentStep == 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Carte — Recto'),
        content: IdFrontStep(
          key: const Key('id_front_step'),
          enableTts: widget.enableTts,
          onComplete: (result) async => _onStepComplete('id_front', result),
          onBack: () => _previousStep(),
        ),
        isActive: _currentStep == 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Carte — Verso'),
        content: IdBackStep(
          key: const Key('id_back_step'),
          enableTts: widget.enableTts,
          onComplete: (result) async => _onStepComplete('id_back', result),
          onBack: () => _previousStep(),
        ),
        isActive: _currentStep == 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Revoir & soumettre'),
        content: ReviewSubmitStep(
          key: const Key('review_step'),
          selfie: _data['selfie'],
          idFront: _data['id_front'],
          idBack: _data['id_back'],
          onSubmit: _handleSubmit,
          onReverify: () {
            setState(() {
              // Return to first step to re-verify selfie+video
              _currentStep = 0;
            });
          },
          onBack: () => _previousStep(),
        ),
        isActive: _currentStep == 3,
        state: _currentStep == 3 ? StepState.editing : StepState.indexed,
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          // Horizontal header + single mounted content for active step
          Expanded(
            child: HorizontalStepper(currentStep: _currentStep, steps: steps),
          ),
        ],
      ),
    );
  }
}
