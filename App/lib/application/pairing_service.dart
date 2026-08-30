// lib/application/pairing_service.dart
// Manages the full pairing lifecycle:
//  - Outgoing: send pairing_request → wait for approval → store trusted device
//  - Incoming: receive pairing_request → show UI → approve/reject → respond

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/logging/app_logger.dart';
import '../core/web/web_pwa_service.dart';
import '../data/local/database.dart';
import '../data/local/daos/device_dao.dart';
import '../data/security/device_identity.dart';
import '../data/transport/protocol.dart';
import '../data/transport/tcp_client.dart';
import '../domain/entities/device.dart' as domain;
import 'settings_service.dart';
import 'web_portal_server.dart';

/// Result of an outgoing pairing attempt.
sealed class PairingResult {}

class PairingApproved extends PairingResult {
  PairingApproved({required this.peerName, required this.peerPublicKey});
  final String peerName;
  final String peerPublicKey;
}

class PairingRejected extends PairingResult {}

class PairingTimeout extends PairingResult {}

class PairingError extends PairingResult {
  PairingError(this.message);
  final String message;
}

/// An incoming pairing request from a remote device.
class IncomingPairingRequest {
  const IncomingPairingRequest({
    required this.messageId,
    required this.sourceDeviceId,
    required this.displayName,
    required this.platform,
    required this.publicKey,
    required this.ecosystemId,
    required this.ecosystemName,
    this.socket,
    required this.respondWith,
  });

  final String messageId;
  final String sourceDeviceId;
  final String displayName;
  final String platform;
  final String publicKey;
  final String ecosystemId;
  final String ecosystemName;
  final Socket? socket;
  final Future<void> Function(bool approved) respondWith;
}

class PairingService {
  PairingService({required this.db, required this.deviceDao}) {
    if (!kIsWeb) {
      WebPortalServer.instance.pairingService = this;
    }
  }

  final AppDatabase db;
  final DeviceDao deviceDao;

  final _incomingController =
      StreamController<IncomingPairingRequest>.broadcast();

  Stream<IncomingPairingRequest> get incomingRequests =>
      _incomingController.stream;

  void emitIncomingRequest(IncomingPairingRequest req) {
    _incomingController.add(req);
  }

  // ── Outgoing pairing ──────────────────────────────────────────────────────

  /// Send a pairing request to the target peer and wait for response.
  Future<PairingResult> sendPairingRequest({
    required String targetAddress,
    required int targetPort,
    required String targetDeviceId,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    if (kIsWeb || (targetPort >= 8080 && targetPort <= 8090 && !targetDeviceId.startsWith('web-'))) {
      try {
        final hostUrl = (targetAddress.isNotEmpty && targetAddress != '127.0.0.1' && targetAddress != 'localhost')
            ? 'http://$targetAddress:$targetPort'
            : (WebPwaService.instance.hostUrl.isNotEmpty
                ? WebPwaService.instance.hostUrl
                : Uri.base.origin);

        if (kIsWeb) {
          WebPwaService.instance.setCustomHostUrl(hostUrl);
        }

        final res = await http.post(
          Uri.parse('$hostUrl/api/join_request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': identity.deviceId,
            'displayName': settings.deviceName,
            'platform': _platformString(),
          }),
        ).timeout(const Duration(seconds: 45));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final approved = data['approved'] as bool? ?? false;
          if (approved) {
            final ecoName = data['ecosystemName'] as String? ?? "Local Ecosystem";
            final ecoId = data['ecosystemId'] as String? ?? const Uuid().v4();
            final hostName = data['hostDeviceName'] as String? ?? "Host Device";

            await settings.saveAndActivateEcosystem(name: ecoName, id: ecoId);
            final hostPlatform = data['platform'] as String? ?? domain.DevicePlatform.fromString(null, hostName).name;
            await _storeTrustedDevice(
              deviceId: data['deviceId'] as String? ?? targetDeviceId,
              displayName: hostName,
              platform: hostPlatform,
              publicKey: identity.publicKeyBase64,
            );
            return PairingApproved(
              peerName: hostName,
              peerPublicKey: identity.publicKeyBase64,
            );
          } else {
            return PairingRejected();
          }
        }
      } catch (e) {
        logger.warning('PairingService', 'HTTP join request failed, trying TCP fallback: $e');
        if (kIsWeb) {
          return PairingError('Failed to join ecosystem: $e');
        }
      }
    }

    if (targetDeviceId.startsWith('web-') || targetDeviceId.contains('web')) {
      // Request pairing on Web client — wait for user to accept on web browser screen!
      final approved = await WebPortalServer.instance.requestWebClientPairing(
        targetDeviceId: targetDeviceId,
        hostName: settings.deviceName,
        hostDeviceId: identity.deviceId,
        ecosystemName: settings.ecosystemName,
        ecosystemId: settings.ecosystemId,
      );

      if (approved) {
        final webPeer = WebPortalServer.instance.getWebPeer(targetDeviceId);
        final displayName = webPeer?['displayName'] as String? ?? 'Web Client';
        final platform = webPeer?['platform'] as String? ?? 'web';

        await _storeTrustedDevice(
          deviceId: targetDeviceId,
          displayName: displayName,
          platform: platform,
          publicKey: identity.publicKeyBase64,
        );
        return PairingApproved(
          peerName: displayName,
          peerPublicKey: identity.publicKeyBase64,
        );
      } else {
        return PairingRejected();
      }
    }

