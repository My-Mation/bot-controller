import 'package:flutter/material.dart';
import '../theme.dart';
import '../core/models/telemetry.dart';
import '../core/websocket/websocket_service.dart';
import 'artificial_horizon.dart';
import 'gps_map_card.dart';
import 'servo_monitor_card.dart';

/// The central display showing top connection/control bar and dynamic telemetry cards.
class CenterDisplay extends StatefulWidget {
  final ConnectionStateEnum connectionState;
  final Telemetry telemetry;
  final bool eStop;
  final String statusLine1;
  final String statusLine2;
  final int activeServoIndex;
  final ValueChanged<bool>? onEStopChanged;
  final ValueChanged<bool>? onLightToggled;
  final ValueChanged<int>? onServoSelected;

  const CenterDisplay({
    super.key,
    required this.connectionState,
    required this.telemetry,
    this.eStop = false,
    this.statusLine1 = 'IDLE',
    this.statusLine2 = '',
    this.activeServoIndex = 0,
    this.onEStopChanged,
    this.onLightToggled,
    this.onServoSelected,
  });

  @override
  State<CenterDisplay> createState() => _CenterDisplayState();
}

class _CenterDisplayState extends State<CenterDisplay> {
  int _selectedTab = 0; // 0: Horizon/IMU, 1: GPS Map, 2: Servos

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.connectionState == ConnectionStateEnum.connected;
    final t = widget.telemetry;

    final batteryPct = (t.batteryPercent?.toInt() ?? 100).clamp(0, 100);
    final batteryVolts = t.batteryVoltage;
    final rssi = t.wifiRSSI ?? -42;
    final lightState = t.light;

