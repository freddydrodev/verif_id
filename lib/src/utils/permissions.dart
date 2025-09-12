import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Requests camera and microphone permissions and returns true if granted.
/// This function will show the system permission dialogs if needed.
Future<bool> requestCameraAndMicPermissions() async {
  try {
    if (kDebugMode) {
      print('🔐 Requesting camera and microphone permissions...');
    }

    // Check current status first
    final cameraStatusBefore = await Permission.camera.status;
    final micStatusBefore = await Permission.microphone.status;

    if (kDebugMode) {
      print('📷 Camera status before request: $cameraStatusBefore');
      print('🎤 Microphone status before request: $micStatusBefore');
    }

    // Request camera permission (will show dialog if not granted)
    PermissionStatus cameraStatus;
    if (cameraStatusBefore.isGranted) {
      cameraStatus = cameraStatusBefore;
      if (kDebugMode) {
        print('📷 Camera already granted');
      }
    } else if (cameraStatusBefore.isPermanentlyDenied) {
      cameraStatus = cameraStatusBefore;
      if (kDebugMode) {
        print('📷 Camera permanently denied - user must go to settings');
      }
    } else {
      if (kDebugMode) {
        print('📷 Requesting camera permission (will show dialog)...');
      }
      cameraStatus = await Permission.camera.request();
    }

    // Request microphone permission (will show dialog if not granted)
    PermissionStatus microphoneStatus;
    if (micStatusBefore.isGranted) {
      microphoneStatus = micStatusBefore;
      if (kDebugMode) {
        print('🎤 Microphone already granted');
      }
    } else if (micStatusBefore.isPermanentlyDenied) {
      microphoneStatus = micStatusBefore;
      if (kDebugMode) {
        print('🎤 Microphone permanently denied - user must go to settings');
      }
    } else {
      if (kDebugMode) {
        print('🎤 Requesting microphone permission (will show dialog)...');
      }
      microphoneStatus = await Permission.microphone.request();
    }

    if (kDebugMode) {
      print('📷 Camera status after request: $cameraStatus');
      print('🎤 Microphone status after request: $microphoneStatus');
    }

    final granted = cameraStatus.isGranted && microphoneStatus.isGranted;

    if (kDebugMode) {
      print('✅ Permissions granted: $granted');
      if (!granted) {
        print('❌ Camera granted: ${cameraStatus.isGranted}');
        print('❌ Microphone granted: ${microphoneStatus.isGranted}');

        // Check if any permissions are permanently denied
        if (cameraStatus.isPermanentlyDenied) {
          print('⚠️ Camera permission is permanently denied');
        }
        if (microphoneStatus.isPermanentlyDenied) {
          print('⚠️ Microphone permission is permanently denied');
        }
      }
    }

    return granted;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error requesting permissions: $e');
    }
    return false;
  }
}
