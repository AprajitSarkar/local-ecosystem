// lib/domain/entities/clipboard_event.dart

class ClipboardEvent {
  const ClipboardEvent({
    required this.eventId,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
    required this.text,
    required this.timestamp,
    required this.payloadHash,
    this.isLocal = false,
  });

  final String eventId;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final String text;
  final DateTime timestamp;
  final String payloadHash;
  final bool isLocal;
}

class LinkOffer {
  const LinkOffer({
    required this.offerId,
    required this.url,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
    required this.timestamp,
  });

  final String offerId;
  final String url;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final DateTime timestamp;
}
