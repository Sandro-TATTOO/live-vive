import 'package:flutter/material.dart';
import '../services/stream_service.dart';

class RoomScreen extends StatefulWidget {
  final String creatorId;
  const RoomScreen({super.key, required this.creatorId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectRoom();
  }

  Future<void> _connectRoom() async {
    try {
      await StreamService.getLivekitToken(widget.creatorId);
      setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiveKit Room')),
      body: Center(
        child: Text(_isConnected ? 'Conectado' : 'Conectando...'),
      ),
    );
  }
}
