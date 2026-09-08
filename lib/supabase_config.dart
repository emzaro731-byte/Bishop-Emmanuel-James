import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