    return Container(
      decoration: BoxDecoration(
        color: ControllerTheme.displayBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ControllerTheme.displayBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(200),
            blurRadius: 18,
            spreadRadius: 3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Control & Telemetry Header Bar ─────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                // Connection Status Pill
                _ConnectionPill(isConnected: isConnected),
                const SizedBox(width: 6),

                // Signal RSSI Indicator
                _RssiIndicator(rssi: rssi),
                const SizedBox(width: 6),

                // Battery Meter (% & V)
                _BatteryMeter(percent: batteryPct, voltage: batteryVolts),
                const SizedBox(width: 12),

                // Headlight Switch
                _HeadlightButton(
                  isOn: lightState,
                  onToggle: () => widget.onLightToggled?.call(!lightState),
                ),
                const SizedBox(width: 8),

                // Kill Switch Toggle (Bigger & Prominent)
                _KillSwitchToggle(
                  active: widget.eStop,
                  onChanged: widget.onEStopChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── View Mode Selector Tabs ────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _TabButton(
                  icon: Icons.screen_rotation_rounded,
                  label: 'HORIZON',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 4),
                _TabButton(
                  icon: Icons.map_rounded,
                  label: 'GPS MAP',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(width: 4),
                _TabButton(
                  icon: Icons.precision_manufacturing_rounded,
                  label: 'SERVOS',
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
                const SizedBox(width: 12),
                // Queue & Status Indicator
                _StatusBadge(
                  line1: widget.statusLine1,
                  line2: widget.statusLine2,
                  queue: t.queue ?? 0,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Dynamic Main Display Area ──────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                ArtificialHorizonCard(
                  imu: t.imu,
                  pitch: t.pitch ?? 0.0,
                  roll: t.roll ?? 0.0,
                ),
                GpsMapCard(gps: t.gps, telemetry: t),
                ServoMonitorCard(
                  servos: t.servos,
                  activeServoIndex: widget.activeServoIndex,
                  onServoSelected: widget.onServoSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final bool isConnected;

  const _ConnectionPill({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? ControllerTheme.accentGreen : ControllerTheme.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(150), width: 0.8),
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: color.withAlpha(50),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isConnected ? 'CONNECTED' : 'DISCONNECTED',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontFamily: ControllerTheme.fontFamily,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RssiIndicator extends StatelessWidget {
  final int rssi;

  const _RssiIndicator({required this.rssi});

  @override
  Widget build(BuildContext context) {
    int bars = 1;
    if (rssi > -55) {
      bars = 4;
    } else if (rssi > -70) {
      bars = 3;
    } else if (rssi > -85) {
      bars = 2;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi, size: 12, color: ControllerTheme.textDim),
        const SizedBox(width: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final active = i < bars;
            return Container(
              width: 2,
              height: (i + 1) * 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              decoration: BoxDecoration(
                color: active
                    ? ControllerTheme.accentCyan
                    : ControllerTheme.textDim.withAlpha(60),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
        const SizedBox(width: 3),
        Text(
          '$rssi dBm',
          style: const TextStyle(
            color: ControllerTheme.textDim,
            fontSize: 8,
            fontFamily: ControllerTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}

class _BatteryMeter extends StatelessWidget {
  final int percent;
  final double? voltage;

  const _BatteryMeter({required this.percent, this.voltage});

  @override
  Widget build(BuildContext context) {
    Color col = ControllerTheme.accentGreen;
    if (percent < 20) {
      col = ControllerTheme.accentRed;
    } else if (percent < 50) {
      col = ControllerTheme.accentAmber;
    }

    final IconData icon;
    if (percent >= 85) {
      icon = Icons.battery_full_rounded;
    } else if (percent >= 65) {
      icon = Icons.battery_6_bar_rounded;
    } else if (percent >= 45) {
      icon = Icons.battery_4_bar_rounded;
    } else if (percent >= 25) {
      icon = Icons.battery_2_bar_rounded;
    } else if (percent >= 10) {
      icon = Icons.battery_1_bar_rounded;
    } else {
      icon = Icons.battery_alert_rounded;
    }

    final String text = voltage != null
        ? '$percent% | ${voltage!.toStringAsFixed(2)}V'
        : '$percent%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: col,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: col,
            fontSize: 9,
            fontFamily: ControllerTheme.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeadlightButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback? onToggle;

  const _HeadlightButton({required this.isOn, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOn
              ? ControllerTheme.accentAmber.withAlpha(40)
              : ControllerTheme.shellDeep,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOn
                ? ControllerTheme.accentAmber
                : ControllerTheme.displayBorder,
            width: 0.8,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: ControllerTheme.accentAmber.withAlpha(80),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
              size: 12,
              color: isOn
                  ? ControllerTheme.accentAmber
                  : ControllerTheme.textDim,
            ),
            const SizedBox(width: 4),
            Text(
              isOn ? 'LIGHT ON' : 'LIGHT OFF',
              style: TextStyle(
                color: isOn
                    ? ControllerTheme.accentAmber
                    : ControllerTheme.textDim,
                fontSize: 8,
                fontFamily: ControllerTheme.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KillSwitchToggle extends StatelessWidget {
  final bool active;
  final ValueChanged<bool>? onChanged;

  const _KillSwitchToggle({required this.active, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5C1D1D) : ControllerTheme.shellDeep,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFF8E3333) : const Color(0xFF632B2B).withAlpha(120),
            width: active ? 1.4 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF5C1D1D).withAlpha(120),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              size: 13,
              color: active ? const Color(0xFFFFD1D1) : const Color(0xFFA66060),
            ),
            const SizedBox(width: 5),
            Text(
              active ? 'KILL ACTIVE' : 'KILL SWITCH',
              style: TextStyle(
                color: active ? const Color(0xFFFFD1D1) : const Color(0xFFA66060),
                fontSize: 8.5,
                fontFamily: ControllerTheme.fontFamily,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? ControllerTheme.ringActive.withAlpha(30)
              : ControllerTheme.shellDeep,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? ControllerTheme.ringActive
                : ControllerTheme.displayBorder,
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isSelected
                  ? ControllerTheme.ringActive
                  : ControllerTheme.textDim,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? ControllerTheme.ringActive
                    : ControllerTheme.textDim,
                fontSize: 8,
                fontFamily: ControllerTheme.fontFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String line1;
  final String line2;
  final int queue;

  const _StatusBadge({
    required this.line1,
    required this.line2,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Q: $queue | $line1',
          style: const TextStyle(
            color: ControllerTheme.textSecondary,
            fontSize: 8,
            fontFamily: ControllerTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
