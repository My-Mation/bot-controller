class ImuData {
  final bool ok;
  final double pitch;
  final double roll;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double temp;

  ImuData({
    this.ok = false,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.accelX = 0.0,
    this.accelY = 0.0,
    this.accelZ = 9.81,
    this.gyroX = 0.0,
    this.gyroY = 0.0,
    this.gyroZ = 0.0,
    this.temp = 0.0,
  });

  factory ImuData.fromJson(Map<String, dynamic> json) {
    return ImuData(
      ok: json['ok'] as bool? ?? false,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      roll: (json['roll'] as num?)?.toDouble() ?? 0.0,
      accelX: (json['accelX'] as num?)?.toDouble() ?? 0.0,
      accelY: (json['accelY'] as num?)?.toDouble() ?? 0.0,
      accelZ: (json['accelZ'] as num?)?.toDouble() ?? 9.81,
      gyroX: (json['gyroX'] as num?)?.toDouble() ?? 0.0,
      gyroY: (json['gyroY'] as num?)?.toDouble() ?? 0.0,
      gyroZ: (json['gyroZ'] as num?)?.toDouble() ?? 0.0,
      temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GpsData {
  final bool valid;
  final double lat;
  final double lng;
  final double alt;
  final double speed;
  final int sats;
  final double hdop;

  GpsData({
    this.valid = false,
    this.lat = 0.0,
    this.lng = 0.0,
    this.alt = 0.0,
    this.speed = 0.0,
    this.sats = 0,
    this.hdop = 0.0,
  });

  factory GpsData.fromJson(Map<String, dynamic> json) {
    return GpsData(
      valid: json['valid'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      alt: (json['alt'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      sats: json['sats'] as int? ?? 0,
      hdop: (json['hdop'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Telemetry {
  final double? batteryPercent;
  final double? batteryVoltage;
  final bool light;
  final double? roll;
  final double? pitch;
  final double? yaw;
  final bool? yawSupported;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final ImuData? imu;
  final GpsData? gps;
  final int? queue;
  final bool? moving;
  final int? wifiRSSI;
  final List<int>? servos;

  Telemetry({
    this.batteryPercent,
    this.batteryVoltage,
    this.light = false,
    this.roll,
    this.pitch,
    this.yaw,
    this.yawSupported,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.imu,
    this.gps,
    this.queue,
    this.moving,
    this.wifiRSSI,
    this.servos,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    ImuData? imuObj;
    if (json['imu'] != null && json['imu'] is Map<String, dynamic>) {
      imuObj = ImuData.fromJson(json['imu'] as Map<String, dynamic>);
    }

    GpsData? gpsObj;
    if (json['gps'] != null && json['gps'] is Map<String, dynamic>) {
      gpsObj = GpsData.fromJson(json['gps'] as Map<String, dynamic>);
    }

    double? rawVoltage = (json['batteryVoltage'] as num?)?.toDouble();
    double? rawBattery = (json['batteryPercent'] as num?)?.toDouble();
    if (rawBattery == null && rawVoltage != null && rawVoltage > 0.0) {
      rawBattery = ((rawVoltage - 4.5) / 3.6 * 100.0).clamp(0.0, 100.0);
    }

    return Telemetry(
      batteryPercent: rawBattery?.clamp(0.0, 100.0),
      batteryVoltage: rawVoltage,
      light: json['light'] as bool? ?? false,
      roll: (json['roll'] as num?)?.toDouble() ?? imuObj?.roll,
      pitch: (json['pitch'] as num?)?.toDouble() ?? imuObj?.pitch,
      yaw: (json['yaw'] as num?)?.toDouble(),
      yawSupported: json['yawSupported'] as bool?,
      accelX: (json['accelX'] as num?)?.toDouble() ?? imuObj?.accelX,
      accelY: (json['accelY'] as num?)?.toDouble() ?? imuObj?.accelY,
      accelZ: (json['accelZ'] as num?)?.toDouble() ?? imuObj?.accelZ,
      gyroX: (json['gyroX'] as num?)?.toDouble() ?? imuObj?.gyroX,
      gyroY: (json['gyroY'] as num?)?.toDouble() ?? imuObj?.gyroY,
      gyroZ: (json['gyroZ'] as num?)?.toDouble() ?? imuObj?.gyroZ,
      imu: imuObj,
      gps: gpsObj,
      queue: json['queue'] as int?,
      moving: json['moving'] as bool?,
      wifiRSSI: json['wifiRSSI'] as int?,
      servos: (json['servos'] as List?)?.cast<int>(),
    );
  }

  Telemetry copyWithJson(Map<String, dynamic> json) {
    ImuData? imuObj = json['imu'] != null && json['imu'] is Map<String, dynamic>
        ? ImuData.fromJson(json['imu'] as Map<String, dynamic>)
        : imu;

    GpsData? gpsObj = json['gps'] != null && json['gps'] is Map<String, dynamic>
        ? GpsData.fromJson(json['gps'] as Map<String, dynamic>)
        : gps;

    double? rawVoltage = json.containsKey('batteryVoltage')
        ? (json['batteryVoltage'] as num?)?.toDouble()
        : batteryVoltage;

    double? rawBattery = json.containsKey('batteryPercent')
        ? (json['batteryPercent'] as num?)?.toDouble()
        : (batteryPercent ?? (rawVoltage != null && rawVoltage > 0.0 ? ((rawVoltage - 4.5) / 3.6 * 100.0).clamp(0.0, 100.0) : null));

    if (json.containsKey('batteryVoltage') && !json.containsKey('batteryPercent') && rawVoltage != null && rawVoltage > 0.0) {
      rawBattery = ((rawVoltage - 4.5) / 3.6 * 100.0).clamp(0.0, 100.0);
    }

    return Telemetry(
      batteryPercent: rawBattery?.clamp(0.0, 100.0),
      batteryVoltage: rawVoltage,
      light: json.containsKey('light') ? (json['light'] as bool? ?? false) : light,
      roll: json.containsKey('roll')
          ? (json['roll'] as num?)?.toDouble()
          : (imuObj?.roll ?? roll),
      pitch: json.containsKey('pitch')
          ? (json['pitch'] as num?)?.toDouble()
          : (imuObj?.pitch ?? pitch),
      yaw: json.containsKey('yaw') ? (json['yaw'] as num?)?.toDouble() : yaw,
      yawSupported: json.containsKey('yawSupported')
          ? json['yawSupported'] as bool?
          : yawSupported,
      accelX: json.containsKey('accelX')
          ? (json['accelX'] as num?)?.toDouble()
          : (imuObj?.accelX ?? accelX),
      accelY: json.containsKey('accelY')
          ? (json['accelY'] as num?)?.toDouble()
          : (imuObj?.accelY ?? accelY),
      accelZ: json.containsKey('accelZ')
          ? (json['accelZ'] as num?)?.toDouble()
          : (imuObj?.accelZ ?? accelZ),
      gyroX: json.containsKey('gyroX')
          ? (json['gyroX'] as num?)?.toDouble()
          : (imuObj?.gyroX ?? gyroX),
      gyroY: json.containsKey('gyroY')
          ? (json['gyroY'] as num?)?.toDouble()
          : (imuObj?.gyroY ?? gyroY),
      gyroZ: json.containsKey('gyroZ')
          ? (json['gyroZ'] as num?)?.toDouble()
          : (imuObj?.gyroZ ?? gyroZ),
      imu: imuObj,
      gps: gpsObj,
      queue: json.containsKey('queue') ? json['queue'] as int? : queue,
      moving: json.containsKey('moving') ? json['moving'] as bool? : moving,
      wifiRSSI: json.containsKey('wifiRSSI') ? json['wifiRSSI'] as int? : wifiRSSI,
      servos: json.containsKey('servos')
          ? (json['servos'] as List?)?.cast<int>()
          : servos,
    );
  }

  Telemetry copyWith({
    double? batteryPercent,
    double? batteryVoltage,
    bool? light,
    double? roll,
    double? pitch,
    double? yaw,
    bool? yawSupported,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    ImuData? imu,
    GpsData? gps,
    int? queue,
    bool? moving,
    int? wifiRSSI,
    List<int>? servos,
  }) {
    return Telemetry(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      light: light ?? this.light,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      yawSupported: yawSupported ?? this.yawSupported,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      imu: imu ?? this.imu,
      gps: gps ?? this.gps,
      queue: queue ?? this.queue,
      moving: moving ?? this.moving,
      wifiRSSI: wifiRSSI ?? this.wifiRSSI,
      servos: servos ?? this.servos,
    );
  }
}

