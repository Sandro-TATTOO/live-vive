import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPuro extends StatefulWidget {
  const ChatPuro({super.key});

  @override
  State<ChatPuro> createState() => _ChatPuroState();
}

class _ChatPuroState extends State<ChatPuro> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _messages = [];
  String? _error;
  final GlobalKey _errorKey = GlobalKey();
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      // Tenta signIn anônimo se não autenticado
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
        print('✅ User anônimo: ${supabase.auth.currentUser?.id}');
      }
      
      _listenMessages();
      _checkConnection();
    } catch (e) {
      print('❌ Auth erro: $e');
      setState(() {
        _error = 'Auth erro: $e';
      });
    }
  }

  Future<void> _checkConnection() async {
    try {
      await supabase.from('messages').select('count').limit(1);
      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Supabase erro: ${e.toString()}';
      });
    }
  }

  void _copyError() {
    final errorText = _error ?? '';
    Clipboard.setData(ClipboardData(text: errorText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erro copiado! 📋'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _listenMessages() {
    if (_isSubscribed) return;
    
    final channel = supabase.channel('chat-public');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        print('🔥 Realtime: ${payload.newRecord}');
      },
    ).subscribe((status, error) {
      print('Status: $status');
      if (error != null) {
        print('Sub erro: $error');
      } else {
        setState(() {
          _isSubscribed = true;
        });
      }
    });

    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen(
          (data) {
            setState(() {
              _messages = data;
            });
            _scrollToBottom();
          },
          onError: (error) {
            setState(() {
              _error = 'Stream erro: $error';
            });
          },
        );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Autentique primeiro')),
      );
      return;
    }

    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('messages').insert({
        'message': _controller.text.trim(),
        'user_id': userId,
        'stream_id': 1,
      });
      
      print('📤 Enviada por $userId: "${_controller.text.trim()}"');
      _controller.clear();
    } catch (e) {
      print('❌ ERRO: $e');
      setState(() {
        _error = 'Send erro: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $e'),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id ?? 'não autenticado';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Puro ($userId)'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initAuth,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              key: _errorKey,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red, 
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.red),
                    tooltip: 'Copiar erro',
                    onPressed: _copyError,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '👋 Bem-vindo ao Chat Puro!\n\nAguardando mensagens...',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _initAuth,
                          child: const Text('🔄 Reconectar'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final msgUserId = msg['user_id']?.toString() ?? 'anon';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        color: msgUserId == userId 
                          ? Colors.blue.shade50 
                          : Colors.grey.shade50,
                        child: ListTile(
                          title: Text(msg['message'] ?? ''),
                          subtitle: Text(
                            '${msgUserId.substring(0,8)}... • '
                            '${msg['created_at']?.toString().split('T')[1].split('.')[0] ?? ''}',
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade200,
                            child: Text(
                              msgUserId.isNotEmpty ? msgUserId[0].toUpperCase() : 'A',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem... (User: $userId)',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 30),
                  onPressed: _sendMessage,
                  tooltip: 'Enviar',
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

