// lib/domain/entities/ecosystem.dart

class Ecosystem {
  const Ecosystem({
    required this.ecosystemId,
    required this.name,
    required this.ownerDeviceId,
    required this.createdAt,
    this.protocolVersion = 1,
    this.memberCount = 0,
  });

  final String ecosystemId;
  final String name;
  final String ownerDeviceId;
  final DateTime createdAt;
  final int protocolVersion;
  final int memberCount;

  Ecosystem copyWith({
    String? ecosystemId,
    String? name,
    String? ownerDeviceId,
    DateTime? createdAt,
    int? protocolVersion,
    int? memberCount,
  }) {
    return Ecosystem(
      ecosystemId: ecosystemId ?? this.ecosystemId,
      name: name ?? this.name,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      createdAt: createdAt ?? this.createdAt,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
