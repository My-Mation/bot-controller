abstract class RobotCommand {
  Map<String, dynamic> toJson();
}

class MoveCommand extends RobotCommand {
  final int id;
  final List<ServoMove> servos;

  MoveCommand({required this.id, required this.servos});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'move',
      'id': id,
      'servos': servos.map((s) => s.toJson()).toList(),
    };
  }
}

class ServoMove {
  final int id;
  final int position;
  final int speed;

  ServoMove({required this.id, required this.position, required this.speed});

  Map<String, dynamic> toJson() {
    return {'id': id, 'position': position, 'speed': speed};
  }
}

class EstopCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'estop'};
}

class HomeCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'home'};
}

class SitCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'sit'};
}

class LightCommand extends RobotCommand {
  final bool state;
  LightCommand({required this.state});

  @override
  Map<String, dynamic> toJson() => {'type': 'light', 'state': state};
}

class BeepCommand extends RobotCommand {
  final int duration;
  BeepCommand({this.duration = 150});

  @override
  Map<String, dynamic> toJson() => {'type': 'beep', 'duration': duration};
}

class WalkCommand extends RobotCommand {
  final String dir;
  WalkCommand({required this.dir});

  @override
  Map<String, dynamic> toJson() => {'type': 'walk', 'dir': dir};
}

class ForwardCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'forward'};
}

class BackwardCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'backward'};
}

class TurnLeftCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'left'};
}

class TurnRightCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'right'};
}

class StopCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'stop'};
}

class ClearQueueCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'clearQueue'};
}

class PingCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'ping'};
}

class HeartbeatCommand extends RobotCommand {
  @override
  Map<String, dynamic> toJson() => {'type': 'heartbeat'};
}

