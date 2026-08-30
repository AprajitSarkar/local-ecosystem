// lib/application/native_power_helper.dart
export 'native_power_helper_native.dart'
    if (dart.library.html) 'native_power_helper_web.dart';
