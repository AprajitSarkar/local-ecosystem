// lib/domain/entities/transfer.dart

enum TransferState {
  queued,
  discovering,
  connecting,
  preparing,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
}

enum TransferDirection { outgoing, incoming }

class TransferProgress {
  const TransferProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    this.speedBytesPerSec = 0,
    this.etaSeconds,
  });

  final int bytesTransferred;
  final int totalBytes;
  final double speedBytesPerSec;
  final int? etaSeconds;

  double get percentage =>
      totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : 0.0;
}

class Transfer {
  const Transfer({
    required this.transferId,
    required this.filename,
    required this.mimeType,
    required this.totalBytes,
    required this.direction,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.state,
    required this.startedAt,
    this.completedAt,
    this.localPath,
    this.progress,
    this.errorMessage,
  });

  final String transferId;
  final String filename;
  final String mimeType;
  final int totalBytes;
  final TransferDirection direction;
  final String peerDeviceId;
  final String peerDeviceName;
  final TransferState state;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? localPath;
  final TransferProgress? progress;
  final String? errorMessage;

  bool get isActive =>
      state == TransferState.connecting ||
      state == TransferState.preparing ||
      state == TransferState.transferring;

  bool get isTerminal =>
      state == TransferState.completed ||
      state == TransferState.failed ||
      state == TransferState.cancelled;

  Transfer copyWith({
    TransferState? state,
    int? totalBytes,
    TransferProgress? progress,
    String? localPath,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return Transfer(
      transferId: transferId,
      filename: filename,
      mimeType: mimeType,
      totalBytes: totalBytes ?? this.totalBytes,
      direction: direction,
      peerDeviceId: peerDeviceId,
      peerDeviceName: peerDeviceName,
      state: state ?? this.state,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      localPath: localPath ?? this.localPath,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
