import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

enum DPadDirection { up, down, left, right, none }

/// A connected D-pad gesture area — one unified control surface.
/// Touch-and-drag changes direction without lifting the finger.
/// Release stops the robot.
class DPad extends StatefulWidget {
  final double size;
  final void Function(DPadDirection dir)? onPress;
  final void Function(DPadDirection dir)? onRelease;

  const DPad({super.key, this.size = 140, this.onPress, this.onRelease});

  @override
  State<DPad> createState() => _DPadState();
}

class _DPadState extends State<DPad> {
  DPadDirection _active = DPadDirection.none;

  // Dead-zone: fraction of half-size before any direction registers
  static const double _deadZone = 0.18;

  DPadDirection _directionFromOffset(Offset local) {
    final s = widget.size;
    final center = Offset(s / 2, s / 2);
    final delta = local - center;
    final dist = delta.distance;

    if (dist < s * _deadZone) return DPadDirection.none;

    final angle = atan2(
      delta.dy,
      delta.dx,
    ); // right=0, down=π/2, left=±π, up=-π/2
    if (angle >= -pi * 0.75 && angle < -pi * 0.25) return DPadDirection.up;
    if (angle >= -pi * 0.25 && angle < pi * 0.25) return DPadDirection.right;
    if (angle >= pi * 0.25 && angle < pi * 0.75) return DPadDirection.down;
    return DPadDirection.left;
  }

  void _updateFromOffset(Offset local) {
    final dir = _directionFromOffset(local);
    if (dir == _active) return;
    if (_active != DPadDirection.none) {
      widget.onRelease?.call(_active);
    }
    setState(() => _active = dir);
    if (dir != DPadDirection.none) {
      widget.onPress?.call(dir);
    }
  }

  void _endTouch() {
    if (_active != DPadDirection.none) {
      widget.onRelease?.call(_active);
    }
    setState(() => _active = DPadDirection.none);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _updateFromOffset(d.localPosition),
      onPanUpdate: (d) => _updateFromOffset(d.localPosition),
      onPanEnd: (_) => _endTouch(),
      onTapDown: (d) => _updateFromOffset(d.localPosition),
      onTapUp: (d) {
        _updateFromOffset(d.localPosition);
        _endTouch();
      },
      onTapCancel: () => _endTouch(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DPadPainter(active: _active, size: widget.size),
        ),
      ),
    );
  }
}

/// Paints the connected cross D-pad with hardware-style depth.
class _DPadPainter extends CustomPainter {
  final DPadDirection active;
  final double size;