    PeerConnection? conn;
    try {
      conn = PeerConnection(
        deviceId: targetDeviceId,
        address: targetAddress,
        port: targetPort,
      );
      await conn.connect(timeout: const Duration(seconds: 10));

      // Send pairing_request with actual hardware model name & ecosystem info
      final msg = ProtocolMessage(
        version: kProtocolVersion,
        type: msgPairingRequest,
        messageId: const Uuid().v4(),
        sourceDeviceId: identity.deviceId,
        timestamp: DateTime.now(),
        payload: pairingRequestPayload(
          displayName: settings.deviceName,
          platform: _platformString(),
          publicKey: identity.publicKeyBase64,
          ecosystemId: settings.ecosystemId,
          ecosystemName: settings.ecosystemName,
        ),
      );
      await conn.send(msg);

      logger.info('PairingService',
          'Sent pairing request to $targetAddress:$targetPort from "${settings.deviceName}"');

      // Wait for response
      final response = await conn.messages
          .where((m) => m.type == msgPairingResponse)
          .timeout(timeout)
          .first
          .catchError((e) => throw TimeoutException('Pairing timed out'));

      final approved = response.payload['approved'] as bool? ?? false;
      if (approved) {
        final peerName = response.payload['displayName'] as String? ?? 'Unknown';
        final peerPublicKey = response.payload['publicKey'] as String? ?? '';
        final peerPlatform = response.payload['platform'] as String? ??
            domain.DevicePlatform.fromString(null, peerName).name;

        // Persist trusted device
        await _storeTrustedDevice(
          deviceId: targetDeviceId,
          displayName: peerName,
          platform: peerPlatform,
          publicKey: peerPublicKey,
        );

        logger.info('PairingService', 'Pairing approved by $peerName ($peerPlatform)');
        return PairingApproved(peerName: peerName, peerPublicKey: peerPublicKey);
      } else {
        logger.info('PairingService', 'Pairing rejected by peer');
        return PairingRejected();
      }
    } on TimeoutException {
      return PairingTimeout();
    } catch (e) {
      logger.error('PairingService', 'Pairing error', e);
      return PairingError(e.toString());
    } finally {
      await conn?.disconnect();
    }
  }

  // ── Incoming pairing ──────────────────────────────────────────────────────

  /// Called by the TCP server when a pairing_request message arrives.
  Future<void> handleIncomingRequest(
    ProtocolMessage msg,
    Socket socket,
  ) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;
    final payload = msg.payload;

    final request = IncomingPairingRequest(
      messageId: msg.messageId,
      sourceDeviceId: msg.sourceDeviceId,
      displayName: payload['displayName'] as String? ?? 'Unknown Device',
      platform: payload['platform'] as String? ?? 'unknown',
      publicKey: payload['publicKey'] as String? ?? '',
      ecosystemId: payload['ecosystemId'] as String? ?? '',
      ecosystemName: payload['ecosystemName'] as String? ?? '',
      socket: socket,
      respondWith: (approved) async {
        final response = ProtocolMessage(
          version: kProtocolVersion,
          type: msgPairingResponse,
          messageId: const Uuid().v4(),
          sourceDeviceId: identity.deviceId,
          timestamp: DateTime.now(),
          payload: pairingResponsePayload(
            approved: approved,
            displayName: settings.deviceName,
            publicKey: identity.publicKeyBase64,
            platform: _platformString(),
          ),
        );
        try {
          socket.write('${response.encode()}\n');
          await socket.flush();
        } catch (e) {
          logger.warning('PairingService', 'Could not send pairing response: $e');
        }

        if (approved) {
          await _storeTrustedDevice(
            deviceId: msg.sourceDeviceId,
            displayName: payload['displayName'] as String? ?? 'Unknown',
            platform: payload['platform'] as String? ?? 'unknown',
            publicKey: payload['publicKey'] as String? ?? '',
          );

          // If this device had no active ecosystem, join the sender's ecosystem!
          if (!settings.hasActiveEcosystem &&
              payload['ecosystemId'] != null &&
              (payload['ecosystemId'] as String).isNotEmpty) {
            await settings.saveAndActivateEcosystem(
              id: payload['ecosystemId'] as String,
              name: payload['ecosystemName'] as String? ?? 'My Ecosystem',
            );
          }

          logger.info('PairingService',
              'Approved pairing with ${payload['displayName']}');
        }
      },
    );

    _incomingController.add(request);
  }

  // ── Trust store ───────────────────────────────────────────────────────────

  Future<void> _storeTrustedDevice({
    required String deviceId,
    required String displayName,
    required String platform,
    required String publicKey,
  }) async {
    final norm = domain.DevicePlatform.fromString(platform, displayName).name;
    await deviceDao.upsertDevice(DeviceTableCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      platform: Value(norm),
      publicKey: Value(publicKey),
      capabilities: const Value('[]'),
      trustStatus: Value(domain.TrustStatus.trusted.name),
      addedAt: Value(DateTime.now()),
    ));
  }

  Future<bool> isTrusted(String deviceId) async {
    final device = await deviceDao.getDevice(deviceId);
    return device?.trustStatus == domain.TrustStatus.trusted.name;
  }

  Future<void> removeDevice(String deviceId) async {
    await deviceDao.deleteDevice(deviceId);
    logger.info('PairingService', 'Removed device $deviceId');
  }

  void dispose() {
    _incomingController.close();
  }

  static String _platformString() {
    if (kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'android';
        case TargetPlatform.iOS:
          return 'ios';
        case TargetPlatform.windows:
          return 'windows';
        case TargetPlatform.macOS:
          return 'macos';
        case TargetPlatform.linux:
          return 'linux';
        default:
          return 'web';
      }
    }
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
}
