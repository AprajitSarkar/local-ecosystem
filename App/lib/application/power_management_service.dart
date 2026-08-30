// lib/application/power_management_service.dart
// Windows power management and display keep-awake service.
// Prevents screen from turning off and system from sleeping when plugged in & charging.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import 'native_power_helper.dart';

class PowerManagementService extends ChangeNotifier {
  PowerManagementService._();
  static final PowerManagementService instance = PowerManagementService._();

  Timer? _powerCheckTimer;
  bool _isPluggedIn = false;
  bool _isKeepAwakeActive = false;
  bool _keepAwakeWhenPluggedInEnabled = true;
  bool _initialized = false;

  bool get isPluggedIn => _isPluggedIn;
  bool get isKeepAwakeActive => _isKeepAwakeActive;
  bool get keepAwakeWhenPluggedInEnabled => _keepAwakeWhenPluggedInEnabled;

  void init() {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (!kIsWeb && Platform.isWindows) {
      NativePowerHelper.init();
      _checkPowerStatus();
      _powerCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkPowerStatus();
      });
    }
  }

  void setKeepAwakeWhenPluggedIn(bool enabled) {
    _keepAwakeWhenPluggedInEnabled = enabled;
    _checkPowerStatus();
    notifyListeners();
  }

  void _checkPowerStatus() {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final status = NativePowerHelper.getPowerStatus();
      if (status != null) {
        final wasPluggedIn = _isPluggedIn;
        _isPluggedIn = status.isPluggedIn;

        if (_isPluggedIn != wasPluggedIn) {
          logger.info(
            'PowerManagement',
            _isPluggedIn
                ? '🔌 Laptop plugged in & charging. Enabling continuous display keep-awake.'
                : '🔋 Running on battery. Restoring standard display sleep.',
          );
          notifyListeners();
        }

        if (_isPluggedIn && _keepAwakeWhenPluggedInEnabled) {
          _enableKeepDisplayAwake();
        } else {
          _restoreDefaultPowerState();
        }
      }
    } catch (e) {
      logger.warning('PowerManagement', 'Error checking power status: $e');
    }
  }

  void _enableKeepDisplayAwake() {
    if (kIsWeb || !Platform.isWindows) return;
    NativePowerHelper.setKeepAwake(true);
    if (!_isKeepAwakeActive) {
      _isKeepAwakeActive = true;
      logger.info('PowerManagement', 'Display & System Keep-Awake ACTIVE');
    }
  }

  void _restoreDefaultPowerState() {
    if (kIsWeb || !Platform.isWindows) return;
    if (_isKeepAwakeActive) {
      NativePowerHelper.setKeepAwake(false);
      _isKeepAwakeActive = false;
      logger.info('PowerManagement', 'Restored default power state');
    }
  }

  @override
  void dispose() {
    _powerCheckTimer?.cancel();
    _restoreDefaultPowerState();
    super.dispose();
  }
}