  _DPadPainter({required this.active, required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final double arm = size * 0.31;
    final double cx = s.width / 2;
    final double cy = s.height / 2;
    final double half = arm / 2;
    const r = Radius.circular(9);

    final crossPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - half, 0, cx + half, s.height),
          r,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, cy - half, s.width, cy + half),
          r,
        ),
      );

    // ── 1. Ambient drop shadow (large, soft) ──────────────────────
    canvas.drawPath(
      crossPath.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xBB000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Crisp under-shadow for lift separation
    canvas.drawPath(
      crossPath.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── 2. Top-lit body gradient ──────────────────────────────────
    // Simulates overhead lighting: top of the cross is lighter,
    // bottom is deeper/darker (ambient occlusion on underside).
    canvas.drawPath(
      crossPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF30363F), // top face — catches overhead light
            Color(0xFF20262E), // mid body
            Color(0xFF141820), // bottom face — in shadow
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );

    // ── 3. Active arm: pressed-in look ───────────────────────────
    if (active != DPadDirection.none) {
      canvas.save();
      canvas.clipPath(crossPath);
      final armRect = _armRect(active, cx, cy, half, s);
      if (armRect != null) {
        // Pressed arm base: darker, flattened tone
        canvas.drawRect(
          armRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFF0D1016), // very dark at entry (sunk in)
                Color(0xFF161B22),
              ],
            ).createShader(armRect),
        );
        // Inner top shadow — the lip of the well casts shadow into the arm
        final innerShadowH = armRect.height * 0.35;
        canvas.drawRect(
          Rect.fromLTWH(armRect.left, armRect.top, armRect.width, innerShadowH),
          Paint()
            ..shader =
                LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0x55000000), Colors.transparent],
                ).createShader(
                  Rect.fromLTWH(
                    armRect.left,
                    armRect.top,
                    armRect.width,
                    innerShadowH,
                  ),
                ),
        );
      }
      canvas.restore();
    }

    // ── 4. Arrows ─────────────────────────────────────────────────
    _drawArrow(canvas, DPadDirection.up, cx, cy, half, s);
    _drawArrow(canvas, DPadDirection.down, cx, cy, half, s);
    _drawArrow(canvas, DPadDirection.left, cx, cy, half, s);
    _drawArrow(canvas, DPadDirection.right, cx, cy, half, s);

    // ── 5. Concave center disc ────────────────────────────────────
    // Recessed pivot in the center, looks like a bowl pressing inward.
    final discR = half * 0.60;
    final discCenter = Offset(cx, cy);
    canvas.drawCircle(
      discCenter,
      discR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, 0.3),
          radius: 1.0,
          colors: const [
            Color(0xFF0E1218), // deep center (concave bottom)
            Color(0xFF222830), // rim — slightly raised
          ],
        ).createShader(Rect.fromCircle(center: discCenter, radius: discR)),
    );
    // Disc rim highlight
    canvas.drawCircle(
      discCenter,
      discR,
      Paint()
        ..color = const Color(0xFF354050).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── 6. Top bevel highlight — only the upper edge of the cross ─
    // Simulates the raised top edge catching light.
    // Two strokes: one bright (top-lit face), one dim (side face).
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = const Color(0xFF4A5260).withAlpha(110)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Thin white specular on the very top edge
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, s.width, cy - half * 0.3));
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    // ── 7. Bottom edge shadow — underside of the cross ────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, cy + half * 0.3, s.width, s.height));
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  void _drawArrow(
    Canvas canvas,
    DPadDirection dir,
    double cx,
    double cy,
    double half,
    Size s,
  ) {
    final isActive = active == dir;
    final color = isActive
        ? ControllerTheme.textSecondary
        : ControllerTheme.textDim.withAlpha(160);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Arrow offset from center
    final offset = s.width * 0.26;
    double ax = cx, ay = cy;

    switch (dir) {
      case DPadDirection.up:
        ay = cy - offset;
        _drawTriangle(canvas, Offset(ax, ay), dir, half * 0.28, paint);
        break;
      case DPadDirection.down:
        ay = cy + offset;
        _drawTriangle(canvas, Offset(ax, ay), dir, half * 0.28, paint);
        break;
      case DPadDirection.left:
        ax = cx - offset;
        _drawTriangle(canvas, Offset(ax, ay), dir, half * 0.28, paint);
        break;
      case DPadDirection.right:
        ax = cx + offset;
        _drawTriangle(canvas, Offset(ax, ay), dir, half * 0.28, paint);
        break;
      default:
        break;
    }
  }

  void _drawTriangle(
    Canvas canvas,
    Offset center,
    DPadDirection dir,
    double sz,
    Paint paint,
  ) {
    final path = Path();
    switch (dir) {
      case DPadDirection.up:
        path.moveTo(center.dx, center.dy - sz);
        path.lineTo(center.dx - sz, center.dy + sz * 0.6);
        path.lineTo(center.dx + sz, center.dy + sz * 0.6);
        break;
      case DPadDirection.down:
        path.moveTo(center.dx, center.dy + sz);
        path.lineTo(center.dx - sz, center.dy - sz * 0.6);
        path.lineTo(center.dx + sz, center.dy - sz * 0.6);
        break;
      case DPadDirection.left:
        path.moveTo(center.dx - sz, center.dy);
        path.lineTo(center.dx + sz * 0.6, center.dy - sz);
        path.lineTo(center.dx + sz * 0.6, center.dy + sz);
        break;
      case DPadDirection.right:
        path.moveTo(center.dx + sz, center.dy);
        path.lineTo(center.dx - sz * 0.6, center.dy - sz);
        path.lineTo(center.dx - sz * 0.6, center.dy + sz);
        break;
      default:
        return;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  Rect? _armRect(DPadDirection dir, double cx, double cy, double half, Size s) {
    switch (dir) {
      case DPadDirection.up:
        return Rect.fromLTRB(cx - half, 0, cx + half, cy - half);
      case DPadDirection.down:
        return Rect.fromLTRB(cx - half, cy + half, cx + half, s.height);
      case DPadDirection.left:
        return Rect.fromLTRB(0, cy - half, cx - half, cy + half);
      case DPadDirection.right:
        return Rect.fromLTRB(cx + half, cy - half, s.width, cy + half);
      default:
        return null;
    }
  }

  @override
  bool shouldRepaint(_DPadPainter old) => old.active != active;
}
