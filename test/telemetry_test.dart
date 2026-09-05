import 'package:flutter_test/flutter_test.dart';
import 'package:bot_controller/core/models/telemetry.dart';

void main() {
  group('Telemetry Parsing & Merging Tests', () {
    test('Parses batteryPercent correctly from ESP32 telemetry JSON', () {
      final json = {'batteryPercent': 72};
      final telemetry = Telemetry.fromJson(json);

      expect(telemetry.batteryPercent, equals(72.0));
      expect(telemetry.batteryPercent?.toInt(), equals(72));
    });

    test('Clamps batteryPercent within 0-100 range', () {
      final jsonLow = {'batteryPercent': -15};
      final telemetryLow = Telemetry.fromJson(jsonLow);
      expect(telemetryLow.batteryPercent, equals(0.0));

      final jsonHigh = {'batteryPercent': 150};
      final telemetryHigh = Telemetry.fromJson(jsonHigh);
      expect(telemetryHigh.batteryPercent, equals(100.0));
    });

    test('copyWithJson preserves existing fields while updating batteryPercent', () {
      final initial = Telemetry(
        wifiRSSI: -65,
        servos: [1500, 1500, 1500, 1500, 1500, 1500],
      );

      final updateJson = {'batteryPercent': 85};
      final updated = initial.copyWithJson(updateJson);

      expect(updated.batteryPercent, equals(85.0));
      expect(updated.wifiRSSI, equals(-65));
      expect(updated.servos, equals([1500, 1500, 1500, 1500, 1500, 1500]));
    });

    test('Parses GpsData correctly from ESP32 telemetry JSON', () {
      final json = {
        'gps': {
          'valid': true,
          'lat': 22.476097,
          'lng': 88.414935,
          'alt': 11.2,
          'speed': 1.5,
          'sats': 8,
          'hdop': 0.9,
        }
      };
      final telemetry = Telemetry.fromJson(json);

      expect(telemetry.gps, isNotNull);
      expect(telemetry.gps!.valid, isTrue);
      expect(telemetry.gps!.lat, closeTo(22.476097, 0.0001));
      expect(telemetry.gps!.lng, closeTo(88.414935, 0.0001));
      expect(telemetry.gps!.sats, equals(8));
    });

    test('Computes 2S 18650 battery percent from batteryVoltage correctly', () {
      // 8.0V = 100%
      final tFull = Telemetry.fromJson({'batteryVoltage': 8.0});
      expect(tFull.batteryPercent, equals(100.0));
      expect(tFull.batteryVoltage, equals(8.0));

      // 7.0V = 50%
      final tHalf = Telemetry.fromJson({'batteryVoltage': 7.0});
      expect(tHalf.batteryPercent, equals(50.0));
      expect(tHalf.batteryVoltage, equals(7.0));

      // 6.0V = 0%
      final tEmpty = Telemetry.fromJson({'batteryVoltage': 6.0});
      expect(tEmpty.batteryPercent, equals(0.0));
      expect(tEmpty.batteryVoltage, equals(6.0));

      // > 8.0V clamped to 100%
      final tOver = Telemetry.fromJson({'batteryVoltage': 8.4});
      expect(tOver.batteryPercent, equals(100.0));

      // < 6.0V clamped to 0%
      final tUnder = Telemetry.fromJson({'batteryVoltage': 5.5});
      expect(tUnder.batteryPercent, equals(0.0));
    });

    test('copyWith preserves and updates battery percent and voltage', () {
      final t = Telemetry(batteryPercent: 80.0, batteryVoltage: 7.6);
      final updated = t.copyWith(batteryPercent: 90.0, batteryVoltage: 7.8);
      expect(updated.batteryPercent, equals(90.0));
      expect(updated.batteryVoltage, equals(7.8));
    });
  });
}
