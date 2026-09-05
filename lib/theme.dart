import 'package:flutter/material.dart';

class ControllerTheme {
  // Shell & background
  static const Color shellBg = Color(0xFF111419);
  static const Color shellDeep = Color(0xFF080A0D);
  static const Color bezel = Color(0xFF050608);

  // Display surface
  static const Color displayBg = Color(0xFF0E1012);
  static const Color displayBorder = Color(0xFF252830);

  // Buttons
  static const Color buttonFace = Color(0xFF272B30);
  static const Color buttonHighlight = Color(0xFF32373D);
  static const Color buttonShadow = Color(0xFF0D0F11);
  static const Color buttonPressed = Color(0xFF1E2226);

  // D-pad
  static const Color dpadFace = Color(0xFF23272C);
  static const Color dpadCenter = Color(0xFF1A1D21);

  // Text / telemetry
  static const Color textPrimary = Color(0xFFD0D4DA);
  static const Color textSecondary = Color(0xFF7A8190);
  static const Color textDim = Color(0xFF4A5060);

  // Accent (very subtle — only for indicators)
  static const Color accentGreen = Color(0xFF3D7A52);
  static const Color accentAmber = Color(0xFF8A6A28);
  static const Color accentRed = Color(0xFF7A3030);
  static const Color accentBlue = Color(0xFF2A4E7A);
  static const Color accentCyan = Color(0xFF2A7A8A);


  // Indicator ring
  static const Color ringActive = Color(0xFF5A8A6A);
  static const Color ringInactive = Color(0xFF2A2E34);

  // Emergency stop — muted red
  static const Color estopOff = Color(0xFF3A2828);
  static const Color estopOn = Color(0xFF7A2828);

  // Jog control
  static const Color jogTrack = Color(0xFF181A1C);
  static const Color jogKnob = Color(0xFF2E3338);
  static const Color jogKnobHighlight = Color(0xFF3A4048);

  // Fonts
  static const String fontFamily = 'monospace';
}
