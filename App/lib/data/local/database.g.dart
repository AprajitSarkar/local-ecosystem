// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EcosystemTableTable extends EcosystemTable
    with TableInfo<$EcosystemTableTable, EcosystemTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcosystemTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ecosystemIdMeta =
      const VerificationMeta('ecosystemId');
  @override
  late final GeneratedColumn<String> ecosystemId = GeneratedColumn<String>(
      'ecosystem_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerDeviceIdMeta =
      const VerificationMeta('ownerDeviceId');
  @override
  late final GeneratedColumn<String> ownerDeviceId = GeneratedColumn<String>(
      'owner_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _protocolVersionMeta =
      const VerificationMeta('protocolVersion');
  @override
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
      'protocol_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [ecosystemId, name, ownerDeviceId, protocolVersion, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecosystems';
  @override
  VerificationContext validateIntegrity(Insertable<EcosystemTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ecosystem_id')) {
      context.handle(
          _ecosystemIdMeta,
          ecosystemId.isAcceptableOrUnknown(
              data['ecosystem_id']!, _ecosystemIdMeta));
    } else if (isInserting) {
      context.missing(_ecosystemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_device_id')) {
      context.handle(
          _ownerDeviceIdMeta,
          ownerDeviceId.isAcceptableOrUnknown(
              data['owner_device_id']!, _ownerDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_ownerDeviceIdMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
          _protocolVersionMeta,
          protocolVersion.isAcceptableOrUnknown(
              data['protocol_version']!, _protocolVersionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ecosystemId};
  @override
  EcosystemTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcosystemTableData(
      ecosystemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ecosystem_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ownerDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}owner_device_id'])!,
      protocolVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protocol_version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EcosystemTableTable createAlias(String alias) {
    return $EcosystemTableTable(attachedDatabase, alias);
  }
}

class EcosystemTableData extends DataClass
    implements Insertable<EcosystemTableData> {
  final String ecosystemId;
  final String name;
  final String ownerDeviceId;
  final int protocolVersion;
  final DateTime createdAt;
  const EcosystemTableData(
      {required this.ecosystemId,
      required this.name,
      required this.ownerDeviceId,
      required this.protocolVersion,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ecosystem_id'] = Variable<String>(ecosystemId);
    map['name'] = Variable<String>(name);
    map['owner_device_id'] = Variable<String>(ownerDeviceId);
    map['protocol_version'] = Variable<int>(protocolVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EcosystemTableCompanion toCompanion(bool nullToAbsent) {
    return EcosystemTableCompanion(
      ecosystemId: Value(ecosystemId),
      name: Value(name),
      ownerDeviceId: Value(ownerDeviceId),
      protocolVersion: Value(protocolVersion),
      createdAt: Value(createdAt),
    );
  }

  factory EcosystemTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcosystemTableData(
      ecosystemId: serializer.fromJson<String>(json['ecosystemId']),
      name: serializer.fromJson<String>(json['name']),
      ownerDeviceId: serializer.fromJson<String>(json['ownerDeviceId']),
      protocolVersion: serializer.fromJson<int>(json['protocolVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ecosystemId': serializer.toJson<String>(ecosystemId),
      'name': serializer.toJson<String>(name),
      'ownerDeviceId': serializer.toJson<String>(ownerDeviceId),
      'protocolVersion': serializer.toJson<int>(protocolVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EcosystemTableData copyWith(
          {String? ecosystemId,
          String? name,
          String? ownerDeviceId,
          int? protocolVersion,
          DateTime? createdAt}) =>
      EcosystemTableData(
        ecosystemId: ecosystemId ?? this.ecosystemId,
        name: name ?? this.name,
        ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
        protocolVersion: protocolVersion ?? this.protocolVersion,
        createdAt: createdAt ?? this.createdAt,
      );
  EcosystemTableData copyWithCompanion(EcosystemTableCompanion data) {
    return EcosystemTableData(
      ecosystemId:
          data.ecosystemId.present ? data.ecosystemId.value : this.ecosystemId,
      name: data.name.present ? data.name.value : this.name,
      ownerDeviceId: data.ownerDeviceId.present
          ? data.ownerDeviceId.value
          : this.ownerDeviceId,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcosystemTableData(')
          ..write('ecosystemId: $ecosystemId, ')
          ..write('name: $name, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ecosystemId, name, ownerDeviceId, protocolVersion, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcosystemTableData &&
          other.ecosystemId == this.ecosystemId &&
          other.name == this.name &&
          other.ownerDeviceId == this.ownerDeviceId &&
          other.protocolVersion == this.protocolVersion &&
          other.createdAt == this.createdAt);
}

class EcosystemTableCompanion extends UpdateCompanion<EcosystemTableData> {
  final Value<String> ecosystemId;
  final Value<String> name;
  final Value<String> ownerDeviceId;
  final Value<int> protocolVersion;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EcosystemTableCompanion({
    this.ecosystemId = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerDeviceId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EcosystemTableCompanion.insert({
    required String ecosystemId,
    required String name,
    required String ownerDeviceId,
    this.protocolVersion = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : ecosystemId = Value(ecosystemId),
        name = Value(name),
        ownerDeviceId = Value(ownerDeviceId),
        createdAt = Value(createdAt);
  static Insertable<EcosystemTableData> custom({
    Expression<String>? ecosystemId,
    Expression<String>? name,
    Expression<String>? ownerDeviceId,
    Expression<int>? protocolVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ecosystemId != null) 'ecosystem_id': ecosystemId,
      if (name != null) 'name': name,
      if (ownerDeviceId != null) 'owner_device_id': ownerDeviceId,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EcosystemTableCompanion copyWith(
      {Value<String>? ecosystemId,
      Value<String>? name,
      Value<String>? ownerDeviceId,
      Value<int>? protocolVersion,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return EcosystemTableCompanion(
      ecosystemId: ecosystemId ?? this.ecosystemId,
      name: name ?? this.name,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ecosystemId.present) {
      map['ecosystem_id'] = Variable<String>(ecosystemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerDeviceId.present) {
      map['owner_device_id'] = Variable<String>(ownerDeviceId.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcosystemTableCompanion(')
          ..write('ecosystemId: $ecosystemId, ')
          ..write('name: $name, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceTableTable extends DeviceTable
    with TableInfo<$DeviceTableTable, DeviceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _capabilitiesMeta =
      const VerificationMeta('capabilities');
  @override
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
      'capabilities', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _trustStatusMeta =
      const VerificationMeta('trustStatus');
  @override
  late final GeneratedColumn<String> trustStatus = GeneratedColumn<String>(
      'trust_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        deviceId,
        displayName,
        platform,
        publicKey,
        capabilities,
        trustStatus,
        addedAt,
        lastSeen
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('capabilities')) {
      context.handle(
          _capabilitiesMeta,
          capabilities.isAcceptableOrUnknown(
              data['capabilities']!, _capabilitiesMeta));
    }
    if (data.containsKey('trust_status')) {
      context.handle(
          _trustStatusMeta,
          trustStatus.isAcceptableOrUnknown(
              data['trust_status']!, _trustStatusMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  DeviceTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceTableData(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key'])!,
      capabilities: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}capabilities'])!,
      trustStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trust_status'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen']),
    );
  }

  @override
  $DeviceTableTable createAlias(String alias) {
    return $DeviceTableTable(attachedDatabase, alias);
  }
}

class DeviceTableData extends DataClass implements Insertable<DeviceTableData> {
  final String deviceId;
  final String displayName;
  final String platform;
  final String publicKey;
  final String capabilities;
  final String trustStatus;
  final DateTime addedAt;
  final DateTime? lastSeen;
  const DeviceTableData(
      {required this.deviceId,
      required this.displayName,
      required this.platform,
      required this.publicKey,
      required this.capabilities,
      required this.trustStatus,
      required this.addedAt,
      this.lastSeen});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['platform'] = Variable<String>(platform);
    map['public_key'] = Variable<String>(publicKey);
    map['capabilities'] = Variable<String>(capabilities);
    map['trust_status'] = Variable<String>(trustStatus);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastSeen != null) {
      map['last_seen'] = Variable<DateTime>(lastSeen);
    }
    return map;
  }

  DeviceTableCompanion toCompanion(bool nullToAbsent) {
    return DeviceTableCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      platform: Value(platform),
      publicKey: Value(publicKey),
      capabilities: Value(capabilities),
      trustStatus: Value(trustStatus),
      addedAt: Value(addedAt),
      lastSeen: lastSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeen),
    );
  }

  factory DeviceTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceTableData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      platform: serializer.fromJson<String>(json['platform']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      capabilities: serializer.fromJson<String>(json['capabilities']),
      trustStatus: serializer.fromJson<String>(json['trustStatus']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastSeen: serializer.fromJson<DateTime?>(json['lastSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'platform': serializer.toJson<String>(platform),
      'publicKey': serializer.toJson<String>(publicKey),
      'capabilities': serializer.toJson<String>(capabilities),
      'trustStatus': serializer.toJson<String>(trustStatus),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastSeen': serializer.toJson<DateTime?>(lastSeen),
    };
  }

  DeviceTableData copyWith(
          {String? deviceId,
          String? displayName,
          String? platform,
          String? publicKey,
          String? capabilities,
          String? trustStatus,
          DateTime? addedAt,
          Value<DateTime?> lastSeen = const Value.absent()}) =>
      DeviceTableData(
        deviceId: deviceId ?? this.deviceId,
        displayName: displayName ?? this.displayName,
        platform: platform ?? this.platform,
        publicKey: publicKey ?? this.publicKey,
        capabilities: capabilities ?? this.capabilities,
        trustStatus: trustStatus ?? this.trustStatus,
        addedAt: addedAt ?? this.addedAt,
        lastSeen: lastSeen.present ? lastSeen.value : this.lastSeen,
      );
  DeviceTableData copyWithCompanion(DeviceTableCompanion data) {
    return DeviceTableData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      platform: data.platform.present ? data.platform.value : this.platform,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      capabilities: data.capabilities.present
          ? data.capabilities.value
          : this.capabilities,
      trustStatus:
          data.trustStatus.present ? data.trustStatus.value : this.trustStatus,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTableData(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('platform: $platform, ')
          ..write('publicKey: $publicKey, ')
          ..write('capabilities: $capabilities, ')
          ..write('trustStatus: $trustStatus, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, displayName, platform, publicKey,
      capabilities, trustStatus, addedAt, lastSeen);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceTableData &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.platform == this.platform &&
          other.publicKey == this.publicKey &&
          other.capabilities == this.capabilities &&
          other.trustStatus == this.trustStatus &&
          other.addedAt == this.addedAt &&
          other.lastSeen == this.lastSeen);
}

class DeviceTableCompanion extends UpdateCompanion<DeviceTableData> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String> platform;
  final Value<String> publicKey;
  final Value<String> capabilities;
  final Value<String> trustStatus;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastSeen;
  final Value<int> rowid;
  const DeviceTableCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.platform = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.trustStatus = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceTableCompanion.insert({
    required String deviceId,
    required String displayName,
    required String platform,
    required String publicKey,
    this.capabilities = const Value.absent(),
    this.trustStatus = const Value.absent(),
    required DateTime addedAt,
    this.lastSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        displayName = Value(displayName),
        platform = Value(platform),
        publicKey = Value(publicKey),
        addedAt = Value(addedAt);
  static Insertable<DeviceTableData> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? platform,
    Expression<String>? publicKey,
    Expression<String>? capabilities,
    Expression<String>? trustStatus,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (platform != null) 'platform': platform,
      if (publicKey != null) 'public_key': publicKey,
      if (capabilities != null) 'capabilities': capabilities,
      if (trustStatus != null) 'trust_status': trustStatus,
      if (addedAt != null) 'added_at': addedAt,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceTableCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? displayName,
      Value<String>? platform,
      Value<String>? publicKey,
      Value<String>? capabilities,
      Value<String>? trustStatus,
      Value<DateTime>? addedAt,
      Value<DateTime?>? lastSeen,
      Value<int>? rowid}) {
    return DeviceTableCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      platform: platform ?? this.platform,
      publicKey: publicKey ?? this.publicKey,
      capabilities: capabilities ?? this.capabilities,
      trustStatus: trustStatus ?? this.trustStatus,
      addedAt: addedAt ?? this.addedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (trustStatus.present) {
      map['trust_status'] = Variable<String>(trustStatus.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTableCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('platform: $platform, ')
          ..write('publicKey: $publicKey, ')
          ..write('capabilities: $capabilities, ')
          ..write('trustStatus: $trustStatus, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferTableTable extends TransferTable
    with TableInfo<$TransferTableTable, TransferTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerDeviceIdMeta =
      const VerificationMeta('peerDeviceId');
  @override
  late final GeneratedColumn<String> peerDeviceId = GeneratedColumn<String>(
      'peer_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerDeviceNameMeta =
      const VerificationMeta('peerDeviceName');
  @override
  late final GeneratedColumn<String> peerDeviceName = GeneratedColumn<String>(
      'peer_device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        transferId,
        filename,
        mimeType,
        totalBytes,
        direction,
        peerDeviceId,
        peerDeviceName,
        state,
        startedAt,
        completedAt,
        localPath,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(Insertable<TransferTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('peer_device_id')) {
      context.handle(
          _peerDeviceIdMeta,
          peerDeviceId.isAcceptableOrUnknown(
              data['peer_device_id']!, _peerDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_peerDeviceIdMeta);
    }
    if (data.containsKey('peer_device_name')) {
      context.handle(
          _peerDeviceNameMeta,
          peerDeviceName.isAcceptableOrUnknown(
              data['peer_device_name']!, _peerDeviceNameMeta));
    } else if (isInserting) {
      context.missing(_peerDeviceNameMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transferId};
  @override
  TransferTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferTableData(
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_id'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      peerDeviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_device_id'])!,
      peerDeviceName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}peer_device_name'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $TransferTableTable createAlias(String alias) {
    return $TransferTableTable(attachedDatabase, alias);
  }
}

class TransferTableData extends DataClass
    implements Insertable<TransferTableData> {
  final String transferId;
  final String filename;
  final String mimeType;
  final int totalBytes;
  final String direction;
  final String peerDeviceId;
  final String peerDeviceName;
  final String state;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? localPath;
  final String? errorMessage;
  const TransferTableData(
      {required this.transferId,
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
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transfer_id'] = Variable<String>(transferId);
    map['filename'] = Variable<String>(filename);
    map['mime_type'] = Variable<String>(mimeType);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['direction'] = Variable<String>(direction);
    map['peer_device_id'] = Variable<String>(peerDeviceId);
    map['peer_device_name'] = Variable<String>(peerDeviceName);
    map['state'] = Variable<String>(state);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  TransferTableCompanion toCompanion(bool nullToAbsent) {
    return TransferTableCompanion(
      transferId: Value(transferId),
      filename: Value(filename),
      mimeType: Value(mimeType),
      totalBytes: Value(totalBytes),
      direction: Value(direction),
      peerDeviceId: Value(peerDeviceId),
      peerDeviceName: Value(peerDeviceName),
      state: Value(state),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory TransferTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferTableData(
      transferId: serializer.fromJson<String>(json['transferId']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      direction: serializer.fromJson<String>(json['direction']),
      peerDeviceId: serializer.fromJson<String>(json['peerDeviceId']),
      peerDeviceName: serializer.fromJson<String>(json['peerDeviceName']),
      state: serializer.fromJson<String>(json['state']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transferId': serializer.toJson<String>(transferId),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String>(mimeType),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'direction': serializer.toJson<String>(direction),
      'peerDeviceId': serializer.toJson<String>(peerDeviceId),
      'peerDeviceName': serializer.toJson<String>(peerDeviceName),
      'state': serializer.toJson<String>(state),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'localPath': serializer.toJson<String?>(localPath),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  TransferTableData copyWith(
          {String? transferId,
          String? filename,
          String? mimeType,
          int? totalBytes,
          String? direction,
          String? peerDeviceId,
          String? peerDeviceName,
          String? state,
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> localPath = const Value.absent(),
          Value<String?> errorMessage = const Value.absent()}) =>
      TransferTableData(
        transferId: transferId ?? this.transferId,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
        totalBytes: totalBytes ?? this.totalBytes,
        direction: direction ?? this.direction,
        peerDeviceId: peerDeviceId ?? this.peerDeviceId,
        peerDeviceName: peerDeviceName ?? this.peerDeviceName,
        state: state ?? this.state,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        localPath: localPath.present ? localPath.value : this.localPath,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  TransferTableData copyWithCompanion(TransferTableCompanion data) {
    return TransferTableData(
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      direction: data.direction.present ? data.direction.value : this.direction,
      peerDeviceId: data.peerDeviceId.present
          ? data.peerDeviceId.value
          : this.peerDeviceId,
      peerDeviceName: data.peerDeviceName.present
          ? data.peerDeviceName.value
          : this.peerDeviceName,
      state: data.state.present ? data.state.value : this.state,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferTableData(')
          ..write('transferId: $transferId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('direction: $direction, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('localPath: $localPath, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      transferId,
      filename,
      mimeType,
      totalBytes,
      direction,
      peerDeviceId,
      peerDeviceName,
      state,
      startedAt,
      completedAt,
      localPath,
      errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferTableData &&
          other.transferId == this.transferId &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          other.totalBytes == this.totalBytes &&
          other.direction == this.direction &&
          other.peerDeviceId == this.peerDeviceId &&
          other.peerDeviceName == this.peerDeviceName &&
          other.state == this.state &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.localPath == this.localPath &&
          other.errorMessage == this.errorMessage);
}

class TransferTableCompanion extends UpdateCompanion<TransferTableData> {
  final Value<String> transferId;
  final Value<String> filename;
  final Value<String> mimeType;
  final Value<int> totalBytes;
  final Value<String> direction;
  final Value<String> peerDeviceId;
  final Value<String> peerDeviceName;
  final Value<String> state;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> localPath;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const TransferTableCompanion({
    this.transferId = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.direction = const Value.absent(),
    this.peerDeviceId = const Value.absent(),
    this.peerDeviceName = const Value.absent(),
    this.state = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.localPath = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferTableCompanion.insert({
    required String transferId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required String direction,
    required String peerDeviceId,
    required String peerDeviceName,
    required String state,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.localPath = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : transferId = Value(transferId),
        filename = Value(filename),
        mimeType = Value(mimeType),
        totalBytes = Value(totalBytes),
        direction = Value(direction),
        peerDeviceId = Value(peerDeviceId),
        peerDeviceName = Value(peerDeviceName),
        state = Value(state),
        startedAt = Value(startedAt);
  static Insertable<TransferTableData> custom({
    Expression<String>? transferId,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<int>? totalBytes,
    Expression<String>? direction,
    Expression<String>? peerDeviceId,
    Expression<String>? peerDeviceName,
    Expression<String>? state,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? localPath,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transferId != null) 'transfer_id': transferId,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (direction != null) 'direction': direction,
      if (peerDeviceId != null) 'peer_device_id': peerDeviceId,
      if (peerDeviceName != null) 'peer_device_name': peerDeviceName,
      if (state != null) 'state': state,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (localPath != null) 'local_path': localPath,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferTableCompanion copyWith(
      {Value<String>? transferId,
      Value<String>? filename,
      Value<String>? mimeType,
      Value<int>? totalBytes,
      Value<String>? direction,
      Value<String>? peerDeviceId,
      Value<String>? peerDeviceName,
      Value<String>? state,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt,
      Value<String?>? localPath,
      Value<String?>? errorMessage,
      Value<int>? rowid}) {
    return TransferTableCompanion(
      transferId: transferId ?? this.transferId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      totalBytes: totalBytes ?? this.totalBytes,
      direction: direction ?? this.direction,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      localPath: localPath ?? this.localPath,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (peerDeviceId.present) {
      map['peer_device_id'] = Variable<String>(peerDeviceId.value);
    }
    if (peerDeviceName.present) {
      map['peer_device_name'] = Variable<String>(peerDeviceName.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferTableCompanion(')
          ..write('transferId: $transferId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('direction: $direction, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('localPath: $localPath, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClipboardEventTableTable extends ClipboardEventTable
    with TableInfo<$ClipboardEventTableTable, ClipboardEventTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipboardEventTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceDeviceIdMeta =
      const VerificationMeta('sourceDeviceId');
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
      'source_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceDeviceNameMeta =
      const VerificationMeta('sourceDeviceName');
  @override
  late final GeneratedColumn<String> sourceDeviceName = GeneratedColumn<String>(
      'source_device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textPreviewMeta =
      const VerificationMeta('textPreview');
  @override
  late final GeneratedColumn<String> textPreview = GeneratedColumn<String>(
      'text_preview', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadHashMeta =
      const VerificationMeta('payloadHash');
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
      'payload_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isLocalMeta =
      const VerificationMeta('isLocal');
  @override
  late final GeneratedColumn<bool> isLocal = GeneratedColumn<bool>(
      'is_local', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_local" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        eventId,
        sourceDeviceId,
        sourceDeviceName,
        textPreview,
        payloadHash,
        timestamp,
        isLocal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clipboard_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<ClipboardEventTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
          _sourceDeviceIdMeta,
          sourceDeviceId.isAcceptableOrUnknown(
              data['source_device_id']!, _sourceDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    if (data.containsKey('source_device_name')) {
      context.handle(
          _sourceDeviceNameMeta,
          sourceDeviceName.isAcceptableOrUnknown(
              data['source_device_name']!, _sourceDeviceNameMeta));
    } else if (isInserting) {
      context.missing(_sourceDeviceNameMeta);
    }
    if (data.containsKey('text_preview')) {
      context.handle(
          _textPreviewMeta,
          textPreview.isAcceptableOrUnknown(
              data['text_preview']!, _textPreviewMeta));
    } else if (isInserting) {
      context.missing(_textPreviewMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
          _payloadHashMeta,
          payloadHash.isAcceptableOrUnknown(
              data['payload_hash']!, _payloadHashMeta));
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(_isLocalMeta,
          isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  ClipboardEventTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClipboardEventTableData(
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_device_id'])!,
      sourceDeviceName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_device_name'])!,
      textPreview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_preview'])!,
      payloadHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_hash'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isLocal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_local'])!,
    );
  }

  @override
  $ClipboardEventTableTable createAlias(String alias) {
    return $ClipboardEventTableTable(attachedDatabase, alias);
  }
}

class ClipboardEventTableData extends DataClass
    implements Insertable<ClipboardEventTableData> {
  final String eventId;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final String textPreview;
  final String payloadHash;
  final DateTime timestamp;
  final bool isLocal;
  const ClipboardEventTableData(
      {required this.eventId,
      required this.sourceDeviceId,
      required this.sourceDeviceName,
      required this.textPreview,
      required this.payloadHash,
      required this.timestamp,
      required this.isLocal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    map['source_device_name'] = Variable<String>(sourceDeviceName);
    map['text_preview'] = Variable<String>(textPreview);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_local'] = Variable<bool>(isLocal);
    return map;
  }

  ClipboardEventTableCompanion toCompanion(bool nullToAbsent) {
    return ClipboardEventTableCompanion(
      eventId: Value(eventId),
      sourceDeviceId: Value(sourceDeviceId),
      sourceDeviceName: Value(sourceDeviceName),
      textPreview: Value(textPreview),
      payloadHash: Value(payloadHash),
      timestamp: Value(timestamp),
      isLocal: Value(isLocal),
    );
  }

  factory ClipboardEventTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClipboardEventTableData(
      eventId: serializer.fromJson<String>(json['eventId']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
      sourceDeviceName: serializer.fromJson<String>(json['sourceDeviceName']),
      textPreview: serializer.fromJson<String>(json['textPreview']),
      payloadHash: serializer.fromJson<String>(json['payloadHash']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
      'sourceDeviceName': serializer.toJson<String>(sourceDeviceName),
      'textPreview': serializer.toJson<String>(textPreview),
      'payloadHash': serializer.toJson<String>(payloadHash),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isLocal': serializer.toJson<bool>(isLocal),
    };
  }

  ClipboardEventTableData copyWith(
          {String? eventId,
          String? sourceDeviceId,
          String? sourceDeviceName,
          String? textPreview,
          String? payloadHash,
          DateTime? timestamp,
          bool? isLocal}) =>
      ClipboardEventTableData(
        eventId: eventId ?? this.eventId,
        sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
        sourceDeviceName: sourceDeviceName ?? this.sourceDeviceName,
        textPreview: textPreview ?? this.textPreview,
        payloadHash: payloadHash ?? this.payloadHash,
        timestamp: timestamp ?? this.timestamp,
        isLocal: isLocal ?? this.isLocal,
      );
  ClipboardEventTableData copyWithCompanion(ClipboardEventTableCompanion data) {
    return ClipboardEventTableData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      sourceDeviceName: data.sourceDeviceName.present
          ? data.sourceDeviceName.value
          : this.sourceDeviceName,
      textPreview:
          data.textPreview.present ? data.textPreview.value : this.textPreview,
      payloadHash:
          data.payloadHash.present ? data.payloadHash.value : this.payloadHash,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClipboardEventTableData(')
          ..write('eventId: $eventId, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('sourceDeviceName: $sourceDeviceName, ')
          ..write('textPreview: $textPreview, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('timestamp: $timestamp, ')
          ..write('isLocal: $isLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, sourceDeviceId, sourceDeviceName,
      textPreview, payloadHash, timestamp, isLocal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClipboardEventTableData &&
          other.eventId == this.eventId &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.sourceDeviceName == this.sourceDeviceName &&
          other.textPreview == this.textPreview &&
          other.payloadHash == this.payloadHash &&
          other.timestamp == this.timestamp &&
          other.isLocal == this.isLocal);
}

class ClipboardEventTableCompanion
    extends UpdateCompanion<ClipboardEventTableData> {
  final Value<String> eventId;
  final Value<String> sourceDeviceId;
  final Value<String> sourceDeviceName;
  final Value<String> textPreview;
  final Value<String> payloadHash;
  final Value<DateTime> timestamp;
  final Value<bool> isLocal;
  final Value<int> rowid;
  const ClipboardEventTableCompanion({
    this.eventId = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.sourceDeviceName = const Value.absent(),
    this.textPreview = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClipboardEventTableCompanion.insert({
    required String eventId,
    required String sourceDeviceId,
    required String sourceDeviceName,
    required String textPreview,
    required String payloadHash,
    required DateTime timestamp,
    this.isLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : eventId = Value(eventId),
        sourceDeviceId = Value(sourceDeviceId),
        sourceDeviceName = Value(sourceDeviceName),
        textPreview = Value(textPreview),
        payloadHash = Value(payloadHash),
        timestamp = Value(timestamp);
  static Insertable<ClipboardEventTableData> custom({
    Expression<String>? eventId,
    Expression<String>? sourceDeviceId,
    Expression<String>? sourceDeviceName,
    Expression<String>? textPreview,
    Expression<String>? payloadHash,
    Expression<DateTime>? timestamp,
    Expression<bool>? isLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (sourceDeviceName != null) 'source_device_name': sourceDeviceName,
      if (textPreview != null) 'text_preview': textPreview,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (timestamp != null) 'timestamp': timestamp,
      if (isLocal != null) 'is_local': isLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClipboardEventTableCompanion copyWith(
      {Value<String>? eventId,
      Value<String>? sourceDeviceId,
      Value<String>? sourceDeviceName,
      Value<String>? textPreview,
      Value<String>? payloadHash,
      Value<DateTime>? timestamp,
      Value<bool>? isLocal,
      Value<int>? rowid}) {
    return ClipboardEventTableCompanion(
      eventId: eventId ?? this.eventId,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceDeviceName: sourceDeviceName ?? this.sourceDeviceName,
      textPreview: textPreview ?? this.textPreview,
      payloadHash: payloadHash ?? this.payloadHash,
      timestamp: timestamp ?? this.timestamp,
      isLocal: isLocal ?? this.isLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (sourceDeviceName.present) {
      map['source_device_name'] = Variable<String>(sourceDeviceName.value);
    }
    if (textPreview.present) {
      map['text_preview'] = Variable<String>(textPreview.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipboardEventTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('sourceDeviceName: $sourceDeviceName, ')
          ..write('textPreview: $textPreview, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('timestamp: $timestamp, ')
          ..write('isLocal: $isLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityTableTable extends ActivityTable
    with TableInfo<$ActivityTableTable, ActivityTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerDeviceNameMeta =
      const VerificationMeta('peerDeviceName');
  @override
  late final GeneratedColumn<String> peerDeviceName = GeneratedColumn<String>(
      'peer_device_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [entryId, type, timestamp, description, peerDeviceName, metadata];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('peer_device_name')) {
      context.handle(
          _peerDeviceNameMeta,
          peerDeviceName.isAcceptableOrUnknown(
              data['peer_device_name']!, _peerDeviceNameMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  ActivityTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityTableData(
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      peerDeviceName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}peer_device_name']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $ActivityTableTable createAlias(String alias) {
    return $ActivityTableTable(attachedDatabase, alias);
  }
}

class ActivityTableData extends DataClass
    implements Insertable<ActivityTableData> {
  final String entryId;
  final String type;
  final DateTime timestamp;
  final String description;
  final String? peerDeviceName;
  final String? metadata;
  const ActivityTableData(
      {required this.entryId,
      required this.type,
      required this.timestamp,
      required this.description,
      this.peerDeviceName,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['type'] = Variable<String>(type);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || peerDeviceName != null) {
      map['peer_device_name'] = Variable<String>(peerDeviceName);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  ActivityTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityTableCompanion(
      entryId: Value(entryId),
      type: Value(type),
      timestamp: Value(timestamp),
      description: Value(description),
      peerDeviceName: peerDeviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(peerDeviceName),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory ActivityTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityTableData(
      entryId: serializer.fromJson<String>(json['entryId']),
      type: serializer.fromJson<String>(json['type']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      description: serializer.fromJson<String>(json['description']),
      peerDeviceName: serializer.fromJson<String?>(json['peerDeviceName']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'type': serializer.toJson<String>(type),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'description': serializer.toJson<String>(description),
      'peerDeviceName': serializer.toJson<String?>(peerDeviceName),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  ActivityTableData copyWith(
          {String? entryId,
          String? type,
          DateTime? timestamp,
          String? description,
          Value<String?> peerDeviceName = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      ActivityTableData(
        entryId: entryId ?? this.entryId,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        description: description ?? this.description,
        peerDeviceName:
            peerDeviceName.present ? peerDeviceName.value : this.peerDeviceName,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  ActivityTableData copyWithCompanion(ActivityTableCompanion data) {
    return ActivityTableData(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      description:
          data.description.present ? data.description.value : this.description,
      peerDeviceName: data.peerDeviceName.present
          ? data.peerDeviceName.value
          : this.peerDeviceName,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityTableData(')
          ..write('entryId: $entryId, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('description: $description, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entryId, type, timestamp, description, peerDeviceName, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityTableData &&
          other.entryId == this.entryId &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.description == this.description &&
          other.peerDeviceName == this.peerDeviceName &&
          other.metadata == this.metadata);
}

class ActivityTableCompanion extends UpdateCompanion<ActivityTableData> {
  final Value<String> entryId;
  final Value<String> type;
  final Value<DateTime> timestamp;
  final Value<String> description;
  final Value<String?> peerDeviceName;
  final Value<String?> metadata;
  final Value<int> rowid;
  const ActivityTableCompanion({
    this.entryId = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.description = const Value.absent(),
    this.peerDeviceName = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityTableCompanion.insert({
    required String entryId,
    required String type,
    required DateTime timestamp,
    required String description,
    this.peerDeviceName = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entryId = Value(entryId),
        type = Value(type),
        timestamp = Value(timestamp),
        description = Value(description);
  static Insertable<ActivityTableData> custom({
    Expression<String>? entryId,
    Expression<String>? type,
    Expression<DateTime>? timestamp,
    Expression<String>? description,
    Expression<String>? peerDeviceName,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (description != null) 'description': description,
      if (peerDeviceName != null) 'peer_device_name': peerDeviceName,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityTableCompanion copyWith(
      {Value<String>? entryId,
      Value<String>? type,
      Value<DateTime>? timestamp,
      Value<String>? description,
      Value<String?>? peerDeviceName,
      Value<String?>? metadata,
      Value<int>? rowid}) {
    return ActivityTableCompanion(
      entryId: entryId ?? this.entryId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (peerDeviceName.present) {
      map['peer_device_name'] = Variable<String>(peerDeviceName.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityTableCompanion(')
          ..write('entryId: $entryId, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('description: $description, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsTableData copyWith({String? key, String? value}) => SettingsTableData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EcosystemTableTable ecosystemTable = $EcosystemTableTable(this);
  late final $DeviceTableTable deviceTable = $DeviceTableTable(this);
  late final $TransferTableTable transferTable = $TransferTableTable(this);
  late final $ClipboardEventTableTable clipboardEventTable =
      $ClipboardEventTableTable(this);
  late final $ActivityTableTable activityTable = $ActivityTableTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        ecosystemTable,
        deviceTable,
        transferTable,
        clipboardEventTable,
        activityTable,
        settingsTable
      ];
}

typedef $$EcosystemTableTableCreateCompanionBuilder = EcosystemTableCompanion
    Function({
  required String ecosystemId,
  required String name,
  required String ownerDeviceId,
  Value<int> protocolVersion,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$EcosystemTableTableUpdateCompanionBuilder = EcosystemTableCompanion
    Function({
  Value<String> ecosystemId,
  Value<String> name,
  Value<String> ownerDeviceId,
  Value<int> protocolVersion,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EcosystemTableTableFilterComposer
    extends Composer<_$AppDatabase, $EcosystemTableTable> {
  $$EcosystemTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ecosystemId => $composableBuilder(
      column: $table.ecosystemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerDeviceId => $composableBuilder(
      column: $table.ownerDeviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get protocolVersion => $composableBuilder(
      column: $table.protocolVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EcosystemTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EcosystemTableTable> {
  $$EcosystemTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ecosystemId => $composableBuilder(
      column: $table.ecosystemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerDeviceId => $composableBuilder(
      column: $table.ownerDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get protocolVersion => $composableBuilder(
      column: $table.protocolVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EcosystemTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcosystemTableTable> {
  $$EcosystemTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ecosystemId => $composableBuilder(
      column: $table.ecosystemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerDeviceId => $composableBuilder(
      column: $table.ownerDeviceId, builder: (column) => column);

  GeneratedColumn<int> get protocolVersion => $composableBuilder(
      column: $table.protocolVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EcosystemTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EcosystemTableTable,
    EcosystemTableData,
    $$EcosystemTableTableFilterComposer,
    $$EcosystemTableTableOrderingComposer,
    $$EcosystemTableTableAnnotationComposer,
    $$EcosystemTableTableCreateCompanionBuilder,
    $$EcosystemTableTableUpdateCompanionBuilder,
    (
      EcosystemTableData,
      BaseReferences<_$AppDatabase, $EcosystemTableTable, EcosystemTableData>
    ),
    EcosystemTableData,
    PrefetchHooks Function()> {
  $$EcosystemTableTableTableManager(
      _$AppDatabase db, $EcosystemTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcosystemTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcosystemTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcosystemTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ecosystemId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> ownerDeviceId = const Value.absent(),
            Value<int> protocolVersion = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EcosystemTableCompanion(
            ecosystemId: ecosystemId,
            name: name,
            ownerDeviceId: ownerDeviceId,
            protocolVersion: protocolVersion,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ecosystemId,
            required String name,
            required String ownerDeviceId,
            Value<int> protocolVersion = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EcosystemTableCompanion.insert(
            ecosystemId: ecosystemId,
            name: name,
            ownerDeviceId: ownerDeviceId,
            protocolVersion: protocolVersion,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EcosystemTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EcosystemTableTable,
    EcosystemTableData,
    $$EcosystemTableTableFilterComposer,
    $$EcosystemTableTableOrderingComposer,
    $$EcosystemTableTableAnnotationComposer,
    $$EcosystemTableTableCreateCompanionBuilder,
    $$EcosystemTableTableUpdateCompanionBuilder,
    (
      EcosystemTableData,
      BaseReferences<_$AppDatabase, $EcosystemTableTable, EcosystemTableData>
    ),
    EcosystemTableData,
    PrefetchHooks Function()>;
typedef $$DeviceTableTableCreateCompanionBuilder = DeviceTableCompanion
    Function({
  required String deviceId,
  required String displayName,
  required String platform,
  required String publicKey,
  Value<String> capabilities,
  Value<String> trustStatus,
  required DateTime addedAt,
  Value<DateTime?> lastSeen,
  Value<int> rowid,
});
typedef $$DeviceTableTableUpdateCompanionBuilder = DeviceTableCompanion
    Function({
  Value<String> deviceId,
  Value<String> displayName,
  Value<String> platform,
  Value<String> publicKey,
  Value<String> capabilities,
  Value<String> trustStatus,
  Value<DateTime> addedAt,
  Value<DateTime?> lastSeen,
  Value<int> rowid,
});

class $$DeviceTableTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceTableTable> {
  $$DeviceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get capabilities => $composableBuilder(
      column: $table.capabilities, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trustStatus => $composableBuilder(
      column: $table.trustStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));
}

class $$DeviceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceTableTable> {
  $$DeviceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get capabilities => $composableBuilder(
      column: $table.capabilities,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trustStatus => $composableBuilder(
      column: $table.trustStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));
}

class $$DeviceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceTableTable> {
  $$DeviceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get capabilities => $composableBuilder(
      column: $table.capabilities, builder: (column) => column);

  GeneratedColumn<String> get trustStatus => $composableBuilder(
      column: $table.trustStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);
}

class $$DeviceTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeviceTableTable,
    DeviceTableData,
    $$DeviceTableTableFilterComposer,
    $$DeviceTableTableOrderingComposer,
    $$DeviceTableTableAnnotationComposer,
    $$DeviceTableTableCreateCompanionBuilder,
    $$DeviceTableTableUpdateCompanionBuilder,
    (
      DeviceTableData,
      BaseReferences<_$AppDatabase, $DeviceTableTable, DeviceTableData>
    ),
    DeviceTableData,
    PrefetchHooks Function()> {
  $$DeviceTableTableTableManager(_$AppDatabase db, $DeviceTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> publicKey = const Value.absent(),
            Value<String> capabilities = const Value.absent(),
            Value<String> trustStatus = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<DateTime?> lastSeen = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceTableCompanion(
            deviceId: deviceId,
            displayName: displayName,
            platform: platform,
            publicKey: publicKey,
            capabilities: capabilities,
            trustStatus: trustStatus,
            addedAt: addedAt,
            lastSeen: lastSeen,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String displayName,
            required String platform,
            required String publicKey,
            Value<String> capabilities = const Value.absent(),
            Value<String> trustStatus = const Value.absent(),
            required DateTime addedAt,
            Value<DateTime?> lastSeen = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceTableCompanion.insert(
            deviceId: deviceId,
            displayName: displayName,
            platform: platform,
            publicKey: publicKey,
            capabilities: capabilities,
            trustStatus: trustStatus,
            addedAt: addedAt,
            lastSeen: lastSeen,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeviceTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeviceTableTable,
    DeviceTableData,
    $$DeviceTableTableFilterComposer,
    $$DeviceTableTableOrderingComposer,
    $$DeviceTableTableAnnotationComposer,
    $$DeviceTableTableCreateCompanionBuilder,
    $$DeviceTableTableUpdateCompanionBuilder,
    (
      DeviceTableData,
      BaseReferences<_$AppDatabase, $DeviceTableTable, DeviceTableData>
    ),
    DeviceTableData,
    PrefetchHooks Function()>;
typedef $$TransferTableTableCreateCompanionBuilder = TransferTableCompanion
    Function({
  required String transferId,
  required String filename,
  required String mimeType,
  required int totalBytes,
  required String direction,
  required String peerDeviceId,
  required String peerDeviceName,
  required String state,
  required DateTime startedAt,
  Value<DateTime?> completedAt,
  Value<String?> localPath,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$TransferTableTableUpdateCompanionBuilder = TransferTableCompanion
    Function({
  Value<String> transferId,
  Value<String> filename,
  Value<String> mimeType,
  Value<int> totalBytes,
  Value<String> direction,
  Value<String> peerDeviceId,
  Value<String> peerDeviceName,
  Value<String> state,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<String?> localPath,
  Value<String?> errorMessage,
  Value<int> rowid,
});

class $$TransferTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransferTableTable> {
  $$TransferTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$TransferTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferTableTable> {
  $$TransferTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$TransferTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferTableTable> {
  $$TransferTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);
}

class $$TransferTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransferTableTable,
    TransferTableData,
    $$TransferTableTableFilterComposer,
    $$TransferTableTableOrderingComposer,
    $$TransferTableTableAnnotationComposer,
    $$TransferTableTableCreateCompanionBuilder,
    $$TransferTableTableUpdateCompanionBuilder,
    (
      TransferTableData,
      BaseReferences<_$AppDatabase, $TransferTableTable, TransferTableData>
    ),
    TransferTableData,
    PrefetchHooks Function()> {
  $$TransferTableTableTableManager(_$AppDatabase db, $TransferTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> transferId = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> peerDeviceId = const Value.absent(),
            Value<String> peerDeviceName = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferTableCompanion(
            transferId: transferId,
            filename: filename,
            mimeType: mimeType,
            totalBytes: totalBytes,
            direction: direction,
            peerDeviceId: peerDeviceId,
            peerDeviceName: peerDeviceName,
            state: state,
            startedAt: startedAt,
            completedAt: completedAt,
            localPath: localPath,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String transferId,
            required String filename,
            required String mimeType,
            required int totalBytes,
            required String direction,
            required String peerDeviceId,
            required String peerDeviceName,
            required String state,
            required DateTime startedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferTableCompanion.insert(
            transferId: transferId,
            filename: filename,
            mimeType: mimeType,
            totalBytes: totalBytes,
            direction: direction,
            peerDeviceId: peerDeviceId,
            peerDeviceName: peerDeviceName,
            state: state,
            startedAt: startedAt,
            completedAt: completedAt,
            localPath: localPath,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransferTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransferTableTable,
    TransferTableData,
    $$TransferTableTableFilterComposer,
    $$TransferTableTableOrderingComposer,
    $$TransferTableTableAnnotationComposer,
    $$TransferTableTableCreateCompanionBuilder,
    $$TransferTableTableUpdateCompanionBuilder,
    (
      TransferTableData,
      BaseReferences<_$AppDatabase, $TransferTableTable, TransferTableData>
    ),
    TransferTableData,
    PrefetchHooks Function()>;
typedef $$ClipboardEventTableTableCreateCompanionBuilder
    = ClipboardEventTableCompanion Function({
  required String eventId,
  required String sourceDeviceId,
  required String sourceDeviceName,
  required String textPreview,
  required String payloadHash,
  required DateTime timestamp,
  Value<bool> isLocal,
  Value<int> rowid,
});
typedef $$ClipboardEventTableTableUpdateCompanionBuilder
    = ClipboardEventTableCompanion Function({
  Value<String> eventId,
  Value<String> sourceDeviceId,
  Value<String> sourceDeviceName,
  Value<String> textPreview,
  Value<String> payloadHash,
  Value<DateTime> timestamp,
  Value<bool> isLocal,
  Value<int> rowid,
});

class $$ClipboardEventTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClipboardEventTableTable> {
  $$ClipboardEventTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceDeviceName => $composableBuilder(
      column: $table.sourceDeviceName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textPreview => $composableBuilder(
      column: $table.textPreview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocal => $composableBuilder(
      column: $table.isLocal, builder: (column) => ColumnFilters(column));
}

class $$ClipboardEventTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClipboardEventTableTable> {
  $$ClipboardEventTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceDeviceName => $composableBuilder(
      column: $table.sourceDeviceName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textPreview => $composableBuilder(
      column: $table.textPreview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocal => $composableBuilder(
      column: $table.isLocal, builder: (column) => ColumnOrderings(column));
}

class $$ClipboardEventTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClipboardEventTableTable> {
  $$ClipboardEventTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId, builder: (column) => column);

  GeneratedColumn<String> get sourceDeviceName => $composableBuilder(
      column: $table.sourceDeviceName, builder: (column) => column);

  GeneratedColumn<String> get textPreview => $composableBuilder(
      column: $table.textPreview, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);
}

class $$ClipboardEventTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClipboardEventTableTable,
    ClipboardEventTableData,
    $$ClipboardEventTableTableFilterComposer,
    $$ClipboardEventTableTableOrderingComposer,
    $$ClipboardEventTableTableAnnotationComposer,
    $$ClipboardEventTableTableCreateCompanionBuilder,
    $$ClipboardEventTableTableUpdateCompanionBuilder,
    (
      ClipboardEventTableData,
      BaseReferences<_$AppDatabase, $ClipboardEventTableTable,
          ClipboardEventTableData>
    ),
    ClipboardEventTableData,
    PrefetchHooks Function()> {
  $$ClipboardEventTableTableTableManager(
      _$AppDatabase db, $ClipboardEventTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipboardEventTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipboardEventTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipboardEventTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> eventId = const Value.absent(),
            Value<String> sourceDeviceId = const Value.absent(),
            Value<String> sourceDeviceName = const Value.absent(),
            Value<String> textPreview = const Value.absent(),
            Value<String> payloadHash = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isLocal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClipboardEventTableCompanion(
            eventId: eventId,
            sourceDeviceId: sourceDeviceId,
            sourceDeviceName: sourceDeviceName,
            textPreview: textPreview,
            payloadHash: payloadHash,
            timestamp: timestamp,
            isLocal: isLocal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String eventId,
            required String sourceDeviceId,
            required String sourceDeviceName,
            required String textPreview,
            required String payloadHash,
            required DateTime timestamp,
            Value<bool> isLocal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClipboardEventTableCompanion.insert(
            eventId: eventId,
            sourceDeviceId: sourceDeviceId,
            sourceDeviceName: sourceDeviceName,
            textPreview: textPreview,
            payloadHash: payloadHash,
            timestamp: timestamp,
            isLocal: isLocal,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClipboardEventTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClipboardEventTableTable,
    ClipboardEventTableData,
    $$ClipboardEventTableTableFilterComposer,
    $$ClipboardEventTableTableOrderingComposer,
    $$ClipboardEventTableTableAnnotationComposer,
    $$ClipboardEventTableTableCreateCompanionBuilder,
    $$ClipboardEventTableTableUpdateCompanionBuilder,
    (
      ClipboardEventTableData,
      BaseReferences<_$AppDatabase, $ClipboardEventTableTable,
          ClipboardEventTableData>
    ),
    ClipboardEventTableData,
    PrefetchHooks Function()>;
typedef $$ActivityTableTableCreateCompanionBuilder = ActivityTableCompanion
    Function({
  required String entryId,
  required String type,
  required DateTime timestamp,
  required String description,
  Value<String?> peerDeviceName,
  Value<String?> metadata,
  Value<int> rowid,
});
typedef $$ActivityTableTableUpdateCompanionBuilder = ActivityTableCompanion
    Function({
  Value<String> entryId,
  Value<String> type,
  Value<DateTime> timestamp,
  Value<String> description,
  Value<String?> peerDeviceName,
  Value<String?> metadata,
  Value<int> rowid,
});

class $$ActivityTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityTableTable> {
  $$ActivityTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));
}

class $$ActivityTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityTableTable> {
  $$ActivityTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));
}

class $$ActivityTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityTableTable> {
  $$ActivityTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$ActivityTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivityTableTable,
    ActivityTableData,
    $$ActivityTableTableFilterComposer,
    $$ActivityTableTableOrderingComposer,
    $$ActivityTableTableAnnotationComposer,
    $$ActivityTableTableCreateCompanionBuilder,
    $$ActivityTableTableUpdateCompanionBuilder,
    (
      ActivityTableData,
      BaseReferences<_$AppDatabase, $ActivityTableTable, ActivityTableData>
    ),
    ActivityTableData,
    PrefetchHooks Function()> {
  $$ActivityTableTableTableManager(_$AppDatabase db, $ActivityTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entryId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> peerDeviceName = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivityTableCompanion(
            entryId: entryId,
            type: type,
            timestamp: timestamp,
            description: description,
            peerDeviceName: peerDeviceName,
            metadata: metadata,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entryId,
            required String type,
            required DateTime timestamp,
            required String description,
            Value<String?> peerDeviceName = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivityTableCompanion.insert(
            entryId: entryId,
            type: type,
            timestamp: timestamp,
            description: description,
            peerDeviceName: peerDeviceName,
            metadata: metadata,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivityTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivityTableTable,
    ActivityTableData,
    $$ActivityTableTableFilterComposer,
    $$ActivityTableTableOrderingComposer,
    $$ActivityTableTableAnnotationComposer,
    $$ActivityTableTableCreateCompanionBuilder,
    $$ActivityTableTableUpdateCompanionBuilder,
    (
      ActivityTableData,
      BaseReferences<_$AppDatabase, $ActivityTableTable, ActivityTableData>
    ),
    ActivityTableData,
    PrefetchHooks Function()>;
typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EcosystemTableTableTableManager get ecosystemTable =>
      $$EcosystemTableTableTableManager(_db, _db.ecosystemTable);
  $$DeviceTableTableTableManager get deviceTable =>
      $$DeviceTableTableTableManager(_db, _db.deviceTable);
  $$TransferTableTableTableManager get transferTable =>
      $$TransferTableTableTableManager(_db, _db.transferTable);
  $$ClipboardEventTableTableTableManager get clipboardEventTable =>
      $$ClipboardEventTableTableTableManager(_db, _db.clipboardEventTable);
  $$ActivityTableTableTableManager get activityTable =>
      $$ActivityTableTableTableManager(_db, _db.activityTable);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
