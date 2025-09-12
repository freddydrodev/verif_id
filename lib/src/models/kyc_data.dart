/// Data model representing the full KYC capture result, with nested classes for each section.
///
/// Structure:
/// {
///   "selfie": {
///     "selfie_path": "...",
///     "selfie_meta": {...},
///     "video_path": "...",
///     "video_meta": {...}
///   },
///   "id_front": {
///     "id_front_path": "...",
///     "id_front_meta": {...}
///   },
///   "id_back": {
///     "id_back_path": "...",
///     "id_back_meta": {...}
///   },
///   "sessionId": "..."
/// }
class KYCData {
  /// Selfie section (image, meta, video, video meta)
  final KycSelfie selfie;

  /// ID front section (image, meta)
  final KycIdFront idFront;

  /// ID back section (image, meta)
  final KycIdBack idBack;

  /// Session identifier
  final String sessionId;

  /// Creates a [KYCData] instance.
  KYCData({
    required this.selfie,
    required this.idFront,
    required this.idBack,
    required this.sessionId,
  });

  /// Creates a [KYCData] from a JSON-like map.
  factory KYCData.fromJson(Map<String, dynamic> json) {
    return KYCData(
      selfie: KycSelfie.fromJson(json['selfie'] ?? const {}),
      idFront: KycIdFront.fromJson(json['id_front'] ?? const {}),
      idBack: KycIdBack.fromJson(json['id_back'] ?? const {}),
      sessionId: json['sessionId'] as String? ?? '',
    );
  }

  /// Converts this [KYCData] to a JSON-like map.
  Map<String, dynamic> toJson() => {
    'selfie': selfie.toJson(),
    'id_front': idFront.toJson(),
    'id_back': idBack.toJson(),
    'sessionId': sessionId,
  };
}

/// Selfie section: image, meta, video, video meta.
class KycSelfie {
  final String selfiePath;
  final KycImageMeta selfieMeta;
  final String videoPath;
  final KycVideoMeta videoMeta;

  KycSelfie({
    required this.selfiePath,
    required this.selfieMeta,
    required this.videoPath,
    required this.videoMeta,
  });

  factory KycSelfie.fromJson(Map<String, dynamic> json) {
    return KycSelfie(
      selfiePath: json['selfie_path'] as String? ?? '',
      selfieMeta: KycImageMeta.fromJson(json['selfie_meta'] ?? const {}),
      videoPath: json['video_path'] as String? ?? '',
      videoMeta: KycVideoMeta.fromJson(json['video_meta'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'selfie_path': selfiePath,
    'selfie_meta': selfieMeta.toJson(),
    'video_path': videoPath,
    'video_meta': videoMeta.toJson(),
  };
}

/// ID front section: image, meta.
class KycIdFront {
  final String idFrontPath;
  final KycImageMeta idFrontMeta;

  KycIdFront({required this.idFrontPath, required this.idFrontMeta});

  factory KycIdFront.fromJson(Map<String, dynamic> json) {
    return KycIdFront(
      idFrontPath: json['id_front_path'] as String? ?? '',
      idFrontMeta: KycImageMeta.fromJson(json['id_front_meta'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_front_path': idFrontPath,
    'id_front_meta': idFrontMeta.toJson(),
  };
}

/// ID back section: image, meta.
class KycIdBack {
  final String idBackPath;
  final KycImageMeta idBackMeta;

  KycIdBack({required this.idBackPath, required this.idBackMeta});

  factory KycIdBack.fromJson(Map<String, dynamic> json) {
    return KycIdBack(
      idBackPath: json['id_back_path'] as String? ?? '',
      idBackMeta: KycImageMeta.fromJson(json['id_back_meta'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_back_path': idBackPath,
    'id_back_meta': idBackMeta.toJson(),
  };
}

/// Metadata for an image (size, width, height, path).
class KycImageMeta {
  final int size;
  final int width;
  final int height;
  final String path;

  KycImageMeta({
    required this.size,
    required this.width,
    required this.height,
    required this.path,
  });

  factory KycImageMeta.fromJson(Map<String, dynamic> json) {
    return KycImageMeta(
      size: json['size'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      path: json['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'size': size,
    'width': width,
    'height': height,
    'path': path,
  };
}

/// Metadata for a video (duration_ms, size, path).
class KycVideoMeta {
  final int durationMs;
  final int size;
  final String path;

  KycVideoMeta({
    required this.durationMs,
    required this.size,
    required this.path,
  });

  factory KycVideoMeta.fromJson(Map<String, dynamic> json) {
    return KycVideoMeta(
      durationMs: json['duration_ms'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      path: json['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'duration_ms': durationMs,
    'size': size,
    'path': path,
  };
}
