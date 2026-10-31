import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestWSScreen extends StatefulWidget {
  const TestWSScreen({super.key});

  @override
  State<TestWSScreen> createState() => _TestWSScreenState();
}

class _TestWSScreenState extends State<TestWSScreen> {
  final supabase = Supabase.instance.client;
  String status = 'Disconnected';
  String error = '';
  final List<String> logs = [];

  @override
  void initState() {
    super.initState();
    _testRealtime();
  }

  void _addLog(String msg) {
    setState(() {
      logs.add(
          '${DateTime.now().toIso8601String().split('T')[1].split('.')[0]}: $msg');
      if (logs.length > 20) logs.removeAt(0);
    });
  }

  void _testRealtime() async {
    try {
      final channel = supabase.channel('test-channel');

      channel.subscribe((status, err) {
        _addLog('Status: $status');
        if (err != null) {
          _addLog('Erro: $err');
          setState(() {
            error = err.toString();
          });
        } else {
          setState(() {
            error = '';
            this.status = status.toString();
          });
        }
      });

      // Teste postgres_changes
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          _addLog(
              'Realtime CHANGE: ${payload.eventType} - ${payload.newRecord}');
        },
      );

      _addLog('✅ Channel subscrito!');
    } catch (e) {
      _addLog('❌ Init erro: $e');
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Teste WS/Supabase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                logs.clear();
                status = 'Disconnected';
                error = '';
              });
              _testRealtime();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $status',
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (error.isNotEmpty)
                      Text('Erro: $error',
                          style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      title: Text(logs[index]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
