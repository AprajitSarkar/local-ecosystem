// test/unit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ecosystem/application/media_control_service.dart';
import 'package:local_ecosystem/application/notification_mirror_service.dart';
import 'package:local_ecosystem/data/discovery/mdns_service.dart';
import 'package:local_ecosystem/data/transport/protocol.dart';

void main() {
  group('Protocol & Discovery Unit Tests', () {
    test('ProtocolMessage encode and decode properly', () {
      final msg = ProtocolMessage(
        version: 1,
        type: msgPairingRequest,
        messageId: 'test-uuid',
        sourceDeviceId: 'device-123',
        timestamp: DateTime(2026, 8, 30, 15, 0, 0),
        payload: {
          'displayName': 'Windows PC',
          'platform': 'windows',
          'ecosystemName': 'My Ecosystem',
        },
      );

      final encoded = msg.encode();
      final decoded = ProtocolMessage.decode(encoded);

      expect(decoded.isValid, isTrue);
      expect(decoded.type, equals(msgPairingRequest));
      expect(decoded.sourceDeviceId, equals('device-123'));
      expect(decoded.payload['displayName'], equals('Windows PC'));
      expect(decoded.payload['ecosystemName'], equals('My Ecosystem'));
    });

    test('DiscoveredPeer holds correct metadata', () {
      const peer = DiscoveredPeer(
        deviceId: 'phone-456',
        displayName: 'Galaxy S24',
        platform: 'android',
        address: '192.168.1.50',
        port: 8080,
        protocolVersion: 1,
        ecosystemHint: 'Aprajit’s Ecosystem',
        capabilities: ['clipboard', 'file', 'link'],
      );

      expect(peer.deviceId, equals('phone-456'));
      expect(peer.displayName, equals('Galaxy S24'));
      expect(peer.ecosystemHint, equals('Aprajit’s Ecosystem'));
      expect(peer.port, equals(8080));
      expect(peer.capabilities, contains('file'));
    });

    test('RemoteMediaState serializes correctly', () {
      final media = RemoteMediaState(
        deviceId: 'phone-001',
        deviceName: 'Pixel 9',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        isPlaying: true,
      );

      final json = media.toJson();
      final reconstructed = RemoteMediaState.fromJson(json);

      expect(reconstructed.title, equals('Starboy'));
      expect(reconstructed.artist, equals('The Weeknd'));
      expect(reconstructed.isPlaying, isTrue);
    });

    test('NotificationMirrorService extracts OTP accurately', () {
      final testCases = {
        'Your verification code is 482910. Do not share.': '482910',
        'Use OTP 8291 to verify your login.': '8291',
        'Your bank password reset pin is 938472': '938472',
      };

      for (final entry in testCases.entries) {
        final otp = NotificationMirrorService.instance.extractOtpForTesting(entry.key);
        expect(otp, equals(entry.value));
      }
    });
  });
}
