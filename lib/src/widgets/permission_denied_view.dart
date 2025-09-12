import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const PermissionDeniedView({super.key, required this.onRetry});

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Permissions nécessaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'application a besoin d\'accès à la caméra et au microphone pour fonctionner correctement.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez autoriser les permissions dans les paramètres de l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
                OutlinedButton(
                  onPressed: _openAppSettings,
                  child: const Text('Paramètres'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
