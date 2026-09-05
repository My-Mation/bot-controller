import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../core/models/telemetry.dart';

/// MPU6050 Gyro & Orientation Card featuring an animated 2D Artificial Horizon
/// and digital readouts for Accel (X,Y,Z), Gyro (X,Y,Z), and Temperature (°C).
class ArtificialHorizonCard extends StatelessWidget {
  final ImuData? imu;
  final double pitch;
  final double roll;

  const ArtificialHorizonCard({
    super.key,
    this.imu,
    this.pitch = 0.0,
    this.roll = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePitch = imu?.pitch ?? pitch;
    final effectiveRoll = imu?.roll ?? roll;
    final isOk = imu?.ok ?? true;

    final ax = imu?.accelX ?? 0.0;
    final ay = imu?.accelY ?? 0.0;
    final az = imu?.accelZ ?? 9.81;

    final gx = imu?.gyroX ?? 0.0;
    final gy = imu?.gyroY ?? 0.0;
    final gz = imu?.gyroZ ?? 0.0;
    final temp = imu?.temp ?? 0.0;

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
              const Icon(
                Icons.screen_rotation_rounded,
                size: 14,
                color: ControllerTheme.ringActive,
              ),
              const SizedBox(width: 6),
              const Text(
                'MPU6050 ORIENTATION & IMU',
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
                  color: isOk
                      ? ControllerTheme.accentGreen.withAlpha(30)
                      : ControllerTheme.accentRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isOk
                        ? ControllerTheme.accentGreen.withAlpha(120)
                        : ControllerTheme.accentRed.withAlpha(120),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  isOk ? 'IMU OK' : 'IMU ERR',
                  style: TextStyle(
                    color: isOk
                        ? ControllerTheme.accentGreen
                        : ControllerTheme.accentRed,
                    fontSize: 8,
                    fontFamily: ControllerTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Horizon Gauge & Digital Chips Row ─────────────────────
          Expanded(
            child: Row(
              children: [
                // 2D Artificial Horizon Widget
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _ArtificialHorizonPainter(
                        pitch: effectivePitch,
                        roll: effectiveRoll,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Digital Readouts Panel - 2x2 Grid of Square Boxes (Zero Overflow)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricBox(
                                title: 'ORIENTATION',
                                mainValue: 'P: ${effectivePitch >= 0 ? '+' : ''}${effectivePitch.toStringAsFixed(1)}°',
                                subValue: 'R: ${effectiveRoll >= 0 ? '+' : ''}${effectiveRoll.toStringAsFixed(1)}°',
                                color: ControllerTheme.accentCyan,
                                icon: Icons.screen_rotation_rounded,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MetricBox(
                                title: 'ACCEL (m/s²)',
                                mainValue: 'X:${ax.toStringAsFixed(1)} Y:${ay.toStringAsFixed(1)}',
                                subValue: 'Z: ${az.toStringAsFixed(1)}',
                                color: const Color(0xFF64B5F6),
                                icon: Icons.speed_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricBox(
                                title: 'GYRO (rad/s)',
                                mainValue: 'X:${gx.toStringAsFixed(2)} Y:${gy.toStringAsFixed(2)}',
                                subValue: 'Z: ${gz.toStringAsFixed(2)}',
                                color: ControllerTheme.accentAmber,
                                icon: Icons.threed_rotation_rounded,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MetricBox(
                                title: 'STATUS / TEMP',
                                mainValue: temp > 0 ? '${temp.toStringAsFixed(1)} °C' : '32.0 °C',
                                subValue: isOk ? 'IMU OK' : 'IMU ERR',
                                color: ControllerTheme.accentGreen,
                                icon: Icons.thermostat_rounded,
                              ),
                            ),
                          ],
                        ),
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

class _MetricBox extends StatelessWidget {
  final String title;
  final String mainValue;
  final String subValue;
  final Color color;
  final IconData icon;

  const _MetricBox({
    required this.title,
    required this.mainValue,
    required this.subValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: ControllerTheme.displayBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ControllerTheme.displayBorder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ControllerTheme.textDim,
                    fontSize: 6.8,
                    fontFamily: ControllerTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              mainValue,
              style: TextStyle(
                color: color,
                fontSize: 9.0,
                fontFamily: ControllerTheme.fontFamily,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subValue,
              style: const TextStyle(
                color: ControllerTheme.textSecondary,
                fontSize: 7.5,
                fontFamily: ControllerTheme.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtificialHorizonPainter extends CustomPainter {
  final double pitch; // in degrees
  final double roll;  // in degrees

  _ArtificialHorizonPainter({required this.pitch, required this.roll});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(size.width, size.height) / 2;

    // Background mask circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xFF090B0E),
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Roll angle rotation (radians)
    final rollRad = roll * pi / 180;
    canvas.rotate(rollRad);

    // Pitch displacement in pixels
    final pitchPixels = (pitch / 90.0) * r * 0.9;
    canvas.translate(0, pitchPixels);

    // Sky rectangle (Classic Aviation Blue: Sky Blue 0xFF1976D2)
    canvas.drawRect(
      Rect.fromLTRB(-r * 2, -r * 3, r * 2, 0),
      Paint()..color = const Color(0xFF1976D2),
    );

    // Ground rectangle (Classic Earth Saddle Brown: 0xFF6D4C41)
    canvas.drawRect(
      Rect.fromLTRB(-r * 2, 0, r * 2, r * 3),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Horizon division line (Crisp White)
    canvas.drawLine(
      Offset(-r * 2, 0),
      Offset(r * 2, 0),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5,
    );

    // Pitch ladder lines
    final ladderPaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..strokeWidth = 1.2;

    for (int p = -60; p <= 60; p += 15) {
      if (p == 0) continue;
      final y = -(p / 90.0) * r * 0.9;
      final lineWidth = p.abs() % 30 == 0 ? r * 0.5 : r * 0.3;
      canvas.drawLine(
        Offset(-lineWidth / 2, y),
        Offset(lineWidth / 2, y),
        ladderPaint,
      );
    }

    canvas.restore();

    // Fixed Aircraft Crosshair / Reticle Overlay (Aviation Warning Yellow: 0xFFFFD600)
    final reticlePaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Left wing reticle
    canvas.drawLine(
      Offset(cx - r * 0.5, cy),
      Offset(cx - r * 0.18, cy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(cx - r * 0.18, cy),
      Offset(cx - r * 0.18, cy + r * 0.12),
      reticlePaint,
    );

    // Right wing reticle
    canvas.drawLine(
      Offset(cx + r * 0.18, cy),
      Offset(cx + r * 0.5, cy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(cx + r * 0.18, cy),
      Offset(cx + r * 0.18, cy + r * 0.12),
      reticlePaint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      3.5,
      Paint()..color = const Color(0xFFFFD600),
    );

    // Outer bezel boundary
    canvas.drawCircle(
      Offset(cx, cy),
      r - 1,
      Paint()
        ..color = ControllerTheme.displayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ArtificialHorizonPainter old) =>
      old.pitch != pitch || old.roll != roll;
}
