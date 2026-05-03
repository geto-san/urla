// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FrameObservationsTable extends FrameObservations
    with TableInfo<$FrameObservationsTable, FrameObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrameObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    width,
    height,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frame_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrameObservation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrameObservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrameObservation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
    );
  }

  @override
  $FrameObservationsTable createAlias(String alias) {
    return $FrameObservationsTable(attachedDatabase, alias);
  }
}

class FrameObservation extends DataClass
    implements Insertable<FrameObservation> {
  final int id;
  final DateTime timestamp;
  final int width;
  final int height;

  /// links ML inference to frame
  final String sessionId;
  const FrameObservation({
    required this.id,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['session_id'] = Variable<String>(sessionId);
    return map;
  }

  FrameObservationsCompanion toCompanion(bool nullToAbsent) {
    return FrameObservationsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      width: Value(width),
      height: Value(height),
      sessionId: Value(sessionId),
    );
  }

  factory FrameObservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrameObservation(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sessionId': serializer.toJson<String>(sessionId),
    };
  }

  FrameObservation copyWith({
    int? id,
    DateTime? timestamp,
    int? width,
    int? height,
    String? sessionId,
  }) => FrameObservation(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    width: width ?? this.width,
    height: height ?? this.height,
    sessionId: sessionId ?? this.sessionId,
  );
  FrameObservation copyWithCompanion(FrameObservationsCompanion data) {
    return FrameObservation(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrameObservation(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, width, height, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrameObservation &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.width == this.width &&
          other.height == this.height &&
          other.sessionId == this.sessionId);
}

class FrameObservationsCompanion extends UpdateCompanion<FrameObservation> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<int> width;
  final Value<int> height;
  final Value<String> sessionId;
  const FrameObservationsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  FrameObservationsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required int width,
    required int height,
    required String sessionId,
  }) : timestamp = Value(timestamp),
       width = Value(width),
       height = Value(height),
       sessionId = Value(sessionId);
  static Insertable<FrameObservation> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  FrameObservationsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<int>? width,
    Value<int>? height,
    Value<String>? sessionId,
  }) {
    return FrameObservationsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      width: width ?? this.width,
      height: height ?? this.height,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrameObservationsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }
}

class $DetectionEventsTable extends DetectionEvents
    with TableInfo<$DetectionEventsTable, DetectionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameSessionIdMeta = const VerificationMeta(
    'frameSessionId',
  );
  @override
  late final GeneratedColumn<String> frameSessionId = GeneratedColumn<String>(
    'frame_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classNameMeta = const VerificationMeta(
    'className',
  );
  @override
  late final GeneratedColumn<String> className = GeneratedColumn<String>(
    'class_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMinMeta = const VerificationMeta('xMin');
  @override
  late final GeneratedColumn<double> xMin = GeneratedColumn<double>(
    'x_min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMinMeta = const VerificationMeta('yMin');
  @override
  late final GeneratedColumn<double> yMin = GeneratedColumn<double>(
    'y_min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMaxMeta = const VerificationMeta('xMax');
  @override
  late final GeneratedColumn<double> xMax = GeneratedColumn<double>(
    'x_max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMaxMeta = const VerificationMeta('yMax');
  @override
  late final GeneratedColumn<double> yMax = GeneratedColumn<double>(
    'y_max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maskMeta = const VerificationMeta('mask');
  @override
  late final GeneratedColumn<String> mask = GeneratedColumn<String>(
    'mask',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    frameSessionId,
    classId,
    className,
    confidence,
    xMin,
    yMin,
    xMax,
    yMax,
    mask,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detection_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectionEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('frame_session_id')) {
      context.handle(
        _frameSessionIdMeta,
        frameSessionId.isAcceptableOrUnknown(
          data['frame_session_id']!,
          _frameSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_frameSessionIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('class_name')) {
      context.handle(
        _classNameMeta,
        className.isAcceptableOrUnknown(data['class_name']!, _classNameMeta),
      );
    } else if (isInserting) {
      context.missing(_classNameMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('x_min')) {
      context.handle(
        _xMinMeta,
        xMin.isAcceptableOrUnknown(data['x_min']!, _xMinMeta),
      );
    } else if (isInserting) {
      context.missing(_xMinMeta);
    }
    if (data.containsKey('y_min')) {
      context.handle(
        _yMinMeta,
        yMin.isAcceptableOrUnknown(data['y_min']!, _yMinMeta),
      );
    } else if (isInserting) {
      context.missing(_yMinMeta);
    }
    if (data.containsKey('x_max')) {
      context.handle(
        _xMaxMeta,
        xMax.isAcceptableOrUnknown(data['x_max']!, _xMaxMeta),
      );
    } else if (isInserting) {
      context.missing(_xMaxMeta);
    }
    if (data.containsKey('y_max')) {
      context.handle(
        _yMaxMeta,
        yMax.isAcceptableOrUnknown(data['y_max']!, _yMaxMeta),
      );
    } else if (isInserting) {
      context.missing(_yMaxMeta);
    }
    if (data.containsKey('mask')) {
      context.handle(
        _maskMeta,
        mask.isAcceptableOrUnknown(data['mask']!, _maskMeta),
      );
    } else if (isInserting) {
      context.missing(_maskMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetectionEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectionEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      frameSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame_session_id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_id'],
      )!,
      className: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_name'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      xMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_min'],
      )!,
      yMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_min'],
      )!,
      xMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_max'],
      )!,
      yMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_max'],
      )!,
      mask: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mask'],
      )!,
    );
  }

  @override
  $DetectionEventsTable createAlias(String alias) {
    return $DetectionEventsTable(attachedDatabase, alias);
  }
}

class DetectionEvent extends DataClass implements Insertable<DetectionEvent> {
  final int id;
  final DateTime timestamp;
  final String frameSessionId;
  final int classId;
  final String className;
  final double confidence;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  /// serialized segmentation mask (JSON)
  final String mask;
  const DetectionEvent({
    required this.id,
    required this.timestamp,
    required this.frameSessionId,
    required this.classId,
    required this.className,
    required this.confidence,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    required this.mask,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['frame_session_id'] = Variable<String>(frameSessionId);
    map['class_id'] = Variable<int>(classId);
    map['class_name'] = Variable<String>(className);
    map['confidence'] = Variable<double>(confidence);
    map['x_min'] = Variable<double>(xMin);
    map['y_min'] = Variable<double>(yMin);
    map['x_max'] = Variable<double>(xMax);
    map['y_max'] = Variable<double>(yMax);
    map['mask'] = Variable<String>(mask);
    return map;
  }

  DetectionEventsCompanion toCompanion(bool nullToAbsent) {
    return DetectionEventsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      frameSessionId: Value(frameSessionId),
      classId: Value(classId),
      className: Value(className),
      confidence: Value(confidence),
      xMin: Value(xMin),
      yMin: Value(yMin),
      xMax: Value(xMax),
      yMax: Value(yMax),
      mask: Value(mask),
    );
  }

  factory DetectionEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectionEvent(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      frameSessionId: serializer.fromJson<String>(json['frameSessionId']),
      classId: serializer.fromJson<int>(json['classId']),
      className: serializer.fromJson<String>(json['className']),
      confidence: serializer.fromJson<double>(json['confidence']),
      xMin: serializer.fromJson<double>(json['xMin']),
      yMin: serializer.fromJson<double>(json['yMin']),
      xMax: serializer.fromJson<double>(json['xMax']),
      yMax: serializer.fromJson<double>(json['yMax']),
      mask: serializer.fromJson<String>(json['mask']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'frameSessionId': serializer.toJson<String>(frameSessionId),
      'classId': serializer.toJson<int>(classId),
      'className': serializer.toJson<String>(className),
      'confidence': serializer.toJson<double>(confidence),
      'xMin': serializer.toJson<double>(xMin),
      'yMin': serializer.toJson<double>(yMin),
      'xMax': serializer.toJson<double>(xMax),
      'yMax': serializer.toJson<double>(yMax),
      'mask': serializer.toJson<String>(mask),
    };
  }

