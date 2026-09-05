import 'package:flutter/material.dart';
import '../theme.dart';

/// 6-DOF Servo Monitor Card
/// Visual position progress bars for S1–S6 with custom range limits
/// (S1..S2, S4..S6 in µs; S3 in ADC feedback 0..4095).
class ServoMonitorCard extends StatelessWidget {
  final List<int>? servos;
  final int activeServoIndex;
  final ValueChanged<int>? onServoSelected;

  const ServoMonitorCard({
    super.key,
    this.servos,
    this.activeServoIndex = 0,
    this.onServoSelected,
  });

  static const List<_ServoConfig> _configs = [
    _ServoConfig(name: 'S1', label: 'FL Leg', min: 1000, max: 2500, unit: 'µs'),
    _ServoConfig(name: 'S2', label: 'BR Leg', min: 500, max: 2500, unit: 'µs'),
    _ServoConfig(name: 'S3', label: 'FR Smart', min: 50, max: 3950, unit: 'ADC'),
    _ServoConfig(name: 'S4', label: 'BL Leg', min: 1170, max: 2500, unit: 'µs'),
    _ServoConfig(name: 'S5', label: 'Slider', min: 1450, max: 2500, unit: 'µs'),
    _ServoConfig(name: 'S6', label: 'Rotator', min: 1700, max: 2500, unit: 'µs'),
  ];

  @override
  Widget build(BuildContext context) {
    final list = servos ?? [2350, 650, 1950, 2350, 2500, 2500];

    return Container(
      decoration: BoxDecoration(
        color: ControllerTheme.shellDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ControllerTheme.displayBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing_rounded,
                size: 14,
                color: ControllerTheme.accentAmber,
              ),
              const SizedBox(width: 6),
              const Text(
                '6-DOF SERVO TELEMETRY',
                style: TextStyle(
                  color: ControllerTheme.textSecondary,
                  fontSize: 10,
                  fontFamily: ControllerTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 6 Servos Progress Grid ─────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) {
                    final cfg = _configs[i];
                    final rawVal = i < list.length ? list[i] : cfg.min;
                    final isSelected = activeServoIndex == i;

                    final double fraction = ((rawVal - cfg.min) / (cfg.max - cfg.min))
                        .clamp(0.0, 1.0);

                    return GestureDetector(
                      onTap: () => onServoSelected?.call(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ControllerTheme.ringActive.withAlpha(25)
                              : ControllerTheme.displayBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? ControllerTheme.ringActive
                                : ControllerTheme.displayBorder,
                            width: isSelected ? 1.2 : 0.6,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                cfg.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? ControllerTheme.ringActive
                                      : ControllerTheme.textSecondary,
                                  fontSize: 9,
                                  fontFamily: ControllerTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                cfg.label,
                                style: const TextStyle(
                                  color: ControllerTheme.textDim,
                                  fontSize: 8,
                                  fontFamily: ControllerTheme.fontFamily,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      color: ControllerTheme.ringInactive,
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: fraction,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? ControllerTheme.ringActive
                                              : ControllerTheme.accentCyan,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 55,
                              child: Text(
                                '$rawVal ${cfg.unit}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isSelected
                                      ? ControllerTheme.ringActive
                                      : ControllerTheme.textSecondary,
                                  fontSize: 9,
                                  fontFamily: ControllerTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServoConfig {
  final String name;
  final String label;
  final int min;
  final int max;
  final String unit;

  const _ServoConfig({
    required this.name,
    required this.label,
    required this.min,
    required this.max,
    required this.unit,
  });
}
