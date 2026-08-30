// lib/data/transport/protocol.dart
// Versioned message envelope + all message types for the LAN protocol.

import 'dart:convert';

const int kProtocolVersion = 1;
const int kDefaultPort = 51413;
const int kChunkSize = 64 * 1024; // 64 KB chunks

// ─── Message type constants ───────────────────────────────────────────────────

const String msgHello          = 'hello';
const String msgPairingRequest = 'pairing_request';
const String msgPairingResponse= 'pairing_response';
const String msgEcosystemState = 'ecosystem_state';
const String msgClipboardEvent = 'clipboard_event';
const String msgTransferOffer  = 'transfer_offer';
const String msgTransferAccept = 'transfer_accept';
const String msgTransferReject = 'transfer_reject';
const String msgTransferChunk  = 'transfer_chunk';
const String msgTransferProgress = 'transfer_progress';
const String msgTransferComplete = 'transfer_complete';
const String msgTransferCancel = 'transfer_cancel';
const String msgLinkOffer      = 'link_offer';
const String msgDevicePresence = 'device_presence';
const String msgHeartbeat      = 'heartbeat';
const String msgError          = 'error';

// ─── Envelope ─────────────────────────────────────────────────────────────────

class ProtocolMessage {
  const ProtocolMessage({
    required this.version,
    required this.type,
    required this.messageId,
    required this.sourceDeviceId,
    required this.timestamp,
    required this.payload,
  });

  final int version;
  final String type;
  final String messageId;
  final String sourceDeviceId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    final rawTs = json['timestamp'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return ProtocolMessage(
      version: (json['version'] as num?)?.toInt() ?? kProtocolVersion,
      type: json['type']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      sourceDeviceId: json['sourceDeviceId']?.toString() ?? '',
      timestamp: ts,
      payload: (json['payload'] is Map)
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'type': type,
    'messageId': messageId,
    'sourceDeviceId': sourceDeviceId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());

  static ProtocolMessage decode(String raw) =>
      ProtocolMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Validate that required fields are present and version is supported.
  bool get isValid =>
      version == kProtocolVersion &&
      type.isNotEmpty &&
      messageId.isNotEmpty &&
      sourceDeviceId.isNotEmpty;
}

// ─── Payload builders ─────────────────────────────────────────────────────────

Map<String, dynamic> helloPayload({
  required String displayName,
  required String platform,
  required List<String> capabilities,
  required String ecosystemHint,
}) => {
  'displayName': displayName,
  'platform': platform,
  'capabilities': capabilities,
  'ecosystemHint': ecosystemHint,
};

Map<String, dynamic> pairingRequestPayload({
  required String displayName,
  required String platform,
  required String publicKey,
  required String ecosystemId,
  required String ecosystemName,
}) => {
  'displayName': displayName,
  'platform': platform,
  'publicKey': publicKey,
  'ecosystemId': ecosystemId,
  'ecosystemName': ecosystemName,
};

Map<String, dynamic> pairingResponsePayload({
  required bool approved,
  required String displayName,
  required String publicKey,
  String platform = 'unknown',
}) => {
  'approved': approved,
  'displayName': displayName,
  'publicKey': publicKey,
  'platform': platform,
};

Map<String, dynamic> clipboardEventPayload({
  required String eventId,
  required String text,
  required String payloadHash,
}) => {
  'eventId': eventId,
  'text': text,
  'payloadHash': payloadHash,
};

Map<String, dynamic> transferOfferPayload({
  required String transferId,
  required String filename,
  required String mimeType,
  required int totalBytes,
  required String sha256Hash,
}) => {
  'transferId': transferId,
  'filename': filename,
  'mimeType': mimeType,
  'totalBytes': totalBytes,
  'sha256Hash': sha256Hash,
};

Map<String, dynamic> transferAcceptPayload({required String transferId}) =>
    {'transferId': transferId};

Map<String, dynamic> transferRejectPayload({
  required String transferId,
  required String reason,
}) => {'transferId': transferId, 'reason': reason};

Map<String, dynamic> transferCompletePayload({
  required String transferId,
  required String sha256Hash,
}) => {'transferId': transferId, 'sha256Hash': sha256Hash};

Map<String, dynamic> linkOfferPayload({
  required String offerId,
  required String url,
}) => {'offerId': offerId, 'url': url};