  DetectionEvent copyWith({
    int? id,
    DateTime? timestamp,
    String? frameSessionId,
    int? classId,
    String? className,
    double? confidence,
    double? xMin,
    double? yMin,
    double? xMax,
    double? yMax,
    String? mask,
  }) => DetectionEvent(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    frameSessionId: frameSessionId ?? this.frameSessionId,
    classId: classId ?? this.classId,
    className: className ?? this.className,
    confidence: confidence ?? this.confidence,
    xMin: xMin ?? this.xMin,
    yMin: yMin ?? this.yMin,
    xMax: xMax ?? this.xMax,
    yMax: yMax ?? this.yMax,
    mask: mask ?? this.mask,
  );
  DetectionEvent copyWithCompanion(DetectionEventsCompanion data) {
    return DetectionEvent(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      frameSessionId: data.frameSessionId.present
          ? data.frameSessionId.value
          : this.frameSessionId,
      classId: data.classId.present ? data.classId.value : this.classId,
      className: data.className.present ? data.className.value : this.className,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      xMin: data.xMin.present ? data.xMin.value : this.xMin,
      yMin: data.yMin.present ? data.yMin.value : this.yMin,
      xMax: data.xMax.present ? data.xMax.value : this.xMax,
      yMax: data.yMax.present ? data.yMax.value : this.yMax,
      mask: data.mask.present ? data.mask.value : this.mask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectionEvent(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('frameSessionId: $frameSessionId, ')
          ..write('classId: $classId, ')
          ..write('className: $className, ')
          ..write('confidence: $confidence, ')
          ..write('xMin: $xMin, ')
          ..write('yMin: $yMin, ')
          ..write('xMax: $xMax, ')
          ..write('yMax: $yMax, ')
          ..write('mask: $mask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    frameSessionId,
    classId,
    className,
    confidence,
    xMin,
    yMin,
    xMax,
    yMax,
    mask,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionEvent &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.frameSessionId == this.frameSessionId &&
          other.classId == this.classId &&
          other.className == this.className &&
          other.confidence == this.confidence &&
          other.xMin == this.xMin &&
          other.yMin == this.yMin &&
          other.xMax == this.xMax &&
          other.yMax == this.yMax &&
          other.mask == this.mask);
}

class DetectionEventsCompanion extends UpdateCompanion<DetectionEvent> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> frameSessionId;
  final Value<int> classId;
  final Value<String> className;
  final Value<double> confidence;
  final Value<double> xMin;
  final Value<double> yMin;
  final Value<double> xMax;
  final Value<double> yMax;
  final Value<String> mask;
  const DetectionEventsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.frameSessionId = const Value.absent(),
    this.classId = const Value.absent(),
    this.className = const Value.absent(),
    this.confidence = const Value.absent(),
    this.xMin = const Value.absent(),
    this.yMin = const Value.absent(),
    this.xMax = const Value.absent(),
    this.yMax = const Value.absent(),
    this.mask = const Value.absent(),
  });
  DetectionEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required String frameSessionId,
    required int classId,
    required String className,
    required double confidence,
    required double xMin,
    required double yMin,
    required double xMax,
    required double yMax,
    required String mask,
  }) : timestamp = Value(timestamp),
       frameSessionId = Value(frameSessionId),
       classId = Value(classId),
       className = Value(className),
       confidence = Value(confidence),
       xMin = Value(xMin),
       yMin = Value(yMin),
       xMax = Value(xMax),
       yMax = Value(yMax),
       mask = Value(mask);
  static Insertable<DetectionEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? frameSessionId,
    Expression<int>? classId,
    Expression<String>? className,
    Expression<double>? confidence,
    Expression<double>? xMin,
    Expression<double>? yMin,
    Expression<double>? xMax,
    Expression<double>? yMax,
    Expression<String>? mask,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (frameSessionId != null) 'frame_session_id': frameSessionId,
      if (classId != null) 'class_id': classId,
      if (className != null) 'class_name': className,
      if (confidence != null) 'confidence': confidence,
      if (xMin != null) 'x_min': xMin,
      if (yMin != null) 'y_min': yMin,
      if (xMax != null) 'x_max': xMax,
      if (yMax != null) 'y_max': yMax,
      if (mask != null) 'mask': mask,
    });
  }

  DetectionEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? frameSessionId,
    Value<int>? classId,
    Value<String>? className,
    Value<double>? confidence,
    Value<double>? xMin,
    Value<double>? yMin,
    Value<double>? xMax,
    Value<double>? yMax,
    Value<String>? mask,
  }) {
    return DetectionEventsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      frameSessionId: frameSessionId ?? this.frameSessionId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      confidence: confidence ?? this.confidence,
      xMin: xMin ?? this.xMin,
      yMin: yMin ?? this.yMin,
      xMax: xMax ?? this.xMax,
      yMax: yMax ?? this.yMax,
      mask: mask ?? this.mask,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (frameSessionId.present) {
      map['frame_session_id'] = Variable<String>(frameSessionId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (className.present) {
      map['class_name'] = Variable<String>(className.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (xMin.present) {
      map['x_min'] = Variable<double>(xMin.value);
    }
    if (yMin.present) {
      map['y_min'] = Variable<double>(yMin.value);
    }
    if (xMax.present) {
      map['x_max'] = Variable<double>(xMax.value);
    }
    if (yMax.present) {
      map['y_max'] = Variable<double>(yMax.value);
    }
    if (mask.present) {
      map['mask'] = Variable<String>(mask.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectionEventsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('frameSessionId: $frameSessionId, ')
          ..write('classId: $classId, ')
          ..write('className: $className, ')
          ..write('confidence: $confidence, ')
          ..write('xMin: $xMin, ')
          ..write('yMin: $yMin, ')
          ..write('xMax: $xMax, ')
          ..write('yMax: $yMax, ')
          ..write('mask: $mask')
          ..write(')'))
        .toString();
  }
}

class $LaneSnapshotsTable extends LaneSnapshots
    with TableInfo<$LaneSnapshotsTable, LaneSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LaneSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameSessionIdMeta = const VerificationMeta(
    'frameSessionId',
  );
  @override
  late final GeneratedColumn<String> frameSessionId = GeneratedColumn<String>(
    'frame_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driftScoreMeta = const VerificationMeta(
    'driftScore',
  );
  @override
  late final GeneratedColumn<double> driftScore = GeneratedColumn<double>(
    'drift_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _curvatureMeta = const VerificationMeta(
    'curvature',
  );
  @override
  late final GeneratedColumn<double> curvature = GeneratedColumn<double>(
    'curvature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneWidthMeta = const VerificationMeta(
    'laneWidth',
  );
  @override
  late final GeneratedColumn<double> laneWidth = GeneratedColumn<double>(
    'lane_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneTypeMeta = const VerificationMeta(
    'laneType',
  );
  @override
  late final GeneratedColumn<String> laneType = GeneratedColumn<String>(
    'lane_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerLineMeta = const VerificationMeta(
    'centerLine',
  );
  @override
  late final GeneratedColumn<String> centerLine = GeneratedColumn<String>(
    'center_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftBoundaryMeta = const VerificationMeta(
    'leftBoundary',
  );
  @override
  late final GeneratedColumn<String> leftBoundary = GeneratedColumn<String>(
    'left_boundary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightBoundaryMeta = const VerificationMeta(
    'rightBoundary',
  );
  @override
  late final GeneratedColumn<String> rightBoundary = GeneratedColumn<String>(
    'right_boundary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    frameSessionId,
    confidence,
    driftScore,
    curvature,
    laneWidth,
    laneType,
    centerLine,
    leftBoundary,
    rightBoundary,
    latitude,
    longitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lane_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LaneSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('frame_session_id')) {
      context.handle(
        _frameSessionIdMeta,
        frameSessionId.isAcceptableOrUnknown(
          data['frame_session_id']!,
          _frameSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('drift_score')) {
      context.handle(
        _driftScoreMeta,
        driftScore.isAcceptableOrUnknown(data['drift_score']!, _driftScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_driftScoreMeta);
    }
    if (data.containsKey('curvature')) {
      context.handle(
        _curvatureMeta,
        curvature.isAcceptableOrUnknown(data['curvature']!, _curvatureMeta),
      );
    } else if (isInserting) {
      context.missing(_curvatureMeta);
    }
    if (data.containsKey('lane_width')) {
      context.handle(
        _laneWidthMeta,
        laneWidth.isAcceptableOrUnknown(data['lane_width']!, _laneWidthMeta),
      );
    } else if (isInserting) {
      context.missing(_laneWidthMeta);
    }
    if (data.containsKey('lane_type')) {
      context.handle(
        _laneTypeMeta,
        laneType.isAcceptableOrUnknown(data['lane_type']!, _laneTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_laneTypeMeta);
    }
    if (data.containsKey('center_line')) {
      context.handle(
        _centerLineMeta,
        centerLine.isAcceptableOrUnknown(data['center_line']!, _centerLineMeta),
      );
    } else if (isInserting) {
      context.missing(_centerLineMeta);
    }
    if (data.containsKey('left_boundary')) {
      context.handle(
        _leftBoundaryMeta,
        leftBoundary.isAcceptableOrUnknown(
          data['left_boundary']!,
          _leftBoundaryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_leftBoundaryMeta);
    }
    if (data.containsKey('right_boundary')) {
      context.handle(
        _rightBoundaryMeta,
        rightBoundary.isAcceptableOrUnknown(
          data['right_boundary']!,
          _rightBoundaryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rightBoundaryMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LaneSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LaneSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      frameSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame_session_id'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      driftScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}drift_score'],
      )!,
      curvature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}curvature'],
      )!,
      laneWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lane_width'],
      )!,
      laneType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lane_type'],
      )!,
      centerLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}center_line'],
      )!,
      leftBoundary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}left_boundary'],
      )!,
      rightBoundary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}right_boundary'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
    );
  }

  @override
  $LaneSnapshotsTable createAlias(String alias) {
    return $LaneSnapshotsTable(attachedDatabase, alias);
  }
}

