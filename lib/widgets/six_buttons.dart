import 'package:flutter/material.dart';
import 'pressable_button.dart';

/// Six circular buttons arranged in a 3×2 grid (3 rows, 2 columns).
class SixButtons extends StatelessWidget {
  final double buttonSize;
  final double spacing;
  final List<String> labels;
  final void Function(int index)? onPress;

  const SixButtons({
    super.key,
    this.buttonSize = 40,
    this.spacing = 10,
    this.labels = const ['F1', 'F2', 'F3', 'F4', 'F5', 'F6'],
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < 2 ? spacing : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (col) {
              final index = row * 2 + col;
              return Padding(
                padding: EdgeInsets.only(right: col < 1 ? spacing : 0),
                child: PressableButton(
                  size: buttonSize,
                  label: labels[index],
                  onPress: () => onPress?.call(index),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
