import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/verif_id_constants.dart';

class PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const PermissionDeniedView({super.key, required this.onRetry});

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VerifIdConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: VerifIdConstants.iconBadgeSizeLg,
              height: VerifIdConstants.iconBadgeSizeLg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.errorContainer,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 36,
                color: cs.onErrorContainer,
              ),
            ),
            const SizedBox(height: VerifIdConstants.sectionGap),

            Text(
              'Permissions necessaires',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VerifIdConstants.tinyGap),

            Text(
              'L\'application a besoin d\'acces a la camera et au microphone pour la verification d\'identite.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Primary: Retry
            SizedBox(
              width: double.infinity,
              height: VerifIdConstants.buttonHeight,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Autoriser l\'acces',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      VerifIdConstants.buttonRadius,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: VerifIdConstants.itemGap),

            // Secondary: Open settings
            SizedBox(
              width: double.infinity,
              height: VerifIdConstants.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined, size: 20),
                label: const Text(
                  'Ouvrir les parametres',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      VerifIdConstants.buttonRadius,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
