// lib/core/utils/system_file_opener.dart
// Universal system file launcher — opens received files in their default OS apps.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

class SystemFileOpener {
  SystemFileOpener._();

  static const _channel = MethodChannel('com.localecosystem/clipboard');

  static Future<void> open(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      logger.warning('FileOpener', 'File not found on disk: $filePath');
      return;
    }

    logger.info('FileOpener', 'Opening file: $filePath');

    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openFile', {'path': filePath});
      } catch (e) {
        logger.warning('FileOpener', 'Android native openFile failed: $e');
      }
    } else if (Platform.isWindows) {
      try {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } catch (e) {
        try {
          await Process.run('explorer.exe', ['/select,', filePath]);
        } catch (_) {}
      }
    } else if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [filePath]);
      } catch (e) {
        logger.warning('FileOpener', 'Linux xdg-open failed: $e');
      }
    } else if (Platform.isMacOS) {
      try {
        await Process.run('open', [filePath]);
      } catch (e) {
        logger.warning('FileOpener', 'macOS open failed: $e');
      }
    }
  }

  static Future<void> openFolder(String filePath) async {
    final file = File(filePath);
    final folderPath = file.parent.path;
    if (kIsWeb) return;

    if (Platform.isWindows) {
      try {
        await Process.run('explorer.exe', ['/select,', filePath]);
      } catch (_) {
        try {
          await Process.run('explorer.exe', [folderPath]);
        } catch (_) {}
      }
    } else if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openFile', {'path': filePath});
      } catch (_) {}
    } else if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [folderPath]);
      } catch (_) {}
    } else if (Platform.isMacOS) {
      try {
        await Process.run('open', ['-R', filePath]);
      } catch (_) {}
    }
  }
}
