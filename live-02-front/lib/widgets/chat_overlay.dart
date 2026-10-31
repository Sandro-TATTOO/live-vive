import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../models/message_model.dart";
import "../services/stream_service.dart";

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
  bool _isSubscribed = false;
  final int _visibleMessages = 100;

  @override
  void initState() {
    super.initState();
    _listenMessages();
  }

  void _listenMessages() {
    if (_isSubscribed) return;
    supabase
        .from('stream_messages')
        .stream(primaryKey: ['id'])
        .eq('stream_id', widget.streamId)
        .order('created_at', ascending: true)
        .limit(_visibleMessages)
        .listen((data) {
          setState(() {
            _messages.clear();
            _messages.addAll(data.map((json) => MessageModel.fromJson(json)));
          });
          _smartScroll();
        });
    _isSubscribed = true;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userId = supabase.auth.currentUser?.id ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';
    await StreamService.sendMessage(widget.streamId, userId, text);
    _controller.clear();
  }

  void _smartScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
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
    final isOwn = msg.userId == (supabase.auth.currentUser?.id ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(msg.userId.isNotEmpty ? msg.userId.substring(0, 1).toUpperCase() : '?'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOwn ? Colors.blue.shade700 : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Primeira mensagem abre chat!', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Mensagem...',
                      hintStyle: TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black87,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
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
