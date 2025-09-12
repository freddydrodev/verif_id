import 'dart:io';
// import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

/// Compress image with the `image` package and save to temp file.
Future<File> saveAndCompressImage(
  File src, {
  int quality = 75,
  int maxWidth = 720,
}) async {
  final bytes = await src.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return src;
  img.Image resized = image;
  if (image.width > maxWidth) {
    resized = img.copyResize(image, width: maxWidth);
  }
  final encoded = img.encodeJpg(resized, quality: quality);
  final dir = await getTemporaryDirectory();
  final out = File('${dir.path}/${const Uuid().v4()}.jpg');
  await out.writeAsBytes(encoded);
  return out;
}

/// Get simple metadata for an image file
Future<Map<String, dynamic>> getImageMetadata(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  return {
    'size': await file.length(),
    'width': image?.width,
    'height': image?.height,
    'path': file.path,
  };
}

/// Get lightweight video metadata using video_player
Future<Map<String, dynamic>?> getVideoMetadata(File file) async {
  try {
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    final size = await file.length();
    controller.dispose();
    return {
      'duration_ms': duration.inMilliseconds,
      'size': size,
      'path': file.path,
    };
  } catch (_) {
    return null;
  }
}
