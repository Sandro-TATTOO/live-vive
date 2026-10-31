import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:uuid/uuid.dart';
import '../services/stream_service.dart';


class HostLiveScreen extends StatefulWidget {
  final String title;
  final String hostId;
  const HostLiveScreen({super.key, required this.title, required this.hostId});

  @override
  State<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends State<HostLiveScreen> {
  String? streamId;
  Room? room;
  EventsListener<RoomEvent>? listener;
  LocalVideoTrack? _videoTrack;
  LocalAudioTrack? _audioTrack;
  bool _isConnected = false;
  String _hostId = '';

  @override
  void initState() {
    super.initState();
    _hostId = _isValidUuid(widget.hostId) ? widget.hostId : const Uuid().v4();
    _startLive();
  }

  bool _isValidUuid(String s) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(s);
  }

  @override
  void initState() {
    super.initState();
    _startLive();
  }

  Future<void> _startLive() async {
    try {
      // 1. Criar stream no backend
      final res = await StreamService.startStream(widget.title, _hostId);
      streamId = res['stream_id']?.toString();
      if (streamId == null) throw Exception('stream_id null');

      // 2. Obter host token
      final tokenData = await StreamService.getHostToken(streamId!);

      // 3. Criar tracks
      _videoTrack = await LocalVideoTrack.createCameraTrack();
      _audioTrack = await LocalAudioTrack.create();

      // 4. Conectar ao LiveKit
      room = Room();
      listener = room!.createListener();
      await room!.prepareConnection(
        tokenData['server_url'] ?? 'wss://livestreamapp-ghcjo92o.livekit.cloud',
        tokenData['token'] ?? '',
      );
      await room!.connect(
        tokenData['server_url'] ?? 'wss://livestreamapp-ghcjo92o.livekit.cloud',
        tokenData['token'] ?? '',
      );

      // 5. Publicar tracks
      if (room!.localParticipant != null) {
        await room!.localParticipant!.publishVideoTrack(_videoTrack!);
        await room!.localParticipant!.publishAudioTrack(_audioTrack!);
      }

      setState(() => _isConnected = true);
    } catch (e) {
      print('Host erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar live: $e')),
        );
      }
    }
  }

  Future<void> _endLive() async {
    try {
      if (streamId != null) {
        await StreamService.endStream(streamId!);
      }
      await _videoTrack?.stop();
      await _audioTrack?.stop();
      listener?.dispose();
      await room?.disconnect();
      await room?.dispose();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('End live erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _endLive,
        ),
      ),
      body: Stack(
        children: [
          if (_videoTrack != null)
            Positioned.fill(
              child: VideoTrackRenderer(_videoTrack!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _endLive,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.stop),
                  label: const Text('Encerrar Live'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoTrack?.dispose();
    _audioTrack?.dispose();
    listener?.dispose();
    room?.disconnect();
    room?.dispose();
    super.dispose();
  }
}
