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
  EventsListener<RoomEvent>? listener;
  bool _isConnected = false;
  int _viewersCount = 0;
  VideoTrack? _remoteVideoTrack;

  @override
  void initState() {
    super.initState();
    StreamService.joinLive(widget.streamId);
    _connectToLive();
  }

  Future<void> _connectToLive() async {
    try {
      final tokenData = await StreamService.getLivekitToken(widget.streamId);
      print('Conectando viewer a live ${widget.streamId}');

      room = Room();
      await room!.prepareConnection(
        tokenData['server_url'] ?? 'wss://livestreamapp-ghcjo92o.livekit.cloud',
        tokenData['token'] ?? '',
      );
      await room!.connect(
        tokenData['server_url'] ?? 'wss://livestreamapp-ghcjo92o.livekit.cloud',
        tokenData['token'] ?? '',
      );

      listener = room!.createListener();
      listener!
        ..on<RoomDisconnectedEvent>((_) {
          if (mounted) setState(() => _isConnected = false);
        })
        ..on<ParticipantEvent>((_) {
          _updateRemoteParticipant();
        })
        ..on<TrackSubscribedEvent>((_) {
          _updateRemoteParticipant();
        });

      _updateRemoteParticipant();
      if (mounted) setState(() => _isConnected = true);
    } catch (e) {
      print('Viewer erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro conectar live: $e')),
        );
      }
    }
  }

  void _updateRemoteParticipant() {
    if (room == null) return;
    final remote = room!.remoteParticipants.values.firstOrNull;
    VideoTrack? videoTrack;
    if (remote != null && remote.videoTrackPublications.isNotEmpty) {
      final pub = remote.videoTrackPublications.first;
      videoTrack = pub.track as VideoTrack?;
    }
    if (mounted) {
      setState(() {
        _remoteVideoTrack = videoTrack;
        _viewersCount = room!.remoteParticipants.length + 1;
      });
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
          if (_isConnected && _remoteVideoTrack != null)
            Positioned.fill(
              child: VideoTrackRenderer(_remoteVideoTrack!),
            )
          else if (_isConnected)
            const Center(
              child: Icon(Icons.videocam_off, color: Colors.white54, size: 100),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text('Conectando Ã  live...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
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
    listener?.dispose();
    room?.disconnect();
    super.dispose();
  }
}
