// lib/core/web/web_pwa_service.dart
// Web PWA installation prompts, iOS home screen guidance, host offline detection, and permissions.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_theme.dart';
import '../audio/sound_effect_service.dart';
import '../logging/app_logger.dart';
import 'web_download_helper.dart';

class WebPwaService extends ChangeNotifier {
  WebPwaService._();
  static final WebPwaService instance = WebPwaService._();

  bool _isHostOnline = true;
  String _hostUrl = '';
  String _hostDeviceName = '';
  Timer? _heartbeatTimer;
  bool _hasPromptedInstall = false;

  bool get isHostOnline => _isHostOnline;
  String get hostUrl => _hostUrl;
  String get hostDeviceName => _hostDeviceName;

  String _webDeviceId = 'web-${DateTime.now().millisecondsSinceEpoch}';
  String _webDisplayName = 'Web Client';
  String _webPlatform = 'web';

  String get webDeviceId => _webDeviceId;
  String get webDisplayName => _webDisplayName;
  String get webPlatform => _webPlatform;

  void init() {
    if (!kIsWeb) return;

    _hostUrl = Uri.base.origin;
    _initWebIdentity();
    _startHostHeartbeat();
    _requestWebPermissions();
  }

  Future<void> _initWebIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('web_device_id');
      if (id == null || id.isEmpty) {
        id = 'web-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
        await prefs.setString('web_device_id', id);
      }
      _webDeviceId = id;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          _webPlatform = 'android';
          _webDisplayName = 'Android (Web Browser)';
          break;
        case TargetPlatform.iOS:
          _webPlatform = 'ios';
          _webDisplayName = 'iOS (Web Browser)';
          break;
        case TargetPlatform.windows:
          _webPlatform = 'windows';
          _webDisplayName = 'Windows (Web Browser)';
          break;
        case TargetPlatform.macOS:
          _webPlatform = 'macos';
          _webDisplayName = 'Mac (Web Browser)';
          break;
        case TargetPlatform.linux:
          _webPlatform = 'linux';
          _webDisplayName = 'Linux (Web Browser)';
          break;
        default:
          _webPlatform = 'web';
          _webDisplayName = 'Web Browser';
      }
    } catch (_) {}
  }

  void Function(Map<String, dynamic> request)? onPendingPairingReceived;
  String? _lastPendingRequestId;

  void _startHostHeartbeat() {
    _heartbeatTimer?.cancel();
    _checkHostStatus();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkHostStatus();
      _checkPendingPairings();
      _checkPendingDownloads();
    });
  }

  List<Map<String, dynamic>> _discoveredPeers = [];
  List<Map<String, dynamic>> get discoveredPeers => _discoveredPeers;

  final Set<String> _downloadedTransferIds = {};
  void Function(Map<String, dynamic> download)? onPendingDownloadReceived;

  Future<void> _checkPendingDownloads() async {
    try {
      final res = await http
          .get(Uri.parse('$_hostUrl/api/pending_downloads?deviceId=$_webDeviceId'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final downloads = (data['downloads'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final item in downloads) {
          final transferId = item['transferId'] as String? ?? '';
          if (transferId.isNotEmpty && !_downloadedTransferIds.contains(transferId)) {
            _downloadedTransferIds.add(transferId);
            final downloadUrl = '$_hostUrl${item['downloadUrl']}';
            final filename = item['filename'] as String? ?? 'file';
            logger.info('WebPWA', 'New file received from Host: "$filename". Triggering browser download: $downloadUrl');
            SoundEffectService.instance.playIncomingAlert();
            _triggerBrowserDownload(downloadUrl, filename);
            onPendingDownloadReceived?.call(item);
          }
        }
      }
    } catch (_) {}
  }

  void triggerBrowserDownloadFromUrl(String url, String filename) {
    _triggerBrowserDownload(url, filename);
  }

  void _triggerBrowserDownload(String url, String filename) {
    try {
      triggerWebBrowserDownload(url, filename);
    } catch (e) {
      logger.warning('WebPWA', 'Error triggering browser download: $e');
    }
  }

  Future<void> _checkPendingPairings() async {
    try {
      final res = await http
          .get(Uri.parse('$_hostUrl/api/pairing_pending?deviceId=$_webDeviceId'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hasPending = data['hasPending'] as bool? ?? false;
        final reqId = data['requestId'] as String?;
        if (hasPending && reqId != null && reqId != _lastPendingRequestId) {
          _lastPendingRequestId = reqId;
          onPendingPairingReceived?.call(data);
        }
      }
    } catch (_) {}
  }

  Future<void> respondToPairing({
    required String requestId,
    required bool approved,
  }) async {
    try {
      await http.post(
        Uri.parse('$_hostUrl/api/pairing_respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestId': requestId,
          'deviceId': _webDeviceId,
          'approved': approved,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> _checkHostStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$_hostUrl/api/status'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _hostDeviceName = data['hostDeviceName'] as String? ?? 'Host Device';
        if (!_isHostOnline) {
          _isHostOnline = true;
          logger.info('WebPWA', 'Reconnected to host: $_hostDeviceName');
          notifyListeners();
        }

        // Register Web Client with Host
        _registerWebPeer();
        // Fetch active peers from host
        _fetchHostPeers();
      } else {
        _setHostOffline();
      }
    } catch (_) {
      _setHostOffline();
    }
  }

  Future<void> _registerWebPeer() async {
    try {
      await http.post(
        Uri.parse('$_hostUrl/api/web_peer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': _webDeviceId,
          'displayName': _webDisplayName,
          'platform': _webPlatform,
        }),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  bool _isJoined = false;
  bool get isJoined => _isJoined;

  Future<bool> requestJoinEcosystem() async {
    try {
      final res = await http.post(
        Uri.parse('$_hostUrl/api/join_request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': _webDeviceId,
          'displayName': _webDisplayName,
          'platform': _webPlatform,
        }),
      ).timeout(const Duration(seconds: 45));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final approved = data['approved'] as bool? ?? false;
        if (approved) {
          _isJoined = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('web_joined_${_hostUrl}', true);
          notifyListeners();
        }
        return approved;
      }
      return false;
    } catch (e) {
      logger.error('WebPWA', 'Error requesting to join ecosystem: $e');
      return false;
    }
  }

  Future<void> _fetchHostPeers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isJoined = prefs.getBool('web_joined_${_hostUrl}') ?? false;

      final res = await http
          .get(Uri.parse('$_hostUrl/api/peers'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['peers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _discoveredPeers = list;
        notifyListeners();
      }
    } catch (_) {}
  }

  bool _isScanning = false;

  void _setHostOffline() {
    if (_isHostOnline) {
      _isHostOnline = false;
      logger.warning('WebPWA', 'Host is offline ($_hostUrl). Searching for other online devices on LAN...');
      notifyListeners();
      _scanSubnetForActiveHost();
    }
  }

  Future<void> _scanSubnetForActiveHost() async {
    if (_isScanning || _isHostOnline) return;
    _isScanning = true;

    final candidates = <String>{
      'http://ecosystem.local:8080',
      'http://192.168.1.153:8080',
      'http://192.168.1.147:8080',
    };

    // Extract current subnet prefix if possible (e.g., 192.168.1.)
    try {
      final uri = Uri.parse(_hostUrl);
      final host = uri.host;
      final parts = host.split('.');
      if (parts.length == 4) {
        final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        for (int i = 1; i <= 254; i++) {
          candidates.add('http://$prefix.$i:8080');
        }
      }
    } catch (_) {}

    for (final candidate in candidates) {
      if (_isHostOnline) break;
      try {
        final res = await http
            .get(Uri.parse('$candidate/api/status'))
            .timeout(const Duration(milliseconds: 600));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['status'] == 'online') {
            _hostUrl = candidate;
            _hostDeviceName = data['hostDeviceName'] as String? ?? 'Host Device';
            _isHostOnline = true;
            logger.info('WebPWA', '✅ Automatically discovered active ecosystem host at: $candidate ($_hostDeviceName)');
            notifyListeners();
            break;
          }
        }
      } catch (_) {}
    }

    _isScanning = false;
  }

  void setCustomHostUrl(String newUrl) {
    var clean = newUrl.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    _hostUrl = clean;
    _checkHostStatus();
  }

  Future<void> _requestWebPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool('web_perms_requested') ?? false;
    if (!requested) {
      await prefs.setBool('web_perms_requested', true);
    }
  }

  void checkAndShowInstallPrompt(BuildContext context) {
    if (!kIsWeb || _hasPromptedInstall) return;
    _hasPromptedInstall = true;

    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => const _InstallPwaSheet(),
        );
      }
    });
  }
}