class LaneSnapshot extends DataClass implements Insertable<LaneSnapshot> {
  final int id;
  final DateTime timestamp;
  final String? frameSessionId;
  final double confidence;
  final double driftScore;
  final double curvature;
  final double laneWidth;
  final String laneType;
  final String centerLine;
  final String leftBoundary;
  final String rightBoundary;
  final double? latitude;
  final double? longitude;
  const LaneSnapshot({
    required this.id,
    required this.timestamp,
    this.frameSessionId,
    required this.confidence,
    required this.driftScore,
    required this.curvature,
    required this.laneWidth,
    required this.laneType,
    required this.centerLine,
    required this.leftBoundary,
    required this.rightBoundary,
    this.latitude,
    this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || frameSessionId != null) {
      map['frame_session_id'] = Variable<String>(frameSessionId);
    }
    map['confidence'] = Variable<double>(confidence);
    map['drift_score'] = Variable<double>(driftScore);
    map['curvature'] = Variable<double>(curvature);
    map['lane_width'] = Variable<double>(laneWidth);
    map['lane_type'] = Variable<String>(laneType);
    map['center_line'] = Variable<String>(centerLine);
    map['left_boundary'] = Variable<String>(leftBoundary);
    map['right_boundary'] = Variable<String>(rightBoundary);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    return map;
  }

  LaneSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return LaneSnapshotsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      frameSessionId: frameSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(frameSessionId),
      confidence: Value(confidence),
      driftScore: Value(driftScore),
      curvature: Value(curvature),
      laneWidth: Value(laneWidth),
      laneType: Value(laneType),
      centerLine: Value(centerLine),
      leftBoundary: Value(leftBoundary),
      rightBoundary: Value(rightBoundary),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
    );
  }

  factory LaneSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LaneSnapshot(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      frameSessionId: serializer.fromJson<String?>(json['frameSessionId']),
      confidence: serializer.fromJson<double>(json['confidence']),
      driftScore: serializer.fromJson<double>(json['driftScore']),
      curvature: serializer.fromJson<double>(json['curvature']),
      laneWidth: serializer.fromJson<double>(json['laneWidth']),
      laneType: serializer.fromJson<String>(json['laneType']),
      centerLine: serializer.fromJson<String>(json['centerLine']),
      leftBoundary: serializer.fromJson<String>(json['leftBoundary']),
      rightBoundary: serializer.fromJson<String>(json['rightBoundary']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'frameSessionId': serializer.toJson<String?>(frameSessionId),
      'confidence': serializer.toJson<double>(confidence),
      'driftScore': serializer.toJson<double>(driftScore),
      'curvature': serializer.toJson<double>(curvature),
      'laneWidth': serializer.toJson<double>(laneWidth),
      'laneType': serializer.toJson<String>(laneType),
      'centerLine': serializer.toJson<String>(centerLine),
      'leftBoundary': serializer.toJson<String>(leftBoundary),
      'rightBoundary': serializer.toJson<String>(rightBoundary),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
    };
  }

  LaneSnapshot copyWith({
    int? id,
    DateTime? timestamp,
    Value<String?> frameSessionId = const Value.absent(),
    double? confidence,
    double? driftScore,
    double? curvature,
    double? laneWidth,
    String? laneType,
    String? centerLine,
    String? leftBoundary,
    String? rightBoundary,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
  }) => LaneSnapshot(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    frameSessionId: frameSessionId.present
        ? frameSessionId.value
        : this.frameSessionId,
    confidence: confidence ?? this.confidence,
    driftScore: driftScore ?? this.driftScore,
    curvature: curvature ?? this.curvature,
    laneWidth: laneWidth ?? this.laneWidth,
    laneType: laneType ?? this.laneType,
    centerLine: centerLine ?? this.centerLine,
    leftBoundary: leftBoundary ?? this.leftBoundary,
    rightBoundary: rightBoundary ?? this.rightBoundary,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
  );
  LaneSnapshot copyWithCompanion(LaneSnapshotsCompanion data) {
    return LaneSnapshot(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      frameSessionId: data.frameSessionId.present
          ? data.frameSessionId.value
          : this.frameSessionId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      driftScore: data.driftScore.present
          ? data.driftScore.value
          : this.driftScore,
      curvature: data.curvature.present ? data.curvature.value : this.curvature,
      laneWidth: data.laneWidth.present ? data.laneWidth.value : this.laneWidth,
      laneType: data.laneType.present ? data.laneType.value : this.laneType,
      centerLine: data.centerLine.present
          ? data.centerLine.value
          : this.centerLine,
      leftBoundary: data.leftBoundary.present
          ? data.leftBoundary.value
          : this.leftBoundary,
      rightBoundary: data.rightBoundary.present
          ? data.rightBoundary.value
          : this.rightBoundary,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LaneSnapshot(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('frameSessionId: $frameSessionId, ')
          ..write('confidence: $confidence, ')
          ..write('driftScore: $driftScore, ')
          ..write('curvature: $curvature, ')
          ..write('laneWidth: $laneWidth, ')
          ..write('laneType: $laneType, ')
          ..write('centerLine: $centerLine, ')
          ..write('leftBoundary: $leftBoundary, ')
          ..write('rightBoundary: $rightBoundary, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    frameSessionId,
    confidence,
    driftScore,
    curvature,
    laneWidth,
    laneType,
    centerLine,
    leftBoundary,
    rightBoundary,
    latitude,
    longitude,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LaneSnapshot &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.frameSessionId == this.frameSessionId &&
          other.confidence == this.confidence &&
          other.driftScore == this.driftScore &&
          other.curvature == this.curvature &&
          other.laneWidth == this.laneWidth &&
          other.laneType == this.laneType &&
          other.centerLine == this.centerLine &&
          other.leftBoundary == this.leftBoundary &&
          other.rightBoundary == this.rightBoundary &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class LaneSnapshotsCompanion extends UpdateCompanion<LaneSnapshot> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String?> frameSessionId;
  final Value<double> confidence;
  final Value<double> driftScore;
  final Value<double> curvature;
  final Value<double> laneWidth;
  final Value<String> laneType;
  final Value<String> centerLine;
  final Value<String> leftBoundary;
  final Value<String> rightBoundary;
  final Value<double?> latitude;
  final Value<double?> longitude;
  const LaneSnapshotsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.frameSessionId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.driftScore = const Value.absent(),
    this.curvature = const Value.absent(),
    this.laneWidth = const Value.absent(),
    this.laneType = const Value.absent(),
    this.centerLine = const Value.absent(),
    this.leftBoundary = const Value.absent(),
    this.rightBoundary = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  });
  LaneSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    this.frameSessionId = const Value.absent(),
    required double confidence,
    required double driftScore,
    required double curvature,
    required double laneWidth,
    required String laneType,
    required String centerLine,
    required String leftBoundary,
    required String rightBoundary,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  }) : timestamp = Value(timestamp),
       confidence = Value(confidence),
       driftScore = Value(driftScore),
       curvature = Value(curvature),
       laneWidth = Value(laneWidth),
       laneType = Value(laneType),
       centerLine = Value(centerLine),
       leftBoundary = Value(leftBoundary),
       rightBoundary = Value(rightBoundary);
  static Insertable<LaneSnapshot> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? frameSessionId,
    Expression<double>? confidence,
    Expression<double>? driftScore,
    Expression<double>? curvature,
    Expression<double>? laneWidth,
    Expression<String>? laneType,
    Expression<String>? centerLine,
    Expression<String>? leftBoundary,
    Expression<String>? rightBoundary,
    Expression<double>? latitude,
    Expression<double>? longitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (frameSessionId != null) 'frame_session_id': frameSessionId,
      if (confidence != null) 'confidence': confidence,
      if (driftScore != null) 'drift_score': driftScore,
      if (curvature != null) 'curvature': curvature,
      if (laneWidth != null) 'lane_width': laneWidth,
      if (laneType != null) 'lane_type': laneType,
      if (centerLine != null) 'center_line': centerLine,
      if (leftBoundary != null) 'left_boundary': leftBoundary,
      if (rightBoundary != null) 'right_boundary': rightBoundary,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  LaneSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String?>? frameSessionId,
    Value<double>? confidence,
    Value<double>? driftScore,
    Value<double>? curvature,
    Value<double>? laneWidth,
    Value<String>? laneType,
    Value<String>? centerLine,
    Value<String>? leftBoundary,
    Value<String>? rightBoundary,
    Value<double?>? latitude,
    Value<double?>? longitude,
  }) {
    return LaneSnapshotsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      frameSessionId: frameSessionId ?? this.frameSessionId,
      confidence: confidence ?? this.confidence,
      driftScore: driftScore ?? this.driftScore,
      curvature: curvature ?? this.curvature,
      laneWidth: laneWidth ?? this.laneWidth,
      laneType: laneType ?? this.laneType,
      centerLine: centerLine ?? this.centerLine,
      leftBoundary: leftBoundary ?? this.leftBoundary,
      rightBoundary: rightBoundary ?? this.rightBoundary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (frameSessionId.present) {
      map['frame_session_id'] = Variable<String>(frameSessionId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (driftScore.present) {
      map['drift_score'] = Variable<double>(driftScore.value);
    }
    if (curvature.present) {
      map['curvature'] = Variable<double>(curvature.value);
    }
    if (laneWidth.present) {
      map['lane_width'] = Variable<double>(laneWidth.value);
    }
    if (laneType.present) {
      map['lane_type'] = Variable<String>(laneType.value);
    }
    if (centerLine.present) {
      map['center_line'] = Variable<String>(centerLine.value);
    }
    if (leftBoundary.present) {
      map['left_boundary'] = Variable<String>(leftBoundary.value);
    }
    if (rightBoundary.present) {
      map['right_boundary'] = Variable<String>(rightBoundary.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LaneSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('frameSessionId: $frameSessionId, ')
          ..write('confidence: $confidence, ')
          ..write('driftScore: $driftScore, ')
          ..write('curvature: $curvature, ')
          ..write('laneWidth: $laneWidth, ')
          ..write('laneType: $laneType, ')
          ..write('centerLine: $centerLine, ')
          ..write('leftBoundary: $leftBoundary, ')
          ..write('rightBoundary: $rightBoundary, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

class $DrivingEventsTable extends DrivingEvents
    with TableInfo<$DrivingEventsTable, DrivingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrivingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<double> severity = GeneratedColumn<double>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    sessionId,
    eventType,
    severity,
    confidence,
    latitude,
    longitude,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'driving_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrivingEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrivingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrivingEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}severity'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $DrivingEventsTable createAlias(String alias) {
    return $DrivingEventsTable(attachedDatabase, alias);
  }
}

class DrivingEvent extends DataClass implements Insertable<DrivingEvent> {
  final int id;
  final DateTime timestamp;
  final String? sessionId;
  final String eventType;
  final double severity;
  final double confidence;
  final double? latitude;
  final double? longitude;
  final String? metadata;
  const DrivingEvent({
    required this.id,
    required this.timestamp,
    this.sessionId,
    required this.eventType,
    required this.severity,
    required this.confidence,
    this.latitude,
    this.longitude,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['event_type'] = Variable<String>(eventType);
    map['severity'] = Variable<double>(severity);
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  DrivingEventsCompanion toCompanion(bool nullToAbsent) {
    return DrivingEventsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      eventType: Value(eventType),
      severity: Value(severity),
      confidence: Value(confidence),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory DrivingEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrivingEvent(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      severity: serializer.fromJson<double>(json['severity']),
      confidence: serializer.fromJson<double>(json['confidence']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'sessionId': serializer.toJson<String?>(sessionId),
      'eventType': serializer.toJson<String>(eventType),
      'severity': serializer.toJson<double>(severity),
      'confidence': serializer.toJson<double>(confidence),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  DrivingEvent copyWith({
    int? id,
    DateTime? timestamp,
    Value<String?> sessionId = const Value.absent(),
    String? eventType,
    double? severity,
    double? confidence,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
  }) => DrivingEvent(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    eventType: eventType ?? this.eventType,
    severity: severity ?? this.severity,
    confidence: confidence ?? this.confidence,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  DrivingEvent copyWithCompanion(DrivingEventsCompanion data) {
    return DrivingEvent(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      severity: data.severity.present ? data.severity.value : this.severity,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrivingEvent(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('severity: $severity, ')
          ..write('confidence: $confidence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    sessionId,
    eventType,
    severity,
    confidence,
    latitude,
    longitude,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrivingEvent &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.sessionId == this.sessionId &&
          other.eventType == this.eventType &&
          other.severity == this.severity &&
          other.confidence == this.confidence &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.metadata == this.metadata);
}

class DrivingEventsCompanion extends UpdateCompanion<DrivingEvent> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String?> sessionId;
  final Value<String> eventType;
  final Value<double> severity;
  final Value<double> confidence;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> metadata;
  const DrivingEventsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.severity = const Value.absent(),
    this.confidence = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  DrivingEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    this.sessionId = const Value.absent(),
    required String eventType,
    required double severity,
    required double confidence,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.metadata = const Value.absent(),
  }) : timestamp = Value(timestamp),
       eventType = Value(eventType),
       severity = Value(severity),
       confidence = Value(confidence);
  static Insertable<DrivingEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? sessionId,
    Expression<String>? eventType,
    Expression<double>? severity,
    Expression<double>? confidence,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (sessionId != null) 'session_id': sessionId,
      if (eventType != null) 'event_type': eventType,
      if (severity != null) 'severity': severity,
      if (confidence != null) 'confidence': confidence,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (metadata != null) 'metadata': metadata,
    });
  }

  DrivingEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String?>? sessionId,
    Value<String>? eventType,
    Value<double>? severity,
    Value<double>? confidence,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? metadata,
  }) {
    return DrivingEventsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<double>(severity.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrivingEventsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('severity: $severity, ')
          ..write('confidence: $confidence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }
}

class $GeoCellsTable extends GeoCells with TableInfo<$GeoCellsTable, GeoCell> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeoCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<int> x = GeneratedColumn<int>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<int> y = GeneratedColumn<int>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskScoreMeta = const VerificationMeta(
    'riskScore',
  );
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
    'risk_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    x,
    y,
    riskScore,
    stability,
    sampleCount,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geo_cells';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeoCell> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('risk_score')) {
      context.handle(
        _riskScoreMeta,
        riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {x, y};
  @override
  GeoCell map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeoCell(
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y'],
      )!,
      riskScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_score'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
    );
  }

  @override
  $GeoCellsTable createAlias(String alias) {
    return $GeoCellsTable(attachedDatabase, alias);
  }
}

class GeoCell extends DataClass implements Insertable<GeoCell> {
  final int x;
  final int y;
  final double riskScore;
  final double stability;
  final int sampleCount;
  final DateTime lastUpdated;
  const GeoCell({
    required this.x,
    required this.y,
    required this.riskScore,
    required this.stability,
    required this.sampleCount,
    required this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['x'] = Variable<int>(x);
    map['y'] = Variable<int>(y);
    map['risk_score'] = Variable<double>(riskScore);
    map['stability'] = Variable<double>(stability);
    map['sample_count'] = Variable<int>(sampleCount);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    return map;
  }

  GeoCellsCompanion toCompanion(bool nullToAbsent) {
    return GeoCellsCompanion(
      x: Value(x),
      y: Value(y),
      riskScore: Value(riskScore),
      stability: Value(stability),
      sampleCount: Value(sampleCount),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory GeoCell.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeoCell(
      x: serializer.fromJson<int>(json['x']),
      y: serializer.fromJson<int>(json['y']),
      riskScore: serializer.fromJson<double>(json['riskScore']),
      stability: serializer.fromJson<double>(json['stability']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'x': serializer.toJson<int>(x),
      'y': serializer.toJson<int>(y),
      'riskScore': serializer.toJson<double>(riskScore),
      'stability': serializer.toJson<double>(stability),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
    };
  }

  GeoCell copyWith({
    int? x,
    int? y,
    double? riskScore,
    double? stability,
    int? sampleCount,
    DateTime? lastUpdated,
  }) => GeoCell(
    x: x ?? this.x,
    y: y ?? this.y,
    riskScore: riskScore ?? this.riskScore,
    stability: stability ?? this.stability,
    sampleCount: sampleCount ?? this.sampleCount,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
  GeoCell copyWithCompanion(GeoCellsCompanion data) {
    return GeoCell(
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      stability: data.stability.present ? data.stability.value : this.stability,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeoCell(')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('riskScore: $riskScore, ')
          ..write('stability: $stability, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(x, y, riskScore, stability, sampleCount, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeoCell &&
          other.x == this.x &&
          other.y == this.y &&
          other.riskScore == this.riskScore &&
          other.stability == this.stability &&
          other.sampleCount == this.sampleCount &&
          other.lastUpdated == this.lastUpdated);
}

class GeoCellsCompanion extends UpdateCompanion<GeoCell> {
  final Value<int> x;
  final Value<int> y;
  final Value<double> riskScore;
  final Value<double> stability;
  final Value<int> sampleCount;
  final Value<DateTime> lastUpdated;
  final Value<int> rowid;
  const GeoCellsCompanion({
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.stability = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeoCellsCompanion.insert({
    required int x,
    required int y,
    this.riskScore = const Value.absent(),
    this.stability = const Value.absent(),
    this.sampleCount = const Value.absent(),
    required DateTime lastUpdated,
    this.rowid = const Value.absent(),
  }) : x = Value(x),
       y = Value(y),
       lastUpdated = Value(lastUpdated);
  static Insertable<GeoCell> custom({
    Expression<int>? x,
    Expression<int>? y,
    Expression<double>? riskScore,
    Expression<double>? stability,
    Expression<int>? sampleCount,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (riskScore != null) 'risk_score': riskScore,
      if (stability != null) 'stability': stability,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeoCellsCompanion copyWith({
    Value<int>? x,
    Value<int>? y,
    Value<double>? riskScore,
    Value<double>? stability,
    Value<int>? sampleCount,
    Value<DateTime>? lastUpdated,
    Value<int>? rowid,
  }) {
    return GeoCellsCompanion(
      x: x ?? this.x,
      y: y ?? this.y,
      riskScore: riskScore ?? this.riskScore,
      stability: stability ?? this.stability,
      sampleCount: sampleCount ?? this.sampleCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (x.present) {
      map['x'] = Variable<int>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<int>(y.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeoCellsCompanion(')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('riskScore: $riskScore, ')
          ..write('stability: $stability, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoadSegmentsTable extends RoadSegments
    with TableInfo<$RoadSegmentsTable, RoadSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoadSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgLaneWidthMeta = const VerificationMeta(
    'avgLaneWidth',
  );
  @override
  late final GeneratedColumn<double> avgLaneWidth = GeneratedColumn<double>(
    'avg_lane_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgCurvatureMeta = const VerificationMeta(
    'avgCurvature',
  );
  @override
  late final GeneratedColumn<double> avgCurvature = GeneratedColumn<double>(
    'avg_curvature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgDriftMeta = const VerificationMeta(
    'avgDrift',
  );
  @override
  late final GeneratedColumn<double> avgDrift = GeneratedColumn<double>(
    'avg_drift',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roadTypeMeta = const VerificationMeta(
    'roadType',
  );
  @override
  late final GeneratedColumn<String> roadType = GeneratedColumn<String>(
    'road_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lat,
    lng,
    avgLaneWidth,
    avgCurvature,
    avgDrift,
    roadType,
    sampleCount,
    lastSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'road_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoadSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('avg_lane_width')) {
      context.handle(
        _avgLaneWidthMeta,
        avgLaneWidth.isAcceptableOrUnknown(
          data['avg_lane_width']!,
          _avgLaneWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgLaneWidthMeta);
    }
    if (data.containsKey('avg_curvature')) {
      context.handle(
        _avgCurvatureMeta,
        avgCurvature.isAcceptableOrUnknown(
          data['avg_curvature']!,
          _avgCurvatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgCurvatureMeta);
    }
    if (data.containsKey('avg_drift')) {
      context.handle(
        _avgDriftMeta,
        avgDrift.isAcceptableOrUnknown(data['avg_drift']!, _avgDriftMeta),
      );
    } else if (isInserting) {
      context.missing(_avgDriftMeta);
    }
    if (data.containsKey('road_type')) {
      context.handle(
        _roadTypeMeta,
        roadType.isAcceptableOrUnknown(data['road_type']!, _roadTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_roadTypeMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoadSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoadSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      avgLaneWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_lane_width'],
      )!,
      avgCurvature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_curvature'],
      )!,
      avgDrift: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_drift'],
      )!,
      roadType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_type'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
    );
  }

  @override
  $RoadSegmentsTable createAlias(String alias) {
    return $RoadSegmentsTable(attachedDatabase, alias);
  }
}

class RoadSegment extends DataClass implements Insertable<RoadSegment> {
  final String id;
  final double lat;
  final double lng;
  final double avgLaneWidth;
  final double avgCurvature;
  final double avgDrift;
  final String roadType;
  final int sampleCount;
  final DateTime lastSeen;
  const RoadSegment({
    required this.id,
    required this.lat,
    required this.lng,
    required this.avgLaneWidth,
    required this.avgCurvature,
    required this.avgDrift,
    required this.roadType,
    required this.sampleCount,
    required this.lastSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['avg_lane_width'] = Variable<double>(avgLaneWidth);
    map['avg_curvature'] = Variable<double>(avgCurvature);
    map['avg_drift'] = Variable<double>(avgDrift);
    map['road_type'] = Variable<String>(roadType);
    map['sample_count'] = Variable<int>(sampleCount);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    return map;
  }

  RoadSegmentsCompanion toCompanion(bool nullToAbsent) {
    return RoadSegmentsCompanion(
      id: Value(id),
      lat: Value(lat),
      lng: Value(lng),
      avgLaneWidth: Value(avgLaneWidth),
      avgCurvature: Value(avgCurvature),
      avgDrift: Value(avgDrift),
      roadType: Value(roadType),
      sampleCount: Value(sampleCount),
      lastSeen: Value(lastSeen),
    );
  }

  factory RoadSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoadSegment(
      id: serializer.fromJson<String>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      avgLaneWidth: serializer.fromJson<double>(json['avgLaneWidth']),
      avgCurvature: serializer.fromJson<double>(json['avgCurvature']),
      avgDrift: serializer.fromJson<double>(json['avgDrift']),
      roadType: serializer.fromJson<String>(json['roadType']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'avgLaneWidth': serializer.toJson<double>(avgLaneWidth),
      'avgCurvature': serializer.toJson<double>(avgCurvature),
      'avgDrift': serializer.toJson<double>(avgDrift),
      'roadType': serializer.toJson<String>(roadType),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
    };
  }

  RoadSegment copyWith({
    String? id,
    double? lat,
    double? lng,
    double? avgLaneWidth,
    double? avgCurvature,
    double? avgDrift,
    String? roadType,
    int? sampleCount,
    DateTime? lastSeen,
  }) => RoadSegment(
    id: id ?? this.id,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    avgLaneWidth: avgLaneWidth ?? this.avgLaneWidth,
    avgCurvature: avgCurvature ?? this.avgCurvature,
    avgDrift: avgDrift ?? this.avgDrift,
    roadType: roadType ?? this.roadType,
    sampleCount: sampleCount ?? this.sampleCount,
    lastSeen: lastSeen ?? this.lastSeen,
  );
  RoadSegment copyWithCompanion(RoadSegmentsCompanion data) {
    return RoadSegment(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      avgLaneWidth: data.avgLaneWidth.present
          ? data.avgLaneWidth.value
          : this.avgLaneWidth,
      avgCurvature: data.avgCurvature.present
          ? data.avgCurvature.value
          : this.avgCurvature,
      avgDrift: data.avgDrift.present ? data.avgDrift.value : this.avgDrift,
      roadType: data.roadType.present ? data.roadType.value : this.roadType,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoadSegment(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('avgLaneWidth: $avgLaneWidth, ')
          ..write('avgCurvature: $avgCurvature, ')
          ..write('avgDrift: $avgDrift, ')
          ..write('roadType: $roadType, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lat,
    lng,
    avgLaneWidth,
    avgCurvature,
    avgDrift,
    roadType,
    sampleCount,
    lastSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoadSegment &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.avgLaneWidth == this.avgLaneWidth &&
          other.avgCurvature == this.avgCurvature &&
          other.avgDrift == this.avgDrift &&
          other.roadType == this.roadType &&
          other.sampleCount == this.sampleCount &&
          other.lastSeen == this.lastSeen);
}

class RoadSegmentsCompanion extends UpdateCompanion<RoadSegment> {
  final Value<String> id;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> avgLaneWidth;
  final Value<double> avgCurvature;
  final Value<double> avgDrift;
  final Value<String> roadType;
  final Value<int> sampleCount;
  final Value<DateTime> lastSeen;
  final Value<int> rowid;
  const RoadSegmentsCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.avgLaneWidth = const Value.absent(),
    this.avgCurvature = const Value.absent(),
    this.avgDrift = const Value.absent(),
    this.roadType = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoadSegmentsCompanion.insert({
    required String id,
    required double lat,
    required double lng,
    required double avgLaneWidth,
    required double avgCurvature,
    required double avgDrift,
    required String roadType,
    this.sampleCount = const Value.absent(),
    required DateTime lastSeen,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lat = Value(lat),
       lng = Value(lng),
       avgLaneWidth = Value(avgLaneWidth),
       avgCurvature = Value(avgCurvature),
       avgDrift = Value(avgDrift),
       roadType = Value(roadType),
       lastSeen = Value(lastSeen);
  static Insertable<RoadSegment> custom({
    Expression<String>? id,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? avgLaneWidth,
    Expression<double>? avgCurvature,
    Expression<double>? avgDrift,
    Expression<String>? roadType,
    Expression<int>? sampleCount,
    Expression<DateTime>? lastSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (avgLaneWidth != null) 'avg_lane_width': avgLaneWidth,
      if (avgCurvature != null) 'avg_curvature': avgCurvature,
      if (avgDrift != null) 'avg_drift': avgDrift,
      if (roadType != null) 'road_type': roadType,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoadSegmentsCompanion copyWith({
    Value<String>? id,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? avgLaneWidth,
    Value<double>? avgCurvature,
    Value<double>? avgDrift,
    Value<String>? roadType,
    Value<int>? sampleCount,
    Value<DateTime>? lastSeen,
    Value<int>? rowid,
  }) {
    return RoadSegmentsCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      avgLaneWidth: avgLaneWidth ?? this.avgLaneWidth,
      avgCurvature: avgCurvature ?? this.avgCurvature,
      avgDrift: avgDrift ?? this.avgDrift,
      roadType: roadType ?? this.roadType,
      sampleCount: sampleCount ?? this.sampleCount,
      lastSeen: lastSeen ?? this.lastSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (avgLaneWidth.present) {
      map['avg_lane_width'] = Variable<double>(avgLaneWidth.value);
    }
    if (avgCurvature.present) {
      map['avg_curvature'] = Variable<double>(avgCurvature.value);
    }
    if (avgDrift.present) {
      map['avg_drift'] = Variable<double>(avgDrift.value);
    }
    if (roadType.present) {
      map['road_type'] = Variable<String>(roadType.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
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
    return (StringBuffer('RoadSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('avgLaneWidth: $avgLaneWidth, ')
          ..write('avgCurvature: $avgCurvature, ')
          ..write('avgDrift: $avgDrift, ')
          ..write('roadType: $roadType, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FrameObservationsTable frameObservations =
      $FrameObservationsTable(this);
  late final $DetectionEventsTable detectionEvents = $DetectionEventsTable(
    this,
  );
  late final $LaneSnapshotsTable laneSnapshots = $LaneSnapshotsTable(this);
  late final $DrivingEventsTable drivingEvents = $DrivingEventsTable(this);
  late final $GeoCellsTable geoCells = $GeoCellsTable(this);
  late final $RoadSegmentsTable roadSegments = $RoadSegmentsTable(this);
  late final Index frameTimestampIdx = Index(
    'frame_timestamp_idx',
    'CREATE INDEX frame_timestamp_idx ON frame_observations (timestamp)',
  );
  late final Index frameSessionIdx = Index(
    'frame_session_idx',
    'CREATE INDEX frame_session_idx ON frame_observations (session_id)',
  );
  late final Index detectionTimeIdx = Index(
    'detection_time_idx',
    'CREATE INDEX detection_time_idx ON detection_events (timestamp)',
  );
  late final Index detectionFrameIdx = Index(
    'detection_frame_idx',
    'CREATE INDEX detection_frame_idx ON detection_events (frame_session_id)',
  );
  late final Index detectionConfIdx = Index(
    'detection_conf_idx',
    'CREATE INDEX detection_conf_idx ON detection_events (confidence)',
  );
  late final Index laneTimeIdx = Index(
    'lane_time_idx',
    'CREATE INDEX lane_time_idx ON lane_snapshots (timestamp)',
  );
  late final Index laneSessionIdx = Index(
    'lane_session_idx',
    'CREATE INDEX lane_session_idx ON lane_snapshots (frame_session_id)',
  );
  late final Index laneConfIdx = Index(
    'lane_conf_idx',
    'CREATE INDEX lane_conf_idx ON lane_snapshots (confidence)',
  );
  late final Index eventTimeIdx = Index(
    'event_time_idx',
    'CREATE INDEX event_time_idx ON driving_events (timestamp)',
  );
  late final Index eventSessionIdx = Index(
    'event_session_idx',
    'CREATE INDEX event_session_idx ON driving_events (session_id)',
  );
  late final Index eventTypeIdx = Index(
    'event_type_idx',
    'CREATE INDEX event_type_idx ON driving_events (event_type)',
  );
  late final Index geoRiskIdx = Index(
    'geo_risk_idx',
    'CREATE INDEX geo_risk_idx ON geo_cells (risk_score)',
  );
  late final Index geoCoordIdx = Index(
    'geo_coord_idx',
    'CREATE INDEX geo_coord_idx ON geo_cells (x, y)',
  );
  late final Index geoUpdatedIdx = Index(
    'geo_updated_idx',
    'CREATE INDEX geo_updated_idx ON geo_cells (last_updated)',
  );
  late final Index roadLocationIdx = Index(
    'road_location_idx',
    'CREATE INDEX road_location_idx ON road_segments (lat, lng)',
  );
  late final Index roadSeenIdx = Index(
    'road_seen_idx',
    'CREATE INDEX road_seen_idx ON road_segments (last_seen)',
  );
  late final Index roadTypeIdx = Index(
    'road_type_idx',
    'CREATE INDEX road_type_idx ON road_segments (road_type)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    frameObservations,
    detectionEvents,
    laneSnapshots,
    drivingEvents,
    geoCells,
    roadSegments,
    frameTimestampIdx,
    frameSessionIdx,
    detectionTimeIdx,
    detectionFrameIdx,
    detectionConfIdx,
    laneTimeIdx,
    laneSessionIdx,
    laneConfIdx,
    eventTimeIdx,
    eventSessionIdx,
    eventTypeIdx,
    geoRiskIdx,
    geoCoordIdx,
    geoUpdatedIdx,
    roadLocationIdx,
    roadSeenIdx,
    roadTypeIdx,
  ];
}

typedef $$FrameObservationsTableCreateCompanionBuilder =
    FrameObservationsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required int width,
      required int height,
      required String sessionId,
    });
typedef $$FrameObservationsTableUpdateCompanionBuilder =
    FrameObservationsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<int> width,
      Value<int> height,
      Value<String> sessionId,
    });

class $$FrameObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $FrameObservationsTable> {
  $$FrameObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FrameObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $FrameObservationsTable> {
  $$FrameObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FrameObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrameObservationsTable> {
  $$FrameObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$FrameObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrameObservationsTable,
          FrameObservation,
          $$FrameObservationsTableFilterComposer,
          $$FrameObservationsTableOrderingComposer,
          $$FrameObservationsTableAnnotationComposer,
          $$FrameObservationsTableCreateCompanionBuilder,
          $$FrameObservationsTableUpdateCompanionBuilder,
          (
            FrameObservation,
            BaseReferences<
              _$AppDatabase,
              $FrameObservationsTable,
              FrameObservation
            >,
          ),
          FrameObservation,
          PrefetchHooks Function()
        > {
  $$FrameObservationsTableTableManager(
    _$AppDatabase db,
    $FrameObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrameObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrameObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrameObservationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
              }) => FrameObservationsCompanion(
                id: id,
                timestamp: timestamp,
                width: width,
                height: height,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required int width,
                required int height,
                required String sessionId,
              }) => FrameObservationsCompanion.insert(
                id: id,
                timestamp: timestamp,
                width: width,
                height: height,
                sessionId: sessionId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FrameObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrameObservationsTable,
      FrameObservation,
      $$FrameObservationsTableFilterComposer,
      $$FrameObservationsTableOrderingComposer,
      $$FrameObservationsTableAnnotationComposer,
      $$FrameObservationsTableCreateCompanionBuilder,
      $$FrameObservationsTableUpdateCompanionBuilder,
      (
        FrameObservation,
        BaseReferences<
          _$AppDatabase,
          $FrameObservationsTable,
          FrameObservation
        >,
      ),
      FrameObservation,
      PrefetchHooks Function()
    >;
typedef $$DetectionEventsTableCreateCompanionBuilder =
    DetectionEventsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required String frameSessionId,
      required int classId,
      required String className,
      required double confidence,
      required double xMin,
      required double yMin,
      required double xMax,
      required double yMax,
      required String mask,
    });
typedef $$DetectionEventsTableUpdateCompanionBuilder =
    DetectionEventsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String> frameSessionId,
      Value<int> classId,
      Value<String> className,
      Value<double> confidence,
      Value<double> xMin,
      Value<double> yMin,
      Value<double> xMax,
      Value<double> yMax,
      Value<String> mask,
    });

class $$DetectionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DetectionEventsTable> {
  $$DetectionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get className => $composableBuilder(
    column: $table.className,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get xMin => $composableBuilder(
    column: $table.xMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yMin => $composableBuilder(
    column: $table.yMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get xMax => $composableBuilder(
    column: $table.xMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yMax => $composableBuilder(
    column: $table.yMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mask => $composableBuilder(
    column: $table.mask,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DetectionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DetectionEventsTable> {
  $$DetectionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get className => $composableBuilder(
    column: $table.className,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get xMin => $composableBuilder(
    column: $table.xMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yMin => $composableBuilder(
    column: $table.yMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get xMax => $composableBuilder(
    column: $table.xMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yMax => $composableBuilder(
    column: $table.yMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mask => $composableBuilder(
    column: $table.mask,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DetectionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetectionEventsTable> {
  $$DetectionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<String> get className =>
      $composableBuilder(column: $table.className, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get xMin =>
      $composableBuilder(column: $table.xMin, builder: (column) => column);

  GeneratedColumn<double> get yMin =>
      $composableBuilder(column: $table.yMin, builder: (column) => column);

  GeneratedColumn<double> get xMax =>
      $composableBuilder(column: $table.xMax, builder: (column) => column);

  GeneratedColumn<double> get yMax =>
      $composableBuilder(column: $table.yMax, builder: (column) => column);

  GeneratedColumn<String> get mask =>
      $composableBuilder(column: $table.mask, builder: (column) => column);
}

class $$DetectionEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetectionEventsTable,
          DetectionEvent,
          $$DetectionEventsTableFilterComposer,
          $$DetectionEventsTableOrderingComposer,
          $$DetectionEventsTableAnnotationComposer,
          $$DetectionEventsTableCreateCompanionBuilder,
          $$DetectionEventsTableUpdateCompanionBuilder,
          (
            DetectionEvent,
            BaseReferences<
              _$AppDatabase,
              $DetectionEventsTable,
              DetectionEvent
            >,
          ),
          DetectionEvent,
          PrefetchHooks Function()
        > {
  $$DetectionEventsTableTableManager(
    _$AppDatabase db,
    $DetectionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> frameSessionId = const Value.absent(),
                Value<int> classId = const Value.absent(),
                Value<String> className = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<double> xMin = const Value.absent(),
                Value<double> yMin = const Value.absent(),
                Value<double> xMax = const Value.absent(),
                Value<double> yMax = const Value.absent(),
                Value<String> mask = const Value.absent(),
              }) => DetectionEventsCompanion(
                id: id,
                timestamp: timestamp,
                frameSessionId: frameSessionId,
                classId: classId,
                className: className,
                confidence: confidence,
                xMin: xMin,
                yMin: yMin,
                xMax: xMax,
                yMax: yMax,
                mask: mask,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required String frameSessionId,
                required int classId,
                required String className,
                required double confidence,
                required double xMin,
                required double yMin,
                required double xMax,
                required double yMax,
                required String mask,
              }) => DetectionEventsCompanion.insert(
                id: id,
                timestamp: timestamp,
                frameSessionId: frameSessionId,
                classId: classId,
                className: className,
                confidence: confidence,
                xMin: xMin,
                yMin: yMin,
                xMax: xMax,
                yMax: yMax,
                mask: mask,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DetectionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetectionEventsTable,
      DetectionEvent,
      $$DetectionEventsTableFilterComposer,
      $$DetectionEventsTableOrderingComposer,
      $$DetectionEventsTableAnnotationComposer,
      $$DetectionEventsTableCreateCompanionBuilder,
      $$DetectionEventsTableUpdateCompanionBuilder,
      (
        DetectionEvent,
        BaseReferences<_$AppDatabase, $DetectionEventsTable, DetectionEvent>,
      ),
      DetectionEvent,
      PrefetchHooks Function()
    >;
typedef $$LaneSnapshotsTableCreateCompanionBuilder =
    LaneSnapshotsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      Value<String?> frameSessionId,
      required double confidence,
      required double driftScore,
      required double curvature,
      required double laneWidth,
      required String laneType,
      required String centerLine,
      required String leftBoundary,
      required String rightBoundary,
      Value<double?> latitude,
      Value<double?> longitude,
    });
typedef $$LaneSnapshotsTableUpdateCompanionBuilder =
    LaneSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String?> frameSessionId,
      Value<double> confidence,
      Value<double> driftScore,
      Value<double> curvature,
      Value<double> laneWidth,
      Value<String> laneType,
      Value<String> centerLine,
      Value<String> leftBoundary,
      Value<String> rightBoundary,
      Value<double?> latitude,
      Value<double?> longitude,
    });

class $$LaneSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $LaneSnapshotsTable> {
  $$LaneSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get driftScore => $composableBuilder(
    column: $table.driftScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get curvature => $composableBuilder(
    column: $table.curvature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get laneWidth => $composableBuilder(
    column: $table.laneWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get laneType => $composableBuilder(
    column: $table.laneType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get centerLine => $composableBuilder(
    column: $table.centerLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leftBoundary => $composableBuilder(
    column: $table.leftBoundary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rightBoundary => $composableBuilder(
    column: $table.rightBoundary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LaneSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $LaneSnapshotsTable> {
  $$LaneSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get driftScore => $composableBuilder(
    column: $table.driftScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get curvature => $composableBuilder(
    column: $table.curvature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get laneWidth => $composableBuilder(
    column: $table.laneWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get laneType => $composableBuilder(
    column: $table.laneType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get centerLine => $composableBuilder(
    column: $table.centerLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leftBoundary => $composableBuilder(
    column: $table.leftBoundary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rightBoundary => $composableBuilder(
    column: $table.rightBoundary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LaneSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LaneSnapshotsTable> {
  $$LaneSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get frameSessionId => $composableBuilder(
    column: $table.frameSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get driftScore => $composableBuilder(
    column: $table.driftScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get curvature =>
      $composableBuilder(column: $table.curvature, builder: (column) => column);

  GeneratedColumn<double> get laneWidth =>
      $composableBuilder(column: $table.laneWidth, builder: (column) => column);

  GeneratedColumn<String> get laneType =>
      $composableBuilder(column: $table.laneType, builder: (column) => column);

  GeneratedColumn<String> get centerLine => $composableBuilder(
    column: $table.centerLine,
    builder: (column) => column,
  );

  GeneratedColumn<String> get leftBoundary => $composableBuilder(
    column: $table.leftBoundary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rightBoundary => $composableBuilder(
    column: $table.rightBoundary,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$LaneSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LaneSnapshotsTable,
          LaneSnapshot,
          $$LaneSnapshotsTableFilterComposer,
          $$LaneSnapshotsTableOrderingComposer,
          $$LaneSnapshotsTableAnnotationComposer,
          $$LaneSnapshotsTableCreateCompanionBuilder,
          $$LaneSnapshotsTableUpdateCompanionBuilder,
          (
            LaneSnapshot,
            BaseReferences<_$AppDatabase, $LaneSnapshotsTable, LaneSnapshot>,
          ),
          LaneSnapshot,
          PrefetchHooks Function()
        > {
  $$LaneSnapshotsTableTableManager(_$AppDatabase db, $LaneSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LaneSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LaneSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LaneSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> frameSessionId = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<double> driftScore = const Value.absent(),
                Value<double> curvature = const Value.absent(),
                Value<double> laneWidth = const Value.absent(),
                Value<String> laneType = const Value.absent(),
                Value<String> centerLine = const Value.absent(),
                Value<String> leftBoundary = const Value.absent(),
                Value<String> rightBoundary = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
              }) => LaneSnapshotsCompanion(
                id: id,
                timestamp: timestamp,
                frameSessionId: frameSessionId,
                confidence: confidence,
                driftScore: driftScore,
                curvature: curvature,
                laneWidth: laneWidth,
                laneType: laneType,
                centerLine: centerLine,
                leftBoundary: leftBoundary,
                rightBoundary: rightBoundary,
                latitude: latitude,
                longitude: longitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                Value<String?> frameSessionId = const Value.absent(),
                required double confidence,
                required double driftScore,
                required double curvature,
                required double laneWidth,
                required String laneType,
                required String centerLine,
                required String leftBoundary,
                required String rightBoundary,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
              }) => LaneSnapshotsCompanion.insert(
                id: id,
                timestamp: timestamp,
                frameSessionId: frameSessionId,
                confidence: confidence,
                driftScore: driftScore,
                curvature: curvature,
                laneWidth: laneWidth,
                laneType: laneType,
                centerLine: centerLine,
                leftBoundary: leftBoundary,
                rightBoundary: rightBoundary,
                latitude: latitude,
                longitude: longitude,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LaneSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LaneSnapshotsTable,
      LaneSnapshot,
      $$LaneSnapshotsTableFilterComposer,
      $$LaneSnapshotsTableOrderingComposer,
      $$LaneSnapshotsTableAnnotationComposer,
      $$LaneSnapshotsTableCreateCompanionBuilder,
      $$LaneSnapshotsTableUpdateCompanionBuilder,
      (
        LaneSnapshot,
        BaseReferences<_$AppDatabase, $LaneSnapshotsTable, LaneSnapshot>,
      ),
      LaneSnapshot,
      PrefetchHooks Function()
    >;
typedef $$DrivingEventsTableCreateCompanionBuilder =
    DrivingEventsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      Value<String?> sessionId,
      required String eventType,
      required double severity,
      required double confidence,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> metadata,
    });
typedef $$DrivingEventsTableUpdateCompanionBuilder =
    DrivingEventsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String?> sessionId,
      Value<String> eventType,
      Value<double> severity,
      Value<double> confidence,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> metadata,
    });

class $$DrivingEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DrivingEventsTable> {
  $$DrivingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrivingEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrivingEventsTable> {
  $$DrivingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrivingEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrivingEventsTable> {
  $$DrivingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<double> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$DrivingEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrivingEventsTable,
          DrivingEvent,
          $$DrivingEventsTableFilterComposer,
          $$DrivingEventsTableOrderingComposer,
          $$DrivingEventsTableAnnotationComposer,
          $$DrivingEventsTableCreateCompanionBuilder,
          $$DrivingEventsTableUpdateCompanionBuilder,
          (
            DrivingEvent,
            BaseReferences<_$AppDatabase, $DrivingEventsTable, DrivingEvent>,
          ),
          DrivingEvent,
          PrefetchHooks Function()
        > {
  $$DrivingEventsTableTableManager(_$AppDatabase db, $DrivingEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrivingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrivingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrivingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<double> severity = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => DrivingEventsCompanion(
                id: id,
                timestamp: timestamp,
                sessionId: sessionId,
                eventType: eventType,
                severity: severity,
                confidence: confidence,
                latitude: latitude,
                longitude: longitude,
                metadata: metadata,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                Value<String?> sessionId = const Value.absent(),
                required String eventType,
                required double severity,
                required double confidence,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => DrivingEventsCompanion.insert(
                id: id,
                timestamp: timestamp,
                sessionId: sessionId,
                eventType: eventType,
                severity: severity,
                confidence: confidence,
                latitude: latitude,
                longitude: longitude,
                metadata: metadata,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrivingEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrivingEventsTable,
      DrivingEvent,
      $$DrivingEventsTableFilterComposer,
      $$DrivingEventsTableOrderingComposer,
      $$DrivingEventsTableAnnotationComposer,
      $$DrivingEventsTableCreateCompanionBuilder,
      $$DrivingEventsTableUpdateCompanionBuilder,
      (
        DrivingEvent,
        BaseReferences<_$AppDatabase, $DrivingEventsTable, DrivingEvent>,
      ),
      DrivingEvent,
      PrefetchHooks Function()
    >;
typedef $$GeoCellsTableCreateCompanionBuilder =
    GeoCellsCompanion Function({
      required int x,
      required int y,
      Value<double> riskScore,
      Value<double> stability,
      Value<int> sampleCount,
      required DateTime lastUpdated,
      Value<int> rowid,
    });
typedef $$GeoCellsTableUpdateCompanionBuilder =
    GeoCellsCompanion Function({
      Value<int> x,
      Value<int> y,
      Value<double> riskScore,
      Value<double> stability,
      Value<int> sampleCount,
      Value<DateTime> lastUpdated,
      Value<int> rowid,
    });

class $$GeoCellsTableFilterComposer
    extends Composer<_$AppDatabase, $GeoCellsTable> {
  $$GeoCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeoCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $GeoCellsTable> {
  $$GeoCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeoCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeoCellsTable> {
  $$GeoCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<int> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$GeoCellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GeoCellsTable,
          GeoCell,
          $$GeoCellsTableFilterComposer,
          $$GeoCellsTableOrderingComposer,
          $$GeoCellsTableAnnotationComposer,
          $$GeoCellsTableCreateCompanionBuilder,
          $$GeoCellsTableUpdateCompanionBuilder,
          (GeoCell, BaseReferences<_$AppDatabase, $GeoCellsTable, GeoCell>),
          GeoCell,
          PrefetchHooks Function()
        > {
  $$GeoCellsTableTableManager(_$AppDatabase db, $GeoCellsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeoCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeoCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeoCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> x = const Value.absent(),
                Value<int> y = const Value.absent(),
                Value<double> riskScore = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeoCellsCompanion(
                x: x,
                y: y,
                riskScore: riskScore,
                stability: stability,
                sampleCount: sampleCount,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int x,
                required int y,
                Value<double> riskScore = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                required DateTime lastUpdated,
                Value<int> rowid = const Value.absent(),
              }) => GeoCellsCompanion.insert(
                x: x,
                y: y,
                riskScore: riskScore,
                stability: stability,
                sampleCount: sampleCount,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeoCellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GeoCellsTable,
      GeoCell,
      $$GeoCellsTableFilterComposer,
      $$GeoCellsTableOrderingComposer,
      $$GeoCellsTableAnnotationComposer,
      $$GeoCellsTableCreateCompanionBuilder,
      $$GeoCellsTableUpdateCompanionBuilder,
      (GeoCell, BaseReferences<_$AppDatabase, $GeoCellsTable, GeoCell>),
      GeoCell,
      PrefetchHooks Function()
    >;
typedef $$RoadSegmentsTableCreateCompanionBuilder =
    RoadSegmentsCompanion Function({
      required String id,
      required double lat,
      required double lng,
      required double avgLaneWidth,
      required double avgCurvature,
      required double avgDrift,
      required String roadType,
      Value<int> sampleCount,
      required DateTime lastSeen,
      Value<int> rowid,
    });
typedef $$RoadSegmentsTableUpdateCompanionBuilder =
    RoadSegmentsCompanion Function({
      Value<String> id,
      Value<double> lat,
      Value<double> lng,
      Value<double> avgLaneWidth,
      Value<double> avgCurvature,
      Value<double> avgDrift,
      Value<String> roadType,
      Value<int> sampleCount,
      Value<DateTime> lastSeen,
      Value<int> rowid,
    });

class $$RoadSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RoadSegmentsTable> {
  $$RoadSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgLaneWidth => $composableBuilder(
    column: $table.avgLaneWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgCurvature => $composableBuilder(
    column: $table.avgCurvature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgDrift => $composableBuilder(
    column: $table.avgDrift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadType => $composableBuilder(
    column: $table.roadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoadSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoadSegmentsTable> {
  $$RoadSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgLaneWidth => $composableBuilder(
    column: $table.avgLaneWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgCurvature => $composableBuilder(
    column: $table.avgCurvature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgDrift => $composableBuilder(
    column: $table.avgDrift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadType => $composableBuilder(
    column: $table.roadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoadSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoadSegmentsTable> {
  $$RoadSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get avgLaneWidth => $composableBuilder(
    column: $table.avgLaneWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgCurvature => $composableBuilder(
    column: $table.avgCurvature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgDrift =>
      $composableBuilder(column: $table.avgDrift, builder: (column) => column);

  GeneratedColumn<String> get roadType =>
      $composableBuilder(column: $table.roadType, builder: (column) => column);

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);
}

class $$RoadSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoadSegmentsTable,
          RoadSegment,
          $$RoadSegmentsTableFilterComposer,
          $$RoadSegmentsTableOrderingComposer,
          $$RoadSegmentsTableAnnotationComposer,
          $$RoadSegmentsTableCreateCompanionBuilder,
          $$RoadSegmentsTableUpdateCompanionBuilder,
          (
            RoadSegment,
            BaseReferences<_$AppDatabase, $RoadSegmentsTable, RoadSegment>,
          ),
          RoadSegment,
          PrefetchHooks Function()
        > {
  $$RoadSegmentsTableTableManager(_$AppDatabase db, $RoadSegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoadSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoadSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoadSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> avgLaneWidth = const Value.absent(),
                Value<double> avgCurvature = const Value.absent(),
                Value<double> avgDrift = const Value.absent(),
                Value<String> roadType = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoadSegmentsCompanion(
                id: id,
                lat: lat,
                lng: lng,
                avgLaneWidth: avgLaneWidth,
                avgCurvature: avgCurvature,
                avgDrift: avgDrift,
                roadType: roadType,
                sampleCount: sampleCount,
                lastSeen: lastSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double lat,
                required double lng,
                required double avgLaneWidth,
                required double avgCurvature,
                required double avgDrift,
                required String roadType,
                Value<int> sampleCount = const Value.absent(),
                required DateTime lastSeen,
                Value<int> rowid = const Value.absent(),
              }) => RoadSegmentsCompanion.insert(
                id: id,
                lat: lat,
                lng: lng,
                avgLaneWidth: avgLaneWidth,
                avgCurvature: avgCurvature,
                avgDrift: avgDrift,
                roadType: roadType,
                sampleCount: sampleCount,
                lastSeen: lastSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoadSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoadSegmentsTable,
      RoadSegment,
      $$RoadSegmentsTableFilterComposer,
      $$RoadSegmentsTableOrderingComposer,
      $$RoadSegmentsTableAnnotationComposer,
      $$RoadSegmentsTableCreateCompanionBuilder,
      $$RoadSegmentsTableUpdateCompanionBuilder,
      (
        RoadSegment,
        BaseReferences<_$AppDatabase, $RoadSegmentsTable, RoadSegment>,
      ),
      RoadSegment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FrameObservationsTableTableManager get frameObservations =>
      $$FrameObservationsTableTableManager(_db, _db.frameObservations);
  $$DetectionEventsTableTableManager get detectionEvents =>
      $$DetectionEventsTableTableManager(_db, _db.detectionEvents);
  $$LaneSnapshotsTableTableManager get laneSnapshots =>
      $$LaneSnapshotsTableTableManager(_db, _db.laneSnapshots);
  $$DrivingEventsTableTableManager get drivingEvents =>
      $$DrivingEventsTableTableManager(_db, _db.drivingEvents);
  $$GeoCellsTableTableManager get geoCells =>
      $$GeoCellsTableTableManager(_db, _db.geoCells);
  $$RoadSegmentsTableTableManager get roadSegments =>
      $$RoadSegmentsTableTableManager(_db, _db.roadSegments);
}
