// lib/domain/entities/activity_entry.dart

enum ActivityType {
  clipboardSynced,
  fileSent,
  fileReceived,
  linkSent,
  linkReceived,
  deviceJoined,
  deviceLeft,
  transferFailed,
  deviceRemoved,
}

class ActivityEntry {
  const ActivityEntry({
    required this.entryId,
    required this.type,
    required this.timestamp,
    required this.description,
    this.peerDeviceName,
    this.metadata,
  });

  final String entryId;
  final ActivityType type;
  final DateTime timestamp;
  final String description;
  final String? peerDeviceName;
  final Map<String, String>? metadata;
}
