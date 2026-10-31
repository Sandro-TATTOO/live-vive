import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'host_live_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Text('Viewer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final titleController = TextEditingController(text: 'Minha Live');
                final hostIdController = TextEditingController(text: 'host_1');
                final result = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Iniciar Live (Host)'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titulo')),
                        TextField(controller: hostIdController, decoration: const InputDecoration(labelText: 'Host ID')),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, {
                          'title': titleController.text,
                          'hostId': hostIdController.text,
                        }),
                        child: const Text('Iniciar'),
                      ),
                    ],
                  ),
                );
                if (result != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HostLiveScreen(
                        title: result['title']!,
                        hostId: result['hostId']!,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Host'),
            ),
          ],
        ),
      ),
    );
  }
}

