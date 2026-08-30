// lib/core/network/adaptive_throughput_tuner.dart
// Real-time throughput monitor & dynamic chunk tuner for maximum LAN transfer speeds.

import 'dart:async';
import 'dart:math';

class ThroughputSnapshot {
  const ThroughputSnapshot({
    required this.bytesTransferred,
    required this.speedBytesPerSec,
    required this.currentChunkSizeBytes,
    required this.percentage,
  });

  final int bytesTransferred;
  final double speedBytesPerSec;
  final int currentChunkSizeBytes;
  final double percentage;

  double get speedMbps => (speedBytesPerSec * 8) / (1000 * 1000);
  double get speedMBps => speedBytesPerSec / (1024 * 1024);
}

class AdaptiveThroughputTuner {
  AdaptiveThroughputTuner({
    required this.totalBytes,
    required int initialChunkSizeBytes,
    required this.maxChunkSizeBytes,
    this.minChunkSizeBytes = 512 * 1024,
  }) : currentChunkSize = initialChunkSizeBytes {
    _startTime = DateTime.now();
    _lastSampleTime = _startTime;
  }

  final int totalBytes;
  final int maxChunkSizeBytes;
  final int minChunkSizeBytes;

  int currentChunkSize;
  int _transferredBytes = 0;
  late DateTime _startTime;
  late DateTime _lastSampleTime;
  int _lastSampleBytes = 0;

  double _currentSpeedBytesPerSec = 0.0;
  final List<double> _speedSamples = [];

  void recordProgress(int bytesChunkSize) {
    _transferredBytes += bytesChunkSize;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastSampleTime).inMilliseconds;

    if (elapsedMs >= 200) {
      final bytesSinceSample = _transferredBytes - _lastSampleBytes;
      final instSpeed = (bytesSinceSample / elapsedMs) * 1000.0;

      _speedSamples.add(instSpeed);
      if (_speedSamples.length > 5) _speedSamples.removeAt(0);

      // Moving average
      _currentSpeedBytesPerSec =
          _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;

      _lastSampleTime = now;
      _lastSampleBytes = _transferredBytes;

      // ── Adaptive Dynamic Tuning ──────────────────────────────────────────
      // If speed is above 30 MB/s, expand chunk size up to max
      if (_currentSpeedBytesPerSec > 30 * 1024 * 1024 &&
          currentChunkSize < maxChunkSizeBytes) {
        currentChunkSize = min(maxChunkSizeBytes, currentChunkSize * 2);
      } else if (_currentSpeedBytesPerSec > 10 * 1024 * 1024 &&
          currentChunkSize < maxChunkSizeBytes ~/ 2) {
        currentChunkSize = min(maxChunkSizeBytes, (currentChunkSize * 1.5).toInt());
      } else if (_currentSpeedBytesPerSec < 2 * 1024 * 1024 &&
          currentChunkSize > minChunkSizeBytes * 2) {
        // High latency or small buffers, reduce chunk size for smoother flow
        currentChunkSize = max(minChunkSizeBytes, currentChunkSize ~/ 2);
      }
    }
  }

  ThroughputSnapshot getSnapshot() {
    final pct = totalBytes > 0 ? (_transferredBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
    return ThroughputSnapshot(
      bytesTransferred: _transferredBytes,
      speedBytesPerSec: _currentSpeedBytesPerSec,
      currentChunkSizeBytes: currentChunkSize,
      percentage: pct,
    );
  }
}
