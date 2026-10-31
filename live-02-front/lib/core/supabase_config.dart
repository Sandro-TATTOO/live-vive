import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig extends ChangeNotifier {
  late final SupabaseClient supabase;

  SupabaseConfig() {
    // SUBSTITUA pelos seus valores reais
    const url = 'YOUR_SUPABASE_URL';
    const anonKey = 'YOUR_SUPABASE_ANON_KEY';

    supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  // Remove signInAnônimo - só init
  void init() {
    // Cliente pronto
    print('✅ Supabase init OK');
  }

  // Para teste sem auth
  Future<bool> testConnection() async {
    try {
      final response = await supabase
        .from('messages')
        .select('id')
        .limit(1)
        .maybeSingle();
      print('✅ Supabase conectado: $response');
      return true;
    } catch (e) {
      print('❌ Supabase erro: $e');
      return false;
    }
  }
}

