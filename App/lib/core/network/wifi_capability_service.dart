// lib/core/network/wifi_capability_service.dart
// Hardware & OS Wi-Fi capability detection — detects 2.4GHz / 5GHz / 6GHz, standard, link speed, and P2P.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

enum WifiBand {
  ghz2_4,
  ghz5,
  ghz6,
  unknown;

  String get label {
    switch (this) {
      case WifiBand.ghz6:
        return '6 GHz (Wi-Fi 6E / 7 Ultra-Fast)';
      case WifiBand.ghz5:
        return '5 GHz (High-Speed)';
      case WifiBand.ghz2_4:
        return '2.4 GHz (Standard)';
      case WifiBand.unknown:
        return 'LAN / Ethernet';
    }
  }

  int get priority {
    switch (this) {
      case WifiBand.ghz6:
        return 4;
      case WifiBand.ghz5:
        return 3;
      case WifiBand.ghz2_4:
        return 2;
      case WifiBand.unknown:
        return 1;
    }
  }
}

class WifiCapability {
  const WifiCapability({
    required this.band,
    required this.standard,
    required this.linkSpeedMbps,
    required this.isP2pSupported,
    required this.frequencyMhz,
    required this.supportedMaxChunkSizeBytes,
    required this.recommendedParallelStreams,
  });

  final WifiBand band;
  final String standard;
  final int linkSpeedMbps;
  final bool isP2pSupported;
  final int frequencyMhz;
  final int supportedMaxChunkSizeBytes;
  final int recommendedParallelStreams;

  Map<String, dynamic> toJson() => {
        'band': band.name,
        'standard': standard,
        'linkSpeedMbps': linkSpeedMbps,
        'isP2pSupported': isP2pSupported,
        'frequencyMhz': frequencyMhz,
        'maxChunkSize': supportedMaxChunkSizeBytes,
        'parallelStreams': recommendedParallelStreams,
      };

  factory WifiCapability.fromJson(Map<String, dynamic> json) {
    return WifiCapability(
      band: WifiBand.values.firstWhere(
        (b) => b.name == json['band'],
        orElse: () => WifiBand.unknown,
      ),
      standard: json['standard'] as String? ?? '802.11ac',
      linkSpeedMbps: (json['linkSpeedMbps'] as num?)?.toInt() ?? 300,
      isP2pSupported: json['isP2pSupported'] as bool? ?? false,
      frequencyMhz: (json['frequencyMhz'] as num?)?.toInt() ?? 5000,
      supportedMaxChunkSizeBytes:
          (json['maxChunkSize'] as num?)?.toInt() ?? (4 * 1024 * 1024),
      recommendedParallelStreams:
          (json['parallelStreams'] as num?)?.toInt() ?? 2,
    );
  }

  static const WifiCapability fallback = WifiCapability(
    band: WifiBand.ghz5,
    standard: '802.11ac High-Speed',
    linkSpeedMbps: 433,
    isP2pSupported: true,
    frequencyMhz: 5200,
    supportedMaxChunkSizeBytes: 4 * 1024 * 1024,
    recommendedParallelStreams: 3,
  );
}

class WifiCapabilityService {
  WifiCapabilityService._();
  static final WifiCapabilityService instance = WifiCapabilityService._();

  static const _channel = MethodChannel('com.localecosystem/clipboard');
  WifiCapability? _cachedCapability;

  Future<WifiCapability> detectCapabilities() async {
    if (_cachedCapability != null) return _cachedCapability!;

    try {
      if (kIsWeb) {
        _cachedCapability = WifiCapability.fallback;
      } else if (Platform.isAndroid) {
        _cachedCapability = await _detectAndroidCapabilities();
      } else if (Platform.isLinux) {
        _cachedCapability = await _detectLinuxCapabilities();
      } else if (Platform.isMacOS || Platform.isIOS) {
        _cachedCapability = _detectAppleCapabilities();
      } else {
        _cachedCapability = WifiCapability.fallback;
      }
    } catch (e) {
      logger.warning('WifiCapability', 'Failed to detect capabilities: $e');
      _cachedCapability = WifiCapability.fallback;
    }

    logger.info(
      'WifiCapability',
      'Detected: ${_cachedCapability!.band.label}, Standard: ${_cachedCapability!.standard}, Link: ${_cachedCapability!.linkSpeedMbps} Mbps, P2P: ${_cachedCapability!.isP2pSupported}',
    );

    return _cachedCapability!;
  }

