import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A tactile hardware-style button with a concave face, rim highlight,
/// and a press-down depth animation — similar to Xbox / Steam Deck buttons.
class PressableButton extends StatefulWidget {
  final double size;
  final Widget? child;
  final VoidCallback? onPress;
  final VoidCallback? onRelease;
  final String? label;

  const PressableButton({
    super.key,
    this.size = 48,
    this.child,
    this.onPress,
    this.onRelease,
    this.label,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onPress?.call();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onRelease?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onRelease?.call();
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 55),
          curve: Curves.easeOut,
          // Simulate 2-3px physical press-down
          transform: _pressed
              ? (Matrix4.translationValues(0, 2.5, 0))
              : Matrix4.identity(),
          child: CustomPaint(
            painter: _HardwareButtonPainter(pressed: _pressed),
            child: Center(
              child:
                  widget.child ??
                  (widget.label != null
                      ? Text(
                          widget.label!,
                          style: TextStyle(
                            color: _pressed
                                ? ControllerTheme.textDim
                                : ControllerTheme.textSecondary,
                            fontSize: widget.size * 0.27,
                            fontFamily: ControllerTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            height: 1.0,
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a concave-faced hardware button:
/// - Outer bezel ring (slightly raised)
/// - Concave face (darker centre, lighter rim)
/// - Top-left specular highlight arc
/// - Bottom shadow arc
/// - Press state flattens the concavity and removes specular
class _HardwareButtonPainter extends CustomPainter {
  final bool pressed;

  _HardwareButtonPainter({required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // ── 1. Drop shadow (under the button body) ────────────────────
    if (!pressed) {
      canvas.drawCircle(
        center + const Offset(0, 3.5),
        r,
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // ── 2. Outer raised bezel ring ────────────────────────────────
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF141618));
    // Top highlight on bezel edge
    if (!pressed) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 0.5),
        -pi * 0.85,
        pi * 0.9,
        false,
        Paint()
          ..color = const Color(0xFF3A3F46)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // ── 3. Concave face ───────────────────────────────────────────
    final faceR = r * 0.87;
    final faceShader = RadialGradient(
      center: const Alignment(0.15, 0.2),
      radius: 1.0,
      colors: pressed
          ? [
              const Color(0xFF1A1D21), // pressed: flat, uniform dark
              const Color(0xFF22262B),
            ]
          : [
              const Color(0xFF1E2228), // concave center: darker
              const Color(0xFF2C3038), // concave rim: lighter
            ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: faceR));

    canvas.drawCircle(center, faceR, Paint()..shader = faceShader);

    // ── 4. Specular highlight arc (top-left, disappears when pressed) ─
    if (!pressed) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: faceR * 0.78),
        -pi * 0.9,
        pi * 0.6,
        false,
        Paint()
          ..color = const Color(0x18FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 5. Bottom inner shadow arc ────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: faceR * 0.80),
      pi * 0.25,
      pi * 0.6,
      false,
      Paint()
        ..color = pressed ? const Color(0x55000000) : const Color(0x30000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 3 : 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HardwareButtonPainter old) => old.pressed != pressed;
}