class _InstallPwaSheet extends StatelessWidget {
  const _InstallPwaSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.install_mobile_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Install Local Ecosystem',
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Install to Home Screen for the full native experience',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            const _InstructionStep(
              number: '1',
              icon: Icons.ios_share_rounded,
              title: 'Tap the Share Button',
              description: 'Located in the top toolbar or bottom bar of Safari.',
            ),
            const SizedBox(height: 12),
            const _InstructionStep(
              number: '2',
              icon: Icons.add_box_outlined,
              title: 'Select "Add to Home Screen"',
              description: 'Scroll down the share menu and tap "+ Add to Home Screen".',
            ),
            const SizedBox(height: 12),
            const _InstructionStep(
              number: '3',
              icon: Icons.check_circle_outline_rounded,
              title: 'Tap "Add"',
              description: 'The app icon will appear directly on your Home Screen.',
            ),
          ] else if (defaultTargetPlatform == TargetPlatform.android) ...[
            const _InstructionStep(
              number: '1',
              icon: Icons.more_vert_rounded,
              title: 'Tap the Menu Button',
              description: 'Tap the three dots (⋮) in Chrome at the top right.',
            ),
            const SizedBox(height: 12),
            const _InstructionStep(
              number: '2',
              icon: Icons.add_to_home_screen_rounded,
              title: 'Select "Install app" or "Add to Home screen"',
              description: 'Choose the install option from the menu list.',
            ),
            const SizedBox(height: 12),
            const _InstructionStep(
              number: '3',
              icon: Icons.check_circle_outline_rounded,
              title: 'Tap "Install"',
              description: 'The web app will be added directly to your app launcher.',
            ),
          ] else ...[
            const _InstructionStep(
              number: '1',
              icon: Icons.install_desktop_rounded,
              title: 'Click the Install Icon',
              description: 'Click the install button (⊕) in the browser address bar.',
            ),
            const SizedBox(height: 12),
            const _InstructionStep(
              number: '2',
              icon: Icons.check_circle_outline_rounded,
              title: 'Click "Install"',
              description: 'Runs in a standalone high-speed window with no browser tabs.',
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got It!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(number,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(title,
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Text(description,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
