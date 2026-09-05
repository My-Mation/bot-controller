import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../models/commands.dart';


final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

enum ConnectionStateEnum { disconnected, connecting, connected }

class WebSocketService {
  static const String _url = 'ws://192.168.4.1/ws';
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  final _connectionStateController =
      StreamController<ConnectionStateEnum>.broadcast();
  Stream<ConnectionStateEnum> get connectionState =>
      _connectionStateController.stream;

  ConnectionStateEnum _currentState = ConnectionStateEnum.disconnected;
  ConnectionStateEnum get currentState => _currentState;

  WebSocketService() {
    connect();
  }

  void _updateState(ConnectionStateEnum state) {
    if (_currentState == state) return;
    _currentState = state;
    _connectionStateController.add(state);
  }

  bool _isKilled = false;
  bool get isKilled => _isKilled;

  void setKillSwitch(bool kill) {
    _isKilled = kill;
    if (kill) {
      disconnect();
    } else {
      connect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (_channel != null) {
      try {
        _channel?.sink.close();
      } catch (_) {}
      _channel = null;
    }
    _updateState(ConnectionStateEnum.disconnected);
  }

  void connect() {
    if (_isKilled || _isDisposed) return;
    if (_currentState == ConnectionStateEnum.connected ||
        _currentState == ConnectionStateEnum.connecting) {
      return;
    }

    _updateState(ConnectionStateEnum.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channel!.stream.listen(
        (message) {
          if (_currentState != ConnectionStateEnum.connected) {
            _updateState(ConnectionStateEnum.connected);
          }
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  bool _isDisposed = false;

  void _scheduleReconnect() {
    if (_isDisposed || _isKilled) return;
    _updateState(ConnectionStateEnum.disconnected);
    _channel?.sink.close();
    _channel = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      connect();
    });
  }

  void sendCommand(RobotCommand command) {
    if (_isKilled) return; // Block all outbound commands when Kill Switch is engaged
    if (_currentState == ConnectionStateEnum.connected && _channel != null) {
      final jsonString = jsonEncode(command.toJson());
      _channel!.sink.add(jsonString);
    }
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
    _connectionStateController.close();
  }
}
