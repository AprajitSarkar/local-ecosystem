// lib/core/web/web_file_picker.dart
// Conditional export for Web and native file picker and streaming uploads.

export 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';
