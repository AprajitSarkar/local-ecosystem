// lib/application/settings_service.dart
// Manages all user-configurable settings, ecosystem persistence,
// device naming from hardware info, and receive folders.

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/logging/app_logger.dart';

const _kReceiveFolderKey = 'receive_folder_path';
const _kDeviceNameKey = 'device_display_name';
const _kClipboardSyncKey = 'clipboard_sync_enabled';
const _kAutoOpenLinksKey = 'auto_open_links_enabled';
const _kAutoAcceptKey = 'auto_accept_trusted';
const _kDarkModeKey = 'dark_mode';
const _kEcosystemNameKey = 'ecosystem_name';
const _kEcosystemIdKey = 'ecosystem_id';
const _kHasActiveEcosystemKey = 'has_active_ecosystem';
const _kSavedEcosystemsKey = 'saved_ecosystems_list';
const _kHasCompletedPermissionsKey = 'has_completed_permissions';

class SavedEcosystem {
  const SavedEcosystem({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  factory SavedEcosystem.fromJson(Map<String, dynamic> json) => SavedEcosystem(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initDeviceName();
    logger.info('SettingsService', 'Settings loaded. Device name: $deviceName');
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'SettingsService.init() must be called first');
    return _prefs!;
  }

  // ── Real Hardware Device Name ──────────────────────────────────────────────

  Future<void> _initDeviceName() async {
    final saved = _p.getString(_kDeviceNameKey);
    if (saved != null && saved.isNotEmpty) return;

    final deviceInfo = DeviceInfoPlugin();
    String detectedName = 'My Device';
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        detectedName = webInfo.browserName.name.toUpperCase();
        if (detectedName.isEmpty) detectedName = 'iPad / Web Device';
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final model = info.model.trim();
        final brand = info.brand.trim();
        if (model.toLowerCase().startsWith(brand.toLowerCase())) {
          detectedName = model;
        } else {
          detectedName = '$brand $model';
        }
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        detectedName = info.name.isNotEmpty
            ? info.name
            : (info.model.isNotEmpty ? info.model : 'iPad');
      } else if (Platform.isLinux) {
        final host = Platform.localHostname;
        detectedName = host.isNotEmpty ? host : 'Linux PC';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        detectedName = info.computerName.isNotEmpty
            ? info.computerName
            : Platform.localHostname;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        detectedName = info.computerName.isNotEmpty
            ? info.computerName
            : Platform.localHostname;
      }
    } catch (e) {
      detectedName = kIsWeb ? 'Web Device' : (Platform.localHostname.isNotEmpty ? Platform.localHostname : 'My Device');
    }

