import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/step_button.dart';

/// ReviewSubmitStep
/// - Shows preview of selfie ONLY
/// - Shows thumbnails/placeholders for id front/back
/// - Buttons: Soumettre (calls onSubmit), Recommencer (calls onReverify)
class ReviewSubmitStep extends StatelessWidget {
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

  Widget _thumb(String? path, String label) {
    if (path == null) {
      return Container(
        width: 120,
        height: 80,
        color: Colors.grey.shade200,
        child: Center(child: Text(label, textAlign: TextAlign.center)),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(path),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfiePath = selfie != null
        ? (selfie!['selfie_path'] as String?)
        : null;
    final idFrontPath = idFront != null
        ? (idFront!['id_front_path'] as String?)
        : null;
    final idBackPath = idBack != null
        ? (idBack!['id_back_path'] as String?)
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vérifiez vos éléments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (selfiePath != null)
            Column(
              children: [
                const Text(
                  'Selfie',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(selfiePath),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Aucun selfie trouvé',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 16),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Recto'),
                    const SizedBox(height: 8),
                    _thumb(idFrontPath, 'Recto'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Verso'),
                    const SizedBox(height: 8),
                    _thumb(idBackPath, 'Verso'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (onBack != null)
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              Expanded(
                child: StepButton(label: 'Soumettre', onTap: () => onSubmit()),
              ),
            ],
          ),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReverify,
            icon: Icon(Icons.refresh),
            label: const Text('Recommencer'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Remarque: la vidéo enregistrée ne sera pas lue ici mais sera incluse dans les métadonnées.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
