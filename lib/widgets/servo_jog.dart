import 'package:flutter/material.dart';
import '../theme.dart';

/// A vertical spring-centered servo jog control.
/// Drag up = positive jog, down = negative jog.
/// Releases snap the knob back to center.
class ServoJog extends StatefulWidget {
  final double width;
  final double height;
  final void Function(double value)? onChanged; // -1.0 to 1.0
  final void Function()? onReleased;

  const ServoJog({
    super.key,
    this.width = 52,
    this.height = 160,
    this.onChanged,
    this.onReleased,
  });

  @override
  State<ServoJog> createState() => _ServoJogState();
}

class _ServoJogState extends State<ServoJog>
    with SingleTickerProviderStateMixin {
  double _knobOffset = 0.0; // pixels from center
  late AnimationController _snapController;
  late Animation<double> _snapAnim;
  double _snapStart = 0.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapAnim = Tween(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    );
    _snapAnim.addListener(() {
      setState(() => _knobOffset = _snapAnim.value);
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double get _trackH => widget.height - _knobH;
  double get _knobH => widget.width * 0.9;
  double get _maxOffset => _trackH / 2 * 0.82;

  void _onDrag(DragUpdateDetails details) {
    _snapController.stop();
    setState(() {
      _knobOffset = (_knobOffset + details.delta.dy).clamp(
        -_maxOffset,
        _maxOffset,
      );
    });
    final normalized = _knobOffset / _maxOffset;
    widget.onChanged?.call(normalized);
  }

  void _onDragEnd(DragEndDetails _) {
    _snapStart = _knobOffset;
    _snapAnim = Tween(begin: _snapStart, end: 0.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    );
    _snapAnim.addListener(() {
      setState(() => _knobOffset = _snapAnim.value);
    });
    _snapController.forward(from: 0);
    widget.onReleased?.call();
    widget.onChanged?.call(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final trackW = widget.width * 0.28;
    final knobW = widget.width;
    final knobH = _knobH;
    final totalH = widget.height;

    return SizedBox(
      width: knobW,
      height: totalH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track — recessed 3D channel
          Center(
            child: SizedBox(
              width: trackW,
              height: totalH,
              child: CustomPaint(
                painter: _JogTrackPainter(trackW: trackW, totalH: totalH),
              ),
            ),
          ),

          // Tick marks
          ...List.generate(5, (i) {
            final y = (i / 4 - 0.5) * (totalH * 0.75);
            final isMid = i == 2;
            return Positioned(
              left: knobW * 0.5 + trackW * 0.6,
              top: totalH / 2 + y - 0.5,
              child: Container(
                width: isMid ? 8 : 5,
                height: 1,
                color: isMid
                    ? ControllerTheme.textDim.withAlpha(80)
                    : ControllerTheme.textDim.withAlpha(40),
              ),
            );
          }),

          // Knob
          Positioned(
            top: (totalH - knobH) / 2 + _knobOffset,
            child: GestureDetector(
              onVerticalDragUpdate: _onDrag,
              onVerticalDragEnd: _onDragEnd,
              child: _JogKnob(
                width: knobW,
                height: knobH,
                offset: _knobOffset,
                maxOffset: _maxOffset,
              ),
            ),
          ),

          // Label
          Positioned(
            bottom: 0,
            child: Text(
              'JOG',
              style: TextStyle(
                color: ControllerTheme.textDim,
                fontSize: 8,
                fontFamily: ControllerTheme.fontFamily,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a recessed 3D track channel — darker inside at top (inner shadow),
/// lighter at bottom (bounce light), with a narrow slot appearance.
class _JogTrackPainter extends CustomPainter {
  final double trackW;
  final double totalH;

  _JogTrackPainter({required this.trackW, required this.totalH});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Radius.circular(w / 2);
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, r);

    // Well fill — very dark, like a drilled hole
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF080A0C));

    // Inner top shadow — light source from above creates shadow inside the well
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x88000000), Colors.transparent],
          stops: const [0.0, 0.25],
        ).createShader(rect),
    );

    // Inner bottom bounce-light — tiny bit of reflected light at the base
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [const Color(0x18404858), Colors.transparent],
          stops: const [0.0, 0.15],
        ).createShader(rect),
    );

    // Outer rim — darker edge (the lip of the channel)
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF181B20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_JogTrackPainter old) => false;
}

