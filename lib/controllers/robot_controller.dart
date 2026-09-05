import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/commands.dart';
import '../core/websocket/websocket_service.dart';
import '../widgets/d_pad.dart'; // For DPadDirection enum

class RobotController {
  final Ref ref;
  final WebSocketService _wsService;
  Timer? _heartbeatTimer;
  StreamSubscription? _wsSubscription;
  
  int _packetId = 1;
  int _activeServo = 0;
  
  DPadDirection _currentDirection = DPadDirection.none;
  DPadDirection get currentDirection => _currentDirection;

  RobotController(this.ref, this._wsService) {
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_wsService.currentState == ConnectionStateEnum.connected) {
        _wsService.sendCommand(HeartbeatCommand());
      }
    });
  }

  void setActiveServo(int index) {
    _activeServo = index;
  }

  DateTime? _lastJogTime;

  // Calibrated standing/home positions matching config.h
  int _getBasePosition(int servoId) {
    switch (servoId) {
      case 0: return 2350; // S1: Front-Left Leg (µs)
      case 1: return 650;  // S2: Back-Right Leg (µs)
      case 2: return 1950; // S3: Front-Right Smart Servo (ADC counts 0-4095)
      case 3: return 2350; // S4: Back-Left Leg (µs)
      case 4: return 2500; // S5: Slider (µs)
      case 5: return 2500; // S6: Rotator (µs)
      default: return 1500;
    }
  }

  bool isEStopActive = false;

  void emergencyStop(bool active) {
    isEStopActive = active;
    if (active) {
      _currentDirection = DPadDirection.none;
      try {
        _wsService.sendCommand(EstopCommand());
        _wsService.sendCommand(ClearQueueCommand());
        _wsService.sendCommand(StopCommand());
      } catch (_) {}
      _wsService.setKillSwitch(true);
    } else {
      _wsService.setKillSwitch(false);
    }
  }

  void setJogValue(double value) {
    if (isEStopActive) return;
    if (_activeServo < 0 || _activeServo > 5) return;
    
    final now = DateTime.now();
    if (_lastJogTime != null && now.difference(_lastJogTime!).inMilliseconds < 100) {
      if (value != 0.0) return; // Allow immediate stop (0.0) but throttle dragging
    }
    _lastJogTime = now;
    
    // Jog sends raw position updates to the targeted servo
    int basePosition = _getBasePosition(_activeServo);
    int offset = (value * -500).toInt();
    _wsService.sendCommand(ClearQueueCommand());
    _wsService.sendCommand(MoveCommand(
      id: _packetId++,
      servos: [ServoMove(id: _activeServo, position: basePosition + offset, speed: 100)],
    ));
  }

  void setDirection(DPadDirection direction) {
    if (isEStopActive) return;
    if (_currentDirection == direction) return;
    _currentDirection = direction;

    switch (direction) {
      case DPadDirection.up:
        _wsService.sendCommand(WalkCommand(dir: 'forward'));
        break;
      case DPadDirection.down:
        _wsService.sendCommand(WalkCommand(dir: 'backward'));
        break;
      case DPadDirection.left:
        _wsService.sendCommand(WalkCommand(dir: 'left'));
        break;
      case DPadDirection.right:
        _wsService.sendCommand(WalkCommand(dir: 'right'));
        break;
      case DPadDirection.none:
        _wsService.sendCommand(StopCommand());
        break;
    }
  }

  void toggleLight(bool state) {
    if (_wsService.currentState == ConnectionStateEnum.connected) {
      _wsService.sendCommand(LightCommand(state: state));
    }
  }

  void triggerBeep([int durationMs = 150]) {
    if (_wsService.currentState == ConnectionStateEnum.connected) {
      _wsService.sendCommand(BeepCommand(duration: durationMs));
    }
  }

  void actionStand() {
    if (isEStopActive) return;
    _currentDirection = DPadDirection.none;
    _wsService.sendCommand(ClearQueueCommand());
    _wsService.sendCommand(HomeCommand());
  }

  void actionSit() {
    if (isEStopActive) return;
    _currentDirection = DPadDirection.none;
    _wsService.sendCommand(ClearQueueCommand());
    _wsService.sendCommand(SitCommand());
  }

  void actionWalkForward() {
    setDirection(DPadDirection.up);
  }

  void actionWalkBackward() {
    setDirection(DPadDirection.down);
  }

  void actionTurnLeft() {
    setDirection(DPadDirection.left);
  }

  void actionTurnRight() {
    setDirection(DPadDirection.right);
  }

  void actionStop() {
    setDirection(DPadDirection.none);
  }

  void actionFrontLegs() {
    actionTurnLeft();
  }

  void actionRearLegs() {
    actionTurnRight();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _wsSubscription?.cancel();
  }
}

final robotControllerProvider = Provider<RobotController>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  final controller = RobotController(ref, wsService);
  ref.onDispose(() => controller.dispose());
  return controller;
});
