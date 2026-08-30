// lib/application/native_power_helper_native.dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const int ES_CONTINUOUS = 0x80000000;
const int ES_SYSTEM_REQUIRED = 0x00000001;
const int ES_DISPLAY_REQUIRED = 0x00000002;
const int ES_AWAYMODE_REQUIRED = 0x00000040;

final class SYSTEM_POWER_STATUS extends Struct {
  @Uint8()
  external int acLineStatus; // 0: Offline, 1: Online, 255: Unknown
  @Uint8()
  external int batteryFlag;
  @Uint8()
  external int batteryLifePercent;
  @Uint8()
  external int systemStatusFlag;
  @Uint32()
  external int batteryLifeTime;
  @Uint32()
  external int batteryFullLifeTime;
}

typedef GetSystemPowerStatusNative = Int32 Function(Pointer<SYSTEM_POWER_STATUS>);
typedef GetSystemPowerStatusDart = int Function(Pointer<SYSTEM_POWER_STATUS>);

typedef SetThreadExecutionStateNative = Uint32 Function(Uint32);
typedef SetThreadExecutionStateDart = int Function(int);

class PowerStatusResult {
  final bool isPluggedIn;
  final int batteryPercent;
  PowerStatusResult({required this.isPluggedIn, required this.batteryPercent});
}

class NativePowerHelper {
  static SetThreadExecutionStateDart? _setThreadExecutionState;
  static GetSystemPowerStatusDart? _getSystemPowerStatus;
  static bool _initialized = false;

  static void init() {
    if (_initialized || !Platform.isWindows) return;
    _initialized = true;
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      _setThreadExecutionState = kernel32.lookupFunction<
          SetThreadExecutionStateNative, SetThreadExecutionStateDart>(
        'SetThreadExecutionState',
      );
      _getSystemPowerStatus = kernel32.lookupFunction<
          GetSystemPowerStatusNative, GetSystemPowerStatusDart>(
        'GetSystemPowerStatus',
      );
    } catch (_) {}
  }

  static PowerStatusResult? getPowerStatus() {
    if (!Platform.isWindows || _getSystemPowerStatus == null) return null;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final success = _getSystemPowerStatus!(status);
      if (success != 0) {
        return PowerStatusResult(
          isPluggedIn: status.ref.acLineStatus == 1,
          batteryPercent: status.ref.batteryLifePercent,
        );
      }
    } catch (_) {
    } finally {
      calloc.free(status);
    }
    return null;
  }

  static void setKeepAwake(bool enable) {
    if (!Platform.isWindows || _setThreadExecutionState == null) return;
    try {
      if (enable) {
        _setThreadExecutionState!(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED | ES_AWAYMODE_REQUIRED);
      } else {
        _setThreadExecutionState!(ES_CONTINUOUS);
      }
    } catch (_) {}
  }
}
