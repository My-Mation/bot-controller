import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../core/models/telemetry.dart';

/// GY-GPS6MV2 GPS Location & Mapping Card
/// Displays live GPS fix status, coordinates, satellite count, speed, HDOP,
/// and an integrated Flutter Map pinned at gps.lat, gps.lng.
class GpsMapCard extends StatelessWidget {
  final GpsData? gps;
  final Telemetry? telemetry;

  /// Default coordinates: Netaji Subhash Engineering College (NSEC), Garia, Kolkata
  /// OSM Way 359466945: 22.476097° N, 88.414935° E
  static const double nsecLat = 22.476097;
  static const double nsecLng = 88.414935;
  static const String defaultLocation = 'NSEC, Garia';

  const GpsMapCard({super.key, this.gps, this.telemetry});

  @override
  Widget build(BuildContext context) {
    final hasFix = gps != null && gps!.valid && gps!.lat != 0.0 && gps!.lng != 0.0;
    final lat = hasFix ? gps!.lat : nsecLat;
    final lng = hasFix ? gps!.lng : nsecLng;
    final alt = (gps != null && gps!.alt != 0.0) ? gps!.alt : 11.0;
    final gpsSpeed = gps?.speed ?? 0.0;
    final sats = gps?.sats ?? 0;
    final hdop = (gps != null && gps!.hdop != 0.0) ? gps!.hdop : (hasFix ? 0.0 : 1.0);

    // Calculate dynamic motion speed from IMU accelerometer & gyro when GPS speed is 0
    final imuData = telemetry?.imu;
    final ax = imuData?.accelX ?? telemetry?.accelX ?? 0.0;
    final ay = imuData?.accelY ?? telemetry?.accelY ?? 0.0;
    final az = imuData?.accelZ ?? telemetry?.accelZ ?? 9.81;
    final gx = (imuData?.gyroX ?? telemetry?.gyroX ?? 0.0).abs();
    final gy = (imuData?.gyroY ?? telemetry?.gyroY ?? 0.0).abs();
    final gz = (imuData?.gyroZ ?? telemetry?.gyroZ ?? 0.0).abs();

    final netAccel = sqrt(ax * ax + ay * ay + (az - 9.81) * (az - 9.81));
    final gyroMotion = (gx + gy + gz) * 0.5;
    final calculatedImuSpeed = ((netAccel * 1.8) + (gyroMotion * 0.8)).clamp(0.0, 45.0);

    String displaySpeedText;
    if (gpsSpeed > 0.1) {
      displaySpeedText = '${gpsSpeed.toStringAsFixed(1)} km/h';
    } else if (calculatedImuSpeed > 0.1) {
      displaySpeedText = '${calculatedImuSpeed.toStringAsFixed(1)} km/h (IMU)';
    } else {
      displaySpeedText = '0.0 km/h';
    }

    final targetPoint = LatLng(lat, lng);

    return Container(
      decoration: BoxDecoration(
        color: ControllerTheme.shellDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ControllerTheme.displayBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Bar ─────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.satellite_alt_rounded,
                size: 14,
                color: ControllerTheme.accentCyan,
              ),

              const SizedBox(width: 6),
              const Text(
                'GY-GPS6MV2 LOCATION',
                style: TextStyle(
                  color: ControllerTheme.textSecondary,
                  fontSize: 10,
                  fontFamily: ControllerTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasFix
                      ? ControllerTheme.accentGreen.withAlpha(30)
                      : ControllerTheme.accentAmber.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasFix
                        ? ControllerTheme.accentGreen.withAlpha(120)
                        : ControllerTheme.accentAmber.withAlpha(120),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasFix
                            ? ControllerTheme.accentGreen
                            : ControllerTheme.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFix ? 'VALID FIX' : 'NSEC (STANDBY)',
                      style: TextStyle(
                        color: hasFix
                            ? ControllerTheme.accentGreen
                            : ControllerTheme.accentAmber,
                        fontSize: 8,
                        fontFamily: ControllerTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Map View & GPS Data Column ─────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Interactive Map View
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: targetPoint,
                            initialZoom: 16.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.robot.bot_controller',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: targetPoint,
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ControllerTheme.accentRed.withAlpha(180),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ControllerTheme.accentRed.withAlpha(120),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.smart_toy_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Coordinates Overlay Chip on Map
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: ControllerTheme.displayBg.withAlpha(230),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ControllerTheme.displayBorder,
                                width: 0.6,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasFix ? Icons.gps_fixed_rounded : Icons.school_rounded,
                                      size: 9,
                                      color: hasFix
                                          ? ControllerTheme.accentGreen
                                          : ControllerTheme.accentAmber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasFix ? 'LIVE FIX' : 'NSEC Garia (Default)',
                                      style: TextStyle(
                                        color: hasFix
                                            ? ControllerTheme.accentGreen
                                            : ControllerTheme.accentAmber,
                                        fontSize: 7.5,
                                        fontFamily: ControllerTheme.fontFamily,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: ControllerTheme.accentCyan,
                                    fontSize: 8,
                                    fontFamily: ControllerTheme.fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // GPS Telemetry Badges
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _GpsInfoChip(
                        label: 'SATS',
                        value: hasFix ? '$sats connected' : '$sats (Standby)',
                        icon: Icons.satellite_rounded,
                      ),
                      _GpsInfoChip(
                        label: 'SPEED',
                        value: displaySpeedText,
                        icon: Icons.speed_rounded,
                      ),
                      _GpsInfoChip(
                        label: 'ALTITUDE',
                        value: hasFix ? '${alt.toStringAsFixed(1)} m' : '${alt.toStringAsFixed(1)} m (NSEC)',
                        icon: Icons.height_rounded,
                      ),
                      _GpsInfoChip(
                        label: 'HDOP',
                        value: hasFix ? hdop.toStringAsFixed(1) : (hdop > 0 ? hdop.toStringAsFixed(1) : '1.0'),
                        icon: Icons.precision_manufacturing_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GpsInfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: ControllerTheme.displayBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ControllerTheme.displayBorder, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: ControllerTheme.textDim),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ControllerTheme.textDim,
                    fontSize: 7,
                    fontFamily: ControllerTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: ControllerTheme.textSecondary,
                      fontSize: 8.5,
                      fontFamily: ControllerTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
