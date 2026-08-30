// lib/application/pending_share_service.dart
// Manages files and folders shared via Windows Explorer context menu ("Share with Ecosystem") or command line.

import 'dart:io';

class PendingShareService {
  PendingShareService._();
  static final PendingShareService instance = PendingShareService._();

  final List<String> initialSharePaths = [];

  void handleArgs(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i].trim();
      if (arg.isEmpty) continue;

      if (arg == '--share' && i + 1 < args.length) {
        final nextArg = args[i + 1].trim();
        if (nextArg.isNotEmpty && (File(nextArg).existsSync() || Directory(nextArg).existsSync())) {
          initialSharePaths.add(nextArg);
        }
        i++;
      } else if (!arg.startsWith('--') && (File(arg).existsSync() || Directory(arg).existsSync())) {
        initialSharePaths.add(arg);
      }
    }
  }
}
