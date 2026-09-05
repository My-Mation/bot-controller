import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/telemetry.dart';
import '../core/websocket/websocket_service.dart';

class TelemetryState {
  final Telemetry telemetry;
  final ConnectionStateEnum connectionState;
  final String statusMessage;

  TelemetryState({
    required this.telemetry,
    required this.connectionState,
    required this.statusMessage,
  });

  TelemetryState copyWith({
    Telemetry? telemetry,
    ConnectionStateEnum? connectionState,
    String? statusMessage,
  }) {
    return TelemetryState(
      telemetry: telemetry ?? this.telemetry,
      connectionState: connectionState ?? this.connectionState,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class TelemetryController extends Notifier<TelemetryState> {
  late StreamSubscription _wsSubscription;
  late StreamSubscription _connSubscription;
  double? _filteredVoltage;
  double? _filteredPercent;

  @override
  TelemetryState build() {
    final wsService = ref.watch(webSocketServiceProvider);
    
    _connSubscription = wsService.connectionState.listen((connState) {
      String status = connState == ConnectionStateEnum.connected ? 'Connected' : 'Disconnected';
      state = state.copyWith(connectionState: connState, statusMessage: status);
    });

    _wsSubscription = wsService.messages.listen((msg) {
      if (msg['type'] == 'telemetry' || msg.containsKey('batteryPercent') || msg.containsKey('batteryVoltage')) {
        _processTelemetryMessage(msg);
      } else if (msg['type'] == 'event' || msg['type'] == 'error') {
        _handleEvent(msg);
      }
    });

    ref.onDispose(() {
      _wsSubscription.cancel();
      _connSubscription.cancel();
    });

    return TelemetryState(
      telemetry: Telemetry(),
      connectionState: wsService.currentState,
      statusMessage: wsService.currentState == ConnectionStateEnum.connected ? 'Connected' : 'Disconnected',
    );
  }

  void _processTelemetryMessage(Map<String, dynamic> msg) {
    final double? rawVoltage = (msg['batteryVoltage'] as num?)?.toDouble();
    final double? rawPercent = (msg['batteryPercent'] as num?)?.toDouble();

    if (rawVoltage != null && rawVoltage > 0.0) {
      if (_filteredVoltage == null) {
        _filteredVoltage = rawVoltage;
      } else {
        // Asymmetric exponential moving average: slow drop to reject motor sag, faster recovery
        final double alpha = (rawVoltage < _filteredVoltage!) ? 0.03 : 0.08;
        _filteredVoltage = _filteredVoltage! + alpha * (rawVoltage - _filteredVoltage!);
      }
      _filteredPercent = ((_filteredVoltage! - 4.5) / 3.6 * 100.0).clamp(0.0, 100.0);
    } else if (rawPercent != null) {
      if (_filteredPercent == null) {
        _filteredPercent = rawPercent.clamp(0.0, 100.0);
      } else {
        final double alpha = (rawPercent < _filteredPercent!) ? 0.03 : 0.08;
        _filteredPercent = (_filteredPercent! + alpha * (rawPercent - _filteredPercent!)).clamp(0.0, 100.0);
      }
    }

    var updatedTelemetry = state.telemetry.copyWithJson(msg);
    if (_filteredVoltage != null || _filteredPercent != null) {
      updatedTelemetry = updatedTelemetry.copyWith(
        batteryVoltage: _filteredVoltage ?? updatedTelemetry.batteryVoltage,
        batteryPercent: _filteredPercent ?? updatedTelemetry.batteryPercent,
      );
    }
    state = state.copyWith(telemetry: updatedTelemetry);
  }

  void _handleEvent(Map<String, dynamic> msg) {
    if (msg['type'] == 'error' && msg['code'] == 'QUEUE_FULL') {
      state = state.copyWith(statusMessage: 'Queue Full');
    } else if (msg['type'] == 'event') {
      final event = msg['event'];
      if (event == 'estop') {
        state = state.copyWith(statusMessage: 'E-STOP Active');
      } else if (event == 'home') {
        state = state.copyWith(statusMessage: 'Homing...');
      } else if (event == 'queueEmpty') {
        // Queue empty
      }
    }
  }
}

final telemetryProvider = NotifierProvider<TelemetryController, TelemetryState>(() {
  return TelemetryController();
});
