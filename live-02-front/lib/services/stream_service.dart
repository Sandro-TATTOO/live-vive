import '../models/message_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stream_model.dart';

class StreamService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // Lista lives (HomeScreen)

  // Iniciar stream (host)
  static Future<Map<String, dynamic>> startStream(String title, String hostId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'host_id': hostId}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('startStream erro: $e');
    }
    return {'stream_id': 'fallback'};
  }

  // Encerrar stream
  static Future<void> endStream(String streamId) async {
    try {
      await http.post(Uri.parse('$_baseUrl/streams/$streamId/end'));
    } catch (e) {
      print('endStream erro: $e');
    }
  }

  // Token host
  static Future<Map<String, dynamic>> getHostToken(String streamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$streamId/host-token'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('getHostToken erro: $e');
    }
    return {
      'server_url': 'wss://livestreamapp-ghcjo92o.livekit.cloud',
      'token': '',
      'room': streamId,
    };
  }

  static Future<List<StreamModel>> fetchStreams() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/live'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => StreamModel.fromJson(e)).toList();
      }
      throw Exception('Erro ao buscar streams');
    } catch (e) {
      print('❌ fetchStreams: $e');
      return [
        StreamModel(
            id: '1',
            title: 'Live Teste 1',
            thumbnailUrl: 'https://via.placeholder.com/400x225',
            viewerCount: 100),
      ];
    }
  }

  // Token LiveKit viewer
  static Future<Map<String, dynamic>> getLivekitToken(String streamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$streamId/viewer-token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Erro token LiveKit');
    } catch (e) {
      print('❌ getLivekitToken: $e');
      return {
        "server_url": "wss://livestreamapp-ghcjo92o.livekit.cloud",
        "token": "",
        "room": streamId,
        "identity": "viewer_fallback"
      };
    }
  }

  // 🌐 SISTEMA PRESENÇA VIEWERS
  static final supabase = Supabase.instance.client;
  static String? _currentUserId;

  static Future<void> initializeUser() async {
    final user = supabase.auth.currentUser;
    _currentUserId =
        user?.id ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> joinLive(String streamId) async {
    if (_currentUserId == null) await initializeUser();

    try {
      await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': _currentUserId}),
      );
      print('✅ JOIN live $streamId');
    } catch (e) {
      print('❌ JOIN erro: $e');
    }
  }

  static Future<void> leaveLive(String streamId) async {
    if (_currentUserId == null) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': _currentUserId}),
      );
      print('👋 LEAVE live $streamId');
    } catch (e) {
      print('❌ LEAVE erro: $e');
    }
  }

  // Detalhes live + viewers (atualização)
  static Future<int> fetchViewerCount(String streamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$streamId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['viewer_count'] ?? 0;
      }
    } catch (e) {
      print('❌ fetchViewerCount: $e');
    }
    return 0;
  }

  // Enviar mensagem via backend
  static Future<void> sendMessage(String streamId, String userId, String content) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stream_id': streamId,
          'user_id': userId,
          'message_type': 'chat',
          'content': content,
        }),
      );
    } catch (e) {
      print('sendMessage erro: $e');
    }
  }

  // Buscar mensagens via backend
  static Future<List<MessageModel>> fetchMessages(String streamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$streamId/messages?limit=50'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['messages'] as List;
        return list.map((e) => MessageModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('fetchMessages erro: $e');
    }
    return [];
  }

}