class _JogKnob extends StatelessWidget {
  final double width;
  final double height;
  final double offset;
  final double maxOffset;

  const _JogKnob({
    required this.width,
    required this.height,
    required this.offset,
    required this.maxOffset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _JogKnobPainter(
          offset: offset,
          maxOffset: maxOffset,
          width: width,
          height: height,
        ),
      ),
    );
  }
}

/// Paints a 3D throttle-lever knob:
/// - Top-lit cylindrical gradient (lighter top, darker bottom)
/// - Left rim highlight (ambient light from the left)
/// - Drop shadow below
/// - Etched grip ridges across the center
/// - Slight specular arc at top-left
class _JogKnobPainter extends CustomPainter {
  final double offset;
  final double maxOffset;
  final double width;
  final double height;

  _JogKnobPainter({
    required this.offset,
    required this.maxOffset,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.28;
    final isActive = offset.abs() > 2;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // ── 1. Drop shadow (deeper when active/displaced) ─────────────
    canvas.drawRRect(
      rrect.shift(Offset(0, isActive ? 7 : 4)),
      Paint()
        ..color = Colors.black.withAlpha(isActive ? 180 : 140)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isActive ? 12 : 8),
    );

    // ── 2. Body — top-lit cylindrical gradient ────────────────────
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isActive
              ? const [
                  Color(0xFF2A3040), // active: brighter (pulled up/down)
                  Color(0xFF1A2030),
                  Color(0xFF0E1420),
                ]
              : const [
                  Color(0xFF262C38), // resting: neutral charcoal
                  Color(0xFF1A1F2A),
                  Color(0xFF0F1318),
                ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // ── 3. Left rim highlight ──────────────────────────────────────
    // A narrow bright strip on the left edge — catches side ambient light.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF505A70).withAlpha(90), Colors.transparent],
          stops: const [0.0, 0.25],
        ).createShader(rect),
    );

    // ── 4. Top specular highlight arc ─────────────────────────────
    if (!isActive) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.12),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x1AFFFFFF), Colors.transparent],
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.12)),
      );
      canvas.restore();
    }

    // ── 5. Etched grip ridges ──────────────────────────────────────
    // 7 horizontal lines across the center 60% of the knob height
    final ridgeTop = h * 0.22;
    final ridgeBot = h * 0.78;
    final ridgeCount = 7;
    final ridgeSpacing = (ridgeBot - ridgeTop) / (ridgeCount - 1);
    final ridgeLeft = w * 0.18;
    final ridgeRight = w * 0.82;

    for (int i = 0; i < ridgeCount; i++) {
      final y = ridgeTop + i * ridgeSpacing;
      // Dark groove
      canvas.drawLine(
        Offset(ridgeLeft, y),
        Offset(ridgeRight, y),
        Paint()
          ..color = const Color(0xFF080A0C).withAlpha(150)
          ..strokeWidth = 1.0,
      );
      // Light ridge (1px below dark groove)
      canvas.drawLine(
        Offset(ridgeLeft, y + 1),
        Offset(ridgeRight, y + 1),
        Paint()
          ..color = const Color(0xFF404858).withAlpha(80)
          ..strokeWidth = 0.7,
      );
    }

    // ── 6. Outer border ───────────────────────────────────────────
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF0A0C10).withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_JogKnobPainter old) =>
      old.offset != offset || old.isActive != isActive;

  bool get isActive => offset.abs() > 2;
}
