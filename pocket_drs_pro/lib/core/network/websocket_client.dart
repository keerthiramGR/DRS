import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketClient {
  io.Socket? _socket;
  int _serverTimeOffset = 0; // NTP offset in milliseconds
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  int get serverTimeOffset => _serverTimeOffset;

  void connect({required String serverUrl, Function(bool)? onConnectionChanged}) {
    _socket = io.io(serverUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket?.connect();

    _socket?.onConnect((_) {
      _isConnected = true;
      if (onConnectionChanged != null) onConnectionChanged(true);
      print('✅ Connected to WebSocket backend server.');
      _syncClock();
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      if (onConnectionChanged != null) onConnectionChanged(false);
      print('❌ Disconnected from WebSocket backend server.');
    });

    // Handle NTP latency responses
    _socket?.on('time_sync_pong', (data) {
      final clientPingTime = data['clientTime'] as int;
      final serverTime = data['serverTime'] as int;
      final clientPongTime = DateTime.now().millisecondsSinceEpoch;
      
      final roundTripTime = clientPongTime - clientPingTime;
      // Estimate server time when it responded
      final estimatedServerTime = serverTime + (roundTripTime / 2);
      _serverTimeOffset = (estimatedServerTime - clientPongTime).round();
      
      print('🕒 Clock synced. Latency: ${roundTripTime}ms. Server offset: ${_serverTimeOffset}ms.');
    });
  }

  void _syncClock() {
    if (_socket == null || !_isConnected) return;
    _socket?.emit('time_sync_ping', {
      'clientTime': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get current synchronized network time
  int get networkTimeNow {
    return DateTime.now().millisecondsSinceEpoch + _serverTimeOffset;
  }

  void joinRoom({required String roomId, required String role, required String deviceName, required String matchId}) {
    if (_socket == null || !_isConnected) return;
    _socket?.emit('join_match_room', {
      'roomId': roomId,
      'role': role,
      'deviceName': deviceName,
      'matchId': matchId,
    });
  }

  void listenToRoomMembers(Function(List<dynamic>) onUpdate) {
    _socket?.on('room_members_updated', (data) {
      onUpdate(data as List<dynamic>);
    });
  }

  void triggerDrsReview({required String roomId, required String eventType}) {
    if (_socket == null || !_isConnected) return;
    _socket?.emit('trigger_drs_recording', {
      'roomId': roomId,
      'eventType': eventType,
      'timestamp': networkTimeNow,
    });
  }

  void listenForDrsTriggers(Function(Map<String, dynamic>) onTrigger) {
    _socket?.on('start_drs_cache_capture', (data) {
      onTrigger(Map<String, dynamic>.from(data));
    });
  }

  void streamSensorTelemetry({required String roomId, required String role, required Map<String, dynamic> payload}) {
    if (_socket == null || !_isConnected) return;
    _socket?.emit('stream_sensor_data', {
      'roomId': roomId,
      'deviceRole': role,
      'payload': payload,
    });
  }

  void listenForSensorTelemetry(Function(Map<String, dynamic>) onTelemetry) {
    _socket?.on('realtime_sensor_overlay', (data) {
      onTelemetry(Map<String, dynamic>.from(data));
    });
  }

  void broadcastDecision({required String roomId, required Map<String, dynamic> decisionOutcome}) {
    if (_socket == null || !_isConnected) return;
    _socket?.emit('broadcast_decision_outcome', {
      'roomId': roomId,
      'decisionOutcome': decisionOutcome,
    });
  }

  void listenForDecisions(Function(Map<String, dynamic>) onDecision) {
    _socket?.on('decision_alert', (data) {
      onDecision(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }
}
