
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  static SocketService get instance => _instance;

  IO.Socket? _socket;
  bool _isConnected = false;

  SocketService._internal();

  // Initialize connection
  Future<void> init() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    // Use ApiService.baseUrl to deduce socket URL
    // Remove '/api' suffix if present
    String baseUrl = ApiService.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setExtraHeaders({'Authorization': 'Bearer $token'})
      .build());

    // Update token on handshake if needed, typically socket.io-client handles it via options or query
    // For flask-socketio jwt, we might need to send token in query or auth payload
    _socket!.io.options?['query'] = {'token': token};
    _socket!.io.options?['auth'] = {'token': token}; // Socket.IO v3+

    _socket!.connect();

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('Socket connected');
      }
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('Socket disconnected');
      }
      _isConnected = false;
    });

    _socket!.onError((data) {
       if (kDebugMode) {
        print('Socket error: $data');
      }
    });
  }

  void joinTeam(int teamId) async {
    if (_socket == null || !_socket!.connected) await init();
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    _socket!.emit('team:join', {
      'token': token,
      'team_id': teamId,
    });
  }

  void leaveTeam(int teamId) async {
    if (_socket == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    _socket!.emit('team:leave', {
      'token': token,
      'team_id': teamId,
    });
  }

  void sendMessage(int teamId, String content) async {
    if (_socket == null || !_socket!.connected) await init();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    _socket!.emit('team:message', {
      'token': token,
      'team_id': teamId,
      'content': content,
    });
  }

  void onMessage(Function(dynamic) callback) {
    _socket?.on('team:message', callback);
  }

  void offMessage() {
    _socket?.off('team:message');
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
