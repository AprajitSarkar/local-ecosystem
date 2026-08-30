// lib/application/native_input_helper.dart
export 'native_input_helper_native.dart'
    if (dart.library.html) 'native_input_helper_web.dart';