    await _p.setString(_kDeviceNameKey, detectedName);
  }

  String get deviceName {
    return _p.getString(_kDeviceNameKey) ?? 'My Device';
  }

  Future<void> setDeviceName(String name) async {
    await _p.setString(_kDeviceNameKey, name);
    notifyListeners();
  }

  // ── Active Ecosystem & Persistence ─────────────────────────────────────────

  bool get hasActiveEcosystem =>
      _p.getBool(_kHasActiveEcosystemKey) ?? false;

  String get ecosystemId {
    var id = _p.getString(_kEcosystemIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _p.setString(_kEcosystemIdKey, id);
    }
    return id;
  }

  String get ecosystemName =>
      _p.getString(_kEcosystemNameKey) ?? 'My Ecosystem';

  List<SavedEcosystem> get savedEcosystems {
    final raw = _p.getString(_kSavedEcosystemsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SavedEcosystem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Activate and save an ecosystem (e.g. after creating or joining)
  Future<void> saveAndActivateEcosystem({
    required String id,
    required String name,
  }) async {
    await _p.setBool(_kHasActiveEcosystemKey, true);
    await _p.setString(_kEcosystemIdKey, id);
    await _p.setString(_kEcosystemNameKey, name);

    // Update saved ecosystems list
    final currentList = savedEcosystems.where((e) => e.id != id).toList();
    currentList.insert(
      0,
      SavedEcosystem(id: id, name: name, createdAt: DateTime.now()),
    );

    final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
    await _p.setString(_kSavedEcosystemsKey, raw);

    logger.info('SettingsService', 'Activated ecosystem: "$name" ($id)');
    notifyListeners();
  }

  /// Switch active ecosystem to another saved one
  Future<void> switchEcosystem(String id) async {
    final target = savedEcosystems.where((e) => e.id == id).firstOrNull;
    if (target != null) {
      await _p.setBool(_kHasActiveEcosystemKey, true);
      await _p.setString(_kEcosystemIdKey, target.id);
      await _p.setString(_kEcosystemNameKey, target.name);
      notifyListeners();
    }
  }

  /// Leave/exit the active ecosystem
  Future<void> leaveEcosystem() async {
    await _p.setBool(_kHasActiveEcosystemKey, false);
    logger.info('SettingsService', 'Exited active ecosystem');
    notifyListeners();
  }

  /// Delete a saved ecosystem
  Future<void> deleteEcosystem(String id) async {
    final currentList = savedEcosystems.where((e) => e.id != id).toList();
    final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
    await _p.setString(_kSavedEcosystemsKey, raw);

    if (ecosystemId == id) {
      await leaveEcosystem();
    } else {
      notifyListeners();
    }
  }

  Future<void> setEcosystemName(String name) async {
    await _p.setString(_kEcosystemNameKey, name);
    // Update in saved list as well
    final currentList = savedEcosystems.map((e) {
      if (e.id == ecosystemId) {
        return SavedEcosystem(id: e.id, name: name, createdAt: e.createdAt);
      }
      return e;
    }).toList();
    final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
    await _p.setString(_kSavedEcosystemsKey, raw);
    notifyListeners();
  }

  // ── Receive Folder ─────────────────────────────────────────────────────────

  Future<String> getReceiveFolder() async {
    final saved = _p.getString(_kReceiveFolderKey);
    if (saved != null && saved.isNotEmpty) {
      final dir = Directory(saved);
      if (await dir.exists()) return saved;
    }
    return await _defaultReceiveFolder();
  }

  Future<void> setReceiveFolder(String path) async {
    await _p.setString(_kReceiveFolderKey, path);
    logger.info('SettingsService', 'Receive folder set to: $path');
    notifyListeners();
  }

  Future<String> _defaultReceiveFolder() async {
    if (kIsWeb) return 'Downloads (Browser)';
    final cleanEco = ecosystemName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (Platform.isAndroid) {
      final publicDownloads =
          Directory('/storage/emulated/0/Download/LocalEcosystem/$cleanEco');
      try {
        if (!await publicDownloads.exists()) {
          await publicDownloads.create(recursive: true);
        }
        return publicDownloads.path;
      } catch (_) {
        final docs = await getApplicationDocumentsDirectory();
        final recv = Directory('${docs.path}/LocalEcosystem/$cleanEco');
        await recv.create(recursive: true);
        return recv.path;
      }
    } else if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final recv = Directory('${docs.path}/LocalEcosystem/$cleanEco');
      await recv.create(recursive: true);
      return recv.path;
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      final recv = Directory('$home/Downloads/LocalEcosystem/$cleanEco');
      await recv.create(recursive: true);
      return recv.path;
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final recv =
          Directory('$userProfile\\Downloads\\LocalEcosystem\\$cleanEco');
      await recv.create(recursive: true);
      return recv.path;
    }
    final temp = await getTemporaryDirectory();
    return temp.path;
  }

  // ── Feature Toggles ────────────────────────────────────────────────────────

  bool get clipboardSyncEnabled =>
      _p.getBool(_kClipboardSyncKey) ?? true;

  Future<void> setClipboardSync(bool value) async {
    await _p.setBool(_kClipboardSyncKey, value);
    notifyListeners();
  }

  bool get autoOpenLinks => _p.getBool(_kAutoOpenLinksKey) ?? false;

  Future<void> setAutoOpenLinks(bool value) async {
    await _p.setBool(_kAutoOpenLinksKey, value);
    notifyListeners();
  }

  bool get autoAcceptTrusted => _p.getBool(_kAutoAcceptKey) ?? true;

  Future<void> setAutoAcceptTrusted(bool value) async {
    await _p.setBool(_kAutoAcceptKey, value);
    notifyListeners();
  }

  bool get darkMode => _p.getBool(_kDarkModeKey) ?? true;

  Future<void> setDarkMode(bool value) async {
    await _p.setBool(_kDarkModeKey, value);
    notifyListeners();
  }

  // ── First-Run Permission Setup ──────────────────────────────────────────────

  bool get hasCompletedPermissions =>
      _p.getBool(_kHasCompletedPermissionsKey) ?? false;

  Future<void> setHasCompletedPermissions(bool value) async {
    await _p.setBool(_kHasCompletedPermissionsKey, value);
    notifyListeners();
  }
}
