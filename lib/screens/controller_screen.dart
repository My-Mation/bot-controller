import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/d_pad.dart';
import '../widgets/diamond_buttons.dart';
import '../widgets/center_display.dart';
import '../widgets/six_buttons.dart';
import '../widgets/servo_jog.dart';
import '../controllers/telemetry_controller.dart';
import '../controllers/robot_controller.dart';
import '../core/models/telemetry.dart';


class ControllerScreen extends ConsumerStatefulWidget {
  const ControllerScreen({super.key});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onDPad(DPadDirection dir) {
    ref.read(robotControllerProvider).setDirection(dir);
  }

  void _onDPadRelease(DPadDirection dir) {
    ref.read(robotControllerProvider).setDirection(DPadDirection.none);
  }

  void _onDiamondButton(int index) {
    final rc = ref.read(robotControllerProvider);
    switch (index) {
      case 0:
        rc.actionStand();
        break;
      case 1:
        rc.actionTurnRight();
        break;
      case 2:
        rc.actionSit();
        break;
      case 3:
        rc.actionTurnLeft();
        break;
    }
  }

  void _onSixButton(int index) {
    ref.read(robotControllerProvider).setActiveServo(index);
  }

  void _onJog(double value) {
    ref.read(robotControllerProvider).setJogValue(value);
  }

  void _onJogReleased() {
    ref.read(robotControllerProvider).setJogValue(0.0);
  }

  int _activeServoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final telemetryState = ref.watch(telemetryProvider);
    final t = telemetryState.telemetry;
    final rc = ref.read(robotControllerProvider);

    final eStop = telemetryState.statusMessage.contains('E-STOP');
    String statusLine1 = telemetryState.statusMessage;
    String statusLine2 = t.moving == true ? 'Moving' : 'Idle';

    return Scaffold(
      backgroundColor: ControllerTheme.bezel,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final shellW = w * 0.98;
            final shellH = h * 0.95;
            return _ControllerShell(
              width: shellW,
              height: shellH,
              child: _buildBody(
                shellW: shellW,
                shellH: shellH,
                telemetryState: telemetryState,
                telemetry: t,
                eStop: eStop,
                statusLine1: statusLine1,
                statusLine2: statusLine2,
                rc: rc,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required double shellW,
    required double shellH,
    required TelemetryState telemetryState,
    required Telemetry telemetry,
    required bool eStop,
    required String statusLine1,
    required String statusLine2,
    required RobotController rc,
  }) {
    final vPad = shellH * 0.06;
    final hPad = shellW * 0.012;

    final innerH = shellH - vPad * 2;
    final innerW = shellW - hPad * 2;

    final sideW = innerW * 0.19;

    final btnSize = (innerH * 0.098).clamp(36.0, 60.0);
    final dpadSize = (btnSize * 3.32).clamp(100.0, 200.0);
    final sixBtnSize = (innerH * 0.090).clamp(32.0, 54.0);
    final jogH = (innerH * 0.42).clamp(110.0, 195.0);
    final jogW = (jogH * 0.33).clamp(38.0, 62.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Panel ────────────────────────────────────────────
          SizedBox(
            width: sideW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DPad(
                  size: dpadSize,
                  onPress: _onDPad,
                  onRelease: _onDPadRelease,
                ),
                DiamondButtons(
                  buttonSize: btnSize,
                  spacing: btnSize * 0.16,
                  labels: const ['▲', '●', '■', '✕'],
                  onPress: _onDiamondButton,
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Center Display ────────────────────────────────────────
          Expanded(
            child: CenterDisplay(
              connectionState: telemetryState.connectionState,
              telemetry: telemetry,
              eStop: eStop,
              statusLine1: statusLine1,
              statusLine2: statusLine2,
              activeServoIndex: _activeServoIndex,
              onEStopChanged: (v) => rc.emergencyStop(v),
              onLightToggled: (state) => rc.toggleLight(state),
              onServoSelected: (idx) {
                setState(() => _activeServoIndex = idx);
                rc.setActiveServo(idx);
              },
            ),
          ),


          const SizedBox(width: 14),

          // ── Right Panel ───────────────────────────────────────────
          SizedBox(
            width: sideW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SixButtons(
                  buttonSize: sixBtnSize,
                  spacing: sixBtnSize * 0.32,
                  labels: const ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'],
                  onPress: _onSixButton,
                ),
                ServoJog(
                  width: jogW,
                  height: jogH,
                  onChanged: _onJog,
                  onReleased: _onJogReleased,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller Shell — one continuous body with Switch-style grip shading
// ─────────────────────────────────────────────────────────────────────────────

class _ControllerShell extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _ControllerShell({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // ── Outer drop shadow ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(220),
                    blurRadius: 48,
                    spreadRadius: 10,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(180),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // ── Main shell body (continuous one-piece surface) ─────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: CustomPaint(
                painter: _ShellPainter(width: width, height: height),
                child: child,
              ),
            ),
          ),

          // ── Rim highlight (top edge catches light) ─────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF3A3E48).withAlpha(55),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the unified controller shell surface:
/// - Dark graphite center body
/// - Slightly darker/different-toned grip zones on left and right
/// - Subtle horizontal sheen across the top
/// - Barely-visible seam lines where grips meet the display well
class _ShellPainter extends CustomPainter {
  final double width;
  final double height;

  _ShellPainter({required this.width, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = Radius.circular(30);

    final fullRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), r);

    // ── Flat matte fill — no gradient, uniform dark graphite ──────
    canvas.drawRRect(fullRect, Paint()..color = const Color(0xFF111419));
  }

  @override
  bool shouldRepaint(_ShellPainter old) =>
      old.width != width || old.height != height;
}
