// lib/application/native_power_helper_web.dart
class PowerStatusResult {
  final bool isPluggedIn;
  final int batteryPercent;
  PowerStatusResult({required this.isPluggedIn, required this.batteryPercent});
}

class NativePowerHelper {
  static void init() {}
  static PowerStatusResult? getPowerStatus() => null;
  static void setKeepAwake(bool enable) {}
}
