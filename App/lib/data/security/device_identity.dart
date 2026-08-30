// lib/data/security/device_identity.dart
// Generates or loads a stable per-installation Ed25519 key pair.
// Private key is stored in SharedPreferences for MVP (with a TODO to move
// to platform secure storage like Android Keystore / iOS Keychain).

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/logging/app_logger.dart';

const _kDeviceIdKey = 'device_identity_id';
const _kPrivateKeyKey = 'device_identity_private_key';
const _kPublicKeyKey = 'device_identity_public_key';

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.publicKeyBase64,
    required this.keyPair,
  });

  final String deviceId;
  final String publicKeyBase64;
  final SimpleKeyPair keyPair;
}

class DeviceIdentityService {
  DeviceIdentityService._();
  static final DeviceIdentityService instance = DeviceIdentityService._();

  DeviceIdentity? _cached;
  String get currentDeviceId => _cached?.deviceId ?? '';

  Future<DeviceIdentity> getOrCreate() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_kDeviceIdKey);
    final existingPrivate = prefs.getString(_kPrivateKeyKey);
    final existingPublic = prefs.getString(_kPublicKeyKey);

    if (existingId != null && existingPrivate != null && existingPublic != null) {
      try {
        final algo = Ed25519();
        final privateBytes = base64Decode(existingPrivate);
        final publicBytes = base64Decode(existingPublic);
        final keyPair = await algo.newKeyPairFromSeed(
          privateBytes.length >= 32 ? privateBytes.sublist(0, 32) : privateBytes,
        );
        // Verify public key matches
        final pubKey = await keyPair.extractPublicKey();
        if (base64Encode(Uint8List.fromList(pubKey.bytes)) == existingPublic) {
          _cached = DeviceIdentity(
            deviceId: existingId,
            publicKeyBase64: existingPublic,
            keyPair: keyPair,
          );
          logger.info('DeviceIdentity', 'Loaded existing identity: $existingId');
          return _cached!;
        }
      } catch (e) {
        logger.warning('DeviceIdentity', 'Failed to load stored identity, regenerating: $e');
      }
    }

    // Generate new identity
    final algo = Ed25519();
    final keyPair = await algo.newKeyPair();
    final pubKey = await keyPair.extractPublicKey();
    final pubBytes = Uint8List.fromList(pubKey.bytes);
    final privateBytes = await keyPair.extractPrivateKeyBytes();

    final deviceId = const Uuid().v4();
    final publicKeyB64 = base64Encode(pubBytes);
    final privateKeyB64 = base64Encode(privateBytes);

    await prefs.setString(_kDeviceIdKey, deviceId);
    await prefs.setString(_kPublicKeyKey, publicKeyB64);
    await prefs.setString(_kPrivateKeyKey, privateKeyB64);

    _cached = DeviceIdentity(
      deviceId: deviceId,
      publicKeyBase64: publicKeyB64,
      keyPair: keyPair,
    );
    logger.info('DeviceIdentity', 'Generated new identity: $deviceId');
    return _cached!;
  }

  /// Sign a message payload for authentication.
  Future<String> sign(String data) async {
    final identity = await getOrCreate();
    final algo = Ed25519();
    final sig = await algo.sign(
      utf8.encode(data),
      keyPair: identity.keyPair,
    );
    return base64Encode(sig.bytes);
  }

  /// Verify a signature from a known peer public key.
  Future<bool> verify(String data, String signatureB64, String publicKeyB64) async {
    try {
      final algo = Ed25519();
      final pubBytes = base64Decode(publicKeyB64);
      final pubKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final sigBytes = base64Decode(signatureB64);
      final sig = Signature(sigBytes, publicKey: pubKey);
      return await algo.verify(utf8.encode(data), signature: sig);
    } catch (e) {
      logger.warning('DeviceIdentity', 'Signature verification failed: $e');
      return false;
    }
  }
}
