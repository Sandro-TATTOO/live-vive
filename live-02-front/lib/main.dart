import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'screens/role_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Supabase SEM auth anônima
  await Supabase.initialize(
    url: 'https://ircmrwpshelypddkbaye.supabase.co',
    anonKey: 'sb_publishable_-U0PInJIeFofQ2gyZB4Vbg_mpbBKRe7',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => SupabaseConfig(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Puro - Live',
      theme: ThemeData.dark(),
      home: const RoleSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

