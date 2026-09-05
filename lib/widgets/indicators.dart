import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Circular tilt indicator showing X/Y tilt as a dot offset within
/// a bounded circle. Purely visual / animated demo values.
class TiltIndicator extends StatefulWidget {
  final double size;
  final double tiltX; // -1.0 to 1.0
  final double tiltY; // -1.0 to 1.0

  const TiltIndicator({
    super.key,
    this.size = 72,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
  });

  @override
  State<TiltIndicator> createState() => _TiltIndicatorState();
}

class _TiltIndicatorState extends State<TiltIndicator> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _TiltPainter(tiltX: widget.tiltX, tiltY: widget.tiltY),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'TILT',
          style: TextStyle(
            color: ControllerTheme.textDim,
            fontSize: 9,
            fontFamily: ControllerTheme.fontFamily,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TiltPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;

  _TiltPainter({required this.tiltX, required this.tiltY});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 4;
    final dotR = r * 0.16;
    final maxOffset = r - dotR - 4;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = ControllerTheme.shellDeep,
    );

    // Subtle ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = ControllerTheme.displayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Cross-hair lines
    final hairPaint = Paint()
      ..color = ControllerTheme.textDim.withAlpha(50)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(cx - r * 0.7, cy),
      Offset(cx + r * 0.7, cy),
      hairPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - r * 0.7),
      Offset(cx, cy + r * 0.7),
      hairPaint,
    );

    // Inner safe zone ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()
        ..color = ControllerTheme.textDim.withAlpha(25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Dot offset
    final clampedX = tiltX.clamp(-1.0, 1.0);
    final clampedY = tiltY.clamp(-1.0, 1.0);
    final dx = clampedX * maxOffset;
    final dy = clampedY * maxOffset;

    // Glow
    canvas.drawCircle(
      Offset(cx + dx, cy + dy),
      dotR * 2,
      Paint()
        ..color = ControllerTheme.ringActive.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Dot
    canvas.drawCircle(
      Offset(cx + dx, cy + dy),
      dotR,
      Paint()..color = ControllerTheme.ringActive,
    );

    // Dot highlight
    canvas.drawCircle(
      Offset(cx + dx - dotR * 0.25, cy + dy - dotR * 0.25),
      dotR * 0.35,
      Paint()..color = ControllerTheme.textSecondary.withAlpha(120),
    );
  }

  @override
  bool shouldRepaint(_TiltPainter old) =>
      old.tiltX != tiltX || old.tiltY != tiltY;
}

/// Circular acceleration indicator.
/// Center dot = XY acceleration, outer ring = Z-axis linear indicator.
class AccelIndicator extends StatefulWidget {
  final double size;
  final double accelX; // -1.0 to 1.0
  final double accelY; // -1.0 to 1.0
  final double accelZ; // 0.0 to 1.0 (magnitude for ring fill)

  const AccelIndicator({
    super.key,
    this.size = 72,
    this.accelX = 0.0,
    this.accelY = 0.0,
    this.accelZ = 0.0,
  });

  @override
  State<AccelIndicator> createState() => _AccelIndicatorState();
}

class _AccelIndicatorState extends State<AccelIndicator> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AccelPainter(
              accelX: widget.accelX,
              accelY: widget.accelY,
              accelZ: widget.accelZ,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ACCEL',
          style: TextStyle(
            color: ControllerTheme.textDim,
            fontSize: 9,
            fontFamily: ControllerTheme.fontFamily,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AccelPainter extends CustomPainter {
  final double accelX;
  final double accelY;
  final double accelZ;

  _AccelPainter({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = cx - 2;
    final ringWidth = outerR * 0.14;
    final innerR = outerR - ringWidth - 2;
    final dotR = innerR * 0.18;
    final maxOffset = innerR - dotR - 3;

    // Background
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()..color = ControllerTheme.shellDeep,
    );

    // Z-axis ring background
    canvas.drawCircle(
      Offset(cx, cy),
      outerR - ringWidth / 2,
      Paint()
        ..color = ControllerTheme.ringInactive
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );

    // Z-axis ring fill arc
    final zClamped = accelZ.clamp(-1.0, 1.0);
    if (zClamped.abs() > 0.05) { // Add small deadband
      final arcPaint = Paint()
        ..color = ControllerTheme.accentRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      // If > 0 (moving up), draw counter-clockwise (left). If < 0 (falling), draw clockwise (right)
      double sweepAngle = zClamped > 0 ? -pi * zClamped.abs() : pi * zClamped.abs();

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR - ringWidth / 2),
        -pi / 2, // Start at top
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // Outer ring border
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..color = ControllerTheme.displayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Inner circle
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = ControllerTheme.dpadCenter,
    );

    // Cross-hair
    final hairPaint = Paint()
      ..color = ControllerTheme.textDim.withAlpha(50)
      ..strokeWidth = 0.7;
    canvas.drawLine(
      Offset(cx - innerR * 0.75, cy),
      Offset(cx + innerR * 0.75, cy),
      hairPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - innerR * 0.75),
      Offset(cx, cy + innerR * 0.75),
      hairPaint,
    );

    // XY dot
    final clampedX = accelX.clamp(-1.0, 1.0);
    final clampedY = accelY.clamp(-1.0, 1.0);
    final dx = clampedX * maxOffset;
    final dy = clampedY * maxOffset;

    canvas.drawCircle(
      Offset(cx + dx, cy + dy),
      dotR * 1.8,
      Paint()
        ..color = ControllerTheme.accentBlue.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(cx + dx, cy + dy),
      dotR,
      Paint()..color = ControllerTheme.accentBlue.withAlpha(220),
    );
  }

  @override
  bool shouldRepaint(_AccelPainter old) =>
      old.accelX != accelX || old.accelY != accelY || old.accelZ != accelZ;
}
