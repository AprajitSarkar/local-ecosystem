// lib/core/network/capability_negotiator.dart
// Exchanges device network capabilities to select the fastest possible transport & streaming params.

import 'dart:math';
import '../logging/app_logger.dart';
import 'wifi_capability_service.dart';

class NegotiatedTransferConfig {
  const NegotiatedTransferConfig({
    required this.transportMode,
    required this.initialChunkSizeBytes,
    required this.maxChunkSizeBytes,
    required this.parallelStreams,
    required this.estimatedBandwidthMbps,
    required this.isP2pDirectActive,
    required this.useZeroCopyStreaming,
  });

  final String transportMode; // 'P2P_DIRECT', 'LAN_6GHZ', 'LAN_5GHZ', 'LAN_FALLBACK'
  final int initialChunkSizeBytes;
  final int maxChunkSizeBytes;
  final int parallelStreams;
  final int estimatedBandwidthMbps;
  final bool isP2pDirectActive;
  final bool useZeroCopyStreaming;

  @override
  String toString() =>
      'NegotiatedConfig[mode: $transportMode, initialChunk: ${initialChunkSizeBytes ~/ 1024}KB, maxChunk: ${maxChunkSizeBytes ~/ (1024 * 1024)}MB, streams: $parallelStreams, estimatedSpeed: $estimatedBandwidthMbps Mbps]';
}

class CapabilityNegotiator {
  CapabilityNegotiator._();

  static NegotiatedTransferConfig negotiate({
    required WifiCapability localCap,
    required WifiCapability remoteCap,
    required int totalFileSizeBytes,
  }) {
    // 1. Determine highest common Wi-Fi band
    final minBandPriority = min(localCap.band.priority, remoteCap.band.priority);
    final isP2pFeasible = localCap.isP2pSupported && remoteCap.isP2pSupported;

    String mode;
    bool isP2p = false;

    if (isP2pFeasible && minBandPriority >= 3) {
      mode = 'P2P_DIRECT';
      isP2p = true;
    } else if (minBandPriority >= 4) {
      mode = 'LAN_6GHZ_ULTRA';
    } else if (minBandPriority >= 3) {
      mode = 'LAN_5GHZ_HIGH_SPEED';
    } else {
      mode = 'LAN_STANDARD_FALLBACK';
    }

    final estimatedSpeed = min(localCap.linkSpeedMbps, remoteCap.linkSpeedMbps);

    // 2. Determine initial chunk size (1 MB to 4 MB based on file size & bandwidth)
    int initialChunkSize;
    if (totalFileSizeBytes > 100 * 1024 * 1024) {
      initialChunkSize = min(4 * 1024 * 1024, min(localCap.supportedMaxChunkSizeBytes, remoteCap.supportedMaxChunkSizeBytes));
    } else if (totalFileSizeBytes > 20 * 1024 * 1024) {
      initialChunkSize = 2 * 1024 * 1024;
    } else {
      initialChunkSize = 1 * 1024 * 1024;
    }

    final maxChunkSize = max(
      initialChunkSize,
      min(localCap.supportedMaxChunkSizeBytes, remoteCap.supportedMaxChunkSizeBytes),
    );

    // 3. Determine parallel streams (1 to 4)
    int streams = min(localCap.recommendedParallelStreams, remoteCap.recommendedParallelStreams);
    if (totalFileSizeBytes < 5 * 1024 * 1024) {
      streams = 1; // Small files don't need multi-stream overhead
    }

    final config = NegotiatedTransferConfig(
      transportMode: mode,
      initialChunkSizeBytes: initialChunkSize,
      maxChunkSizeBytes: maxChunkSize,
      parallelStreams: streams,
      estimatedBandwidthMbps: estimatedSpeed,
      isP2pDirectActive: isP2p,
      useZeroCopyStreaming: true,
    );

    logger.info('CapabilityNegotiator', 'Negotiation complete: $config');
    return config;
  }
}
