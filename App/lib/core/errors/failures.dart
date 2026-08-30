// lib/core/errors/failures.dart

sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class PairingFailure extends Failure {
  const PairingFailure(super.message);
}

class TransferFailure extends Failure {
  const TransferFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class CryptoFailure extends Failure {
  const CryptoFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Convert a raw exception to a human-readable failure message.
Failure mapException(Object e) {
  final msg = e.toString();
  if (msg.contains('SocketException') || msg.contains('Connection refused')) {
    return const NetworkFailure('Could not reach the device. Check it is on the same network.');
  }
  if (msg.contains('TlsException') || msg.contains('HandshakeException')) {
    return const NetworkFailure('Secure connection failed. The device identity may have changed.');
  }
  if (msg.contains('FileSystemException')) {
    return const StorageFailure('Could not access the storage location. Check permissions.');
  }
  return NetworkFailure('An unexpected error occurred: $msg');
}
