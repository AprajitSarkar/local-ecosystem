enum DevicePlatform {
  android,
  ios,
  linux,
  windows,
  unknown;

  static DevicePlatform fromString(String? raw, [String? deviceName]) {
    final lower = (raw ?? '').toLowerCase().trim();
    if (lower == 'windows' || lower == 'win' || lower == 'win32') return DevicePlatform.windows;
    if (lower == 'android') return DevicePlatform.android;
    if (lower == 'ios' || lower == 'iphone' || lower == 'ipad') return DevicePlatform.ios;
    if (lower == 'linux') return DevicePlatform.linux;
    if (lower == 'macos' || lower == 'darwin' || lower == 'mac') return DevicePlatform.linux;

    // Fallback: infer from device display name
    final nameLower = (deviceName ?? '').toLowerCase().trim();
    if (nameLower.contains('desktop-') || nameLower.contains('laptop-') || nameLower.contains('windows') || nameLower.contains('pc')) {
      return DevicePlatform.windows;
    }
    if (nameLower.contains('redmi') || nameLower.contains('samsung') || nameLower.contains('xiaomi') || nameLower.contains('pixel') || nameLower.contains('oneplus') || nameLower.contains('android') || nameLower.contains('phone')) {
      return DevicePlatform.android;
    }
    if (nameLower.contains('iphone') || nameLower.contains('ipad')) {
      return DevicePlatform.ios;
    }

    return DevicePlatform.unknown;
  }
}

enum TrustStatus { pending, trusted, rejected, removed }

class Device {
  const Device({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.publicKey,
    required this.capabilities,
    required this.addedAt,
    this.lastSeen,
    this.trustStatus = TrustStatus.pending,
    this.address,
    this.port,
    this.isOnline = false,
  });

  final String deviceId;
  final String displayName;
  final DevicePlatform platform;
  final String publicKey;
  final List<String> capabilities;
  final DateTime addedAt;
  final DateTime? lastSeen;
  final TrustStatus trustStatus;
  final String? address;
  final int? port;
  final bool isOnline;

  bool get isTrusted => trustStatus == TrustStatus.trusted;

  Device copyWith({
    String? deviceId,
    String? displayName,
    DevicePlatform? platform,
    String? publicKey,
    List<String>? capabilities,
    DateTime? addedAt,
    DateTime? lastSeen,
    TrustStatus? trustStatus,
    String? address,
    int? port,
    bool? isOnline,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      platform: platform ?? this.platform,
      publicKey: publicKey ?? this.publicKey,
      capabilities: capabilities ?? this.capabilities,
      addedAt: addedAt ?? this.addedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      trustStatus: trustStatus ?? this.trustStatus,
      address: address ?? this.address,
      port: port ?? this.port,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}
