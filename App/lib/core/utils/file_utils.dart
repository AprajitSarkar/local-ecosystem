// lib/core/utils/file_utils.dart

import 'dart:io';
import 'package:path/path.dart' as p;

/// Sanitize a filename to prevent path traversal and filesystem issues.
String sanitizeFilename(String filename) {
  // Strip any directory components
  String name = p.basename(filename);
  // Replace problematic characters
  name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  // Trim dots and spaces from edges
  name = name.trim().trimLeft().trimRight();
  if (name.isEmpty) name = 'file';
  // Limit length
  if (name.length > 255) name = name.substring(0, 255);
  return name;
}

/// Ensure a unique filename if the path already exists.
Future<String> uniqueFilePath(String directory, String filename) async {
  final sanitized = sanitizeFilename(filename);
  var candidate = p.join(directory, sanitized);
  if (!await File(candidate).exists()) return candidate;

  final ext = p.extension(sanitized);
  final base = p.basenameWithoutExtension(sanitized);
  var counter = 1;
  do {
    candidate = p.join(directory, '${base}_$counter$ext');
    counter++;
  } while (await File(candidate).exists());
  return candidate;
}

/// Format bytes as human-readable string.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Format speed as human-readable string.
String formatSpeed(double bytesPerSec) => '${formatBytes(bytesPerSec.round())}/s';

/// Format ETA seconds.
String formatEta(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
  return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
}
