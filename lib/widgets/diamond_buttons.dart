import 'package:flutter/material.dart';
import 'pressable_button.dart';

/// Four circular buttons arranged in a diamond (◇) layout.
class DiamondButtons extends StatelessWidget {
  final double buttonSize;
  final double spacing;
  final List<String> labels;
  final void Function(int index)? onPress;

  const DiamondButtons({
    super.key,
    this.buttonSize = 44,
    this.spacing = 6,
    this.labels = const ['▲', '●', '■', '✕'],
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final step = buttonSize + spacing;
    final total = buttonSize + step * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top (index 0)
          Positioned(
            top: 0,
            left: step,
            child: PressableButton(
              size: buttonSize,
              label: labels[0],
              onPress: () => onPress?.call(0),
            ),
          ),
          // Left (index 3)
          Positioned(
            top: step,
            left: 0,
            child: PressableButton(
              size: buttonSize,
              label: labels[3],
              onPress: () => onPress?.call(3),
            ),
          ),
          // Right (index 1)
          Positioned(
            top: step,
            left: step * 2,
            child: PressableButton(
              size: buttonSize,
              label: labels[1],
              onPress: () => onPress?.call(1),
            ),
          ),
          // Bottom (index 2)
          Positioned(
            top: step * 2,
            left: step,
            child: PressableButton(
              size: buttonSize,
              label: labels[2],
              onPress: () => onPress?.call(2),
            ),
          ),
        ],
      ),
    );
  }
}
