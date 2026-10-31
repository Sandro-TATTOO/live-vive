import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/stream_service.dart';
import '../widgets/chat_overlay.dart';

class LiveRoomScreen extends StatefulWidget {
  final String streamId;
  const LiveRoomScreen({super.key, required this.streamId});

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  Room? room;
  bool _isConnected = false;
  int _viewersCount = 0;
  Participant? _remoteParticipant;
  final VideoRenderer _renderer = VideoRenderer();

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
    StreamService.joinLive(widget.streamId);
    _connectToLive();
  }

  Future<void> _connectToLive() async {
    try {
      // Token para VIEWER
      final tokenData = await StreamService.getLivekitToken(widget.streamId);

      print('🔗 Conectando viewer a live ${widget.streamId}');

      room = await Room.connect(
        url: 'wss://livestreamapp-ghcjo92o.livekit.cloud', // LiveKit Cloud
        token: tokenData['token'],
      );

      room!.on<RemoteTrackAddedEvent>((event) {
        print('📹 Remote track adicionado: ${event.remoteTrack.kind}');
        setState(() {});
      });

      room!.on<ParticipantEvent>((event) {
        print('👥 Participant update: ${event.participant.sid}');
        setState(() {
          _viewersCount = StreamService.fetchViewerCountSync(
              widget.streamId); // Backend real-time
          _remoteParticipant = room!.remoteParticipants.values.firstOrNull;
        });
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('❌ Viewer erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro conectar live: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text('$_viewersCount viewers',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Video fullscreen
          if (_isConnected && _remoteParticipant != null)
            Positioned.fill(
              child: _remoteParticipant!.videoTracks.values.isNotEmpty
                  ? VideoView(
                      _remoteParticipant!.videoTracks.values.first.track!,
                      renderer: _renderer,
                      mirrorHorizontal: false,
                      objectFit: VideoViewObjectFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.videocam_off,
                          color: Colors.white54, size: 100),
                    ),
            )
          else if (!_isConnected)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text('Conectando à live...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Chat overlay (bottom 40%)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatOverlay(streamId: widget.streamId),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    StreamService.leaveLive(widget.streamId);
    room?.disconnect();
    super.dispose();
  }
}
