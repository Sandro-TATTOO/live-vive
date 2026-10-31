import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class ChatOverlay extends StatefulWidget {
  final String streamId;
  const ChatOverlay({super.key, required this.streamId});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;
  final List<MessageModel> _messages = [];
  String? _error;
  bool _isSubscribed = false;
  final int _visibleMessages = 100; // Performance: limit render

  @override
  void initState() {
    super.initState();
    _listenMessages();
  }

  void _listenMessages() {
    if (_isSubscribed) return;

    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('stream_id', widget.streamId)
        .order('created_at', ascending: true)
        .limit(_visibleMessages) // Paginado
        .listen((data) {
          setState(() {
            _messages.clear();
            _messages
                .addAll(data.map((json) => MessageModel.fromSupabase(json)));
          });
          _smartScroll();
        });

    _isSubscribed = true;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await supabase.from('messages').insert({
        'message': text,
        'user_id': supabase.auth.currentUser?.id ?? 'anon',
        'stream_id': widget.streamId,
        'type': 'normal', // Backend define VIP/gift/system
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro enviar: $e')),
      );
    }
  }

  void _smartScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;

      // Smart scroll: só auto se usuário no fundo ou últimas 2 mensagens
      if (current >= max - 200 || _messages.length <= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    }
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isOwn = msg.userId == supabase.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Badge
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _getAvatarColor(msg.type),
                child: Text(
                  msg.avatarChar,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              // VIP Badge
              if (msg.isVip)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.star, size: 12, color: Colors.black),
                  ),
                ),
              // Moderator Crown
              if (msg.isModerator)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble w/ type styles
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: msg.isSystem ? 6 : 10),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(msg.type, isOwn),
                    borderRadius: BorderRadius.circular(msg.isSystem ? 12 : 20),
                    border: msg.isVip
                        ? Border.all(color: Colors.amber, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: _getBubbleTextColor(msg.type),
                      fontSize: msg.isVip ? 15 : 14,
                      fontWeight:
                          msg.isVip ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Timestamp
                Text(
                  _formatTime(msg.createdAt),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(MessageType type) {
    return switch (type) {
      MessageType.vip => Colors.amber,
      MessageType.moderator => Colors.purple,
      MessageType.gift => Colors.pink,
      MessageType.system => Colors.grey,
      _ => Colors.blue[400]!,
    };
  }

  Color _getBubbleColor(MessageType type, bool isOwn) {
    if (isOwn) return Colors.blue[600]!;
    return switch (type) {
      MessageType.vip => Colors.amber[800]!,
      MessageType.moderator => Colors.purple[700]!,
      MessageType.gift => Colors.pink[600]!,
      MessageType.system => Colors.grey[800]!,
      _ => Colors.grey[850]!,
    };
  }

  Color _getBubbleTextColor(MessageType type) {
    return switch (type) {
      MessageType.system => Colors.white,
      _ => Colors.white,
    };
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inMinutes < 1) return 'agora';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // Aumentado
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header (viewers + minimizar)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('456 assistindo',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white70),
                  onPressed: () {}, // Minimizar
                ),
              ],
            ),
          ),
          // Messages ListView (limitado performance)
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Primeira mensagem abre chat!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
          ),
          // Input melhorado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '💬 Mensagem... (Ctrl+Enter)',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 28,
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
