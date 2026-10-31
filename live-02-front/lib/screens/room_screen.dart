import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/stream_service.dart';

class RoomScreen extends StatefulWidget {
  final String creatorId;
  const RoomScreen({super.key, required this.creatorId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  Room? room;
  bool _isConnected = false;
  LocalVideoTrack? _cameraTrack;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
    _connectRoom();
  }

  Future<void> _connectRoom() async {
    try {
      print('🔗 Conectando LiveKit...');

      final tokenData = await StreamService.getLivekitToken(widget.creatorId);

      print('✅ Token recebido: ${tokenData['token'].substring(0, 20)}...');

      final connectOptions = ConnectOptions(
        url:
            'wss://your-livekit-server.com', // Altere para seu servidor LiveKit
        token: tokenData['token'],
      );

      room = await Room.connect(connectOptions);

      // Enable camera/microfone
      final videoTrack = await LocalVideoTrack.createCameraTrack();
      final audioTrack = await LocalVideoTrack.createMicrophoneTrack();

      await room!.localParticipant.setMetadata('creator:${widget.creatorId}');
      await room!.localParticipant.publishTrack(videoTrack);
      await room!.localParticipant.publishTrack(audioTrack);

      room!.on('trackSubscribed', (track, publication, participant) {
        print('📹 Remote track: ${participant.identity}');
      });

      setState(() {
        _cameraTrack = videoTrack;
        _isConnected = true;
      });

      print('✅ Conectado ao room: ${tokenData['room']}');
    } catch (e) {
      print('❌ LiveKit erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _startCamera() async {
    if (room != null && _isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera já ativa! 🎥')),
      );
      return;
    }
    _connectRoom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiveKit Room')),
      body: Stack(
        children: [
          if (_isConnected && _cameraTrack != null)
            Positioned.fill(
              child: ClipRRect(
                child: RTCVideoView(
                  _renderer,
                  mirrorHorizontal: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          if (!_isConnected)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Clique para iniciar camera',
                      style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _startCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                    ),
                    child: const Text('🎥 START CAMERA',
                        style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _isConnected ? '🟢 LIVE' : '🔴 OFFLINE',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _renderer.dispose();
    _cameraTrack?.dispose();
    room?.disconnect();
    super.dispose();
  }
}