  Future<WifiCapability> _detectAndroidCapabilities() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getWifiCapabilities');
      if (res != null) {
        final freq = (res['frequency'] as num?)?.toInt() ?? 5200;
        final speed = (res['linkSpeed'] as num?)?.toInt() ?? 866;
        final p2p = res['isP2pSupported'] as bool? ?? true;
        final standard = res['standard'] as String? ?? 'Wi-Fi 6 (802.11ax)';

        WifiBand band = WifiBand.ghz5;
        if (freq >= 5925) {
          band = WifiBand.ghz6;
        } else if (freq >= 4900) {
          band = WifiBand.ghz5;
        } else if (freq >= 2400) {
          band = WifiBand.ghz2_4;
        }

        final maxChunk = band == WifiBand.ghz6
            ? 8 * 1024 * 1024
            : (band == WifiBand.ghz5 ? 4 * 1024 * 1024 : 1 * 1024 * 1024);
        final streams = band == WifiBand.ghz6 ? 4 : (band == WifiBand.ghz5 ? 3 : 2);

        return WifiCapability(
          band: band,
          standard: standard,
          linkSpeedMbps: speed,
          isP2pSupported: p2p,
          frequencyMhz: freq,
          supportedMaxChunkSizeBytes: maxChunk,
          recommendedParallelStreams: streams,
        );
      }
    } catch (_) {}

    return WifiCapability.fallback;
  }

  Future<WifiCapability> _detectLinuxCapabilities() async {
    try {
      final res = await Process.run('iw', ['dev']);
      final iwOutput = res.stdout.toString();

      int freq = 5200;
      int speed = 866;
      WifiBand band = WifiBand.ghz5;
      String standard = '802.11ax (Wi-Fi 6)';

      if (iwOutput.contains('MHz')) {
        final match = RegExp(r'(\d{4})\s*MHz').firstMatch(iwOutput);
        if (match != null) {
          freq = int.tryParse(match.group(1)!) ?? 5200;
          if (freq >= 5925) {
            band = WifiBand.ghz6;
            standard = '802.11be / ax (Wi-Fi 6E / 7)';
            speed = 1200;
          } else if (freq >= 4900) {
            band = WifiBand.ghz5;
            standard = '802.11ax / ac (Wi-Fi 6 / 5)';
            speed = 866;
          } else {
            band = WifiBand.ghz2_4;
            standard = '802.11n (Wi-Fi 4)';
            speed = 144;
          }
        }
      }

      final maxChunk = band == WifiBand.ghz6
          ? 16 * 1024 * 1024
          : (band == WifiBand.ghz5 ? 8 * 1024 * 1024 : 2 * 1024 * 1024);
      final streams = band == WifiBand.ghz6 ? 4 : (band == WifiBand.ghz5 ? 4 : 2);

      return WifiCapability(
        band: band,
        standard: standard,
        linkSpeedMbps: speed,
        isP2pSupported: true,
        frequencyMhz: freq,
        supportedMaxChunkSizeBytes: maxChunk,
        recommendedParallelStreams: streams,
      );
    } catch (_) {
      return WifiCapability.fallback;
    }
  }

  WifiCapability _detectAppleCapabilities() {
    return const WifiCapability(
      band: WifiBand.ghz5,
      standard: '802.11ax (Wi-Fi 6 Apple Silicon / iPad)',
      linkSpeedMbps: 1200,
      isP2pSupported: true,
      frequencyMhz: 5240,
      supportedMaxChunkSizeBytes: 8 * 1024 * 1024,
      recommendedParallelStreams: 4,
    );
  }
}
