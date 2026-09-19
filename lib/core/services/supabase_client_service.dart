import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Singleton access to the Supabase client.
///
/// Call [init] once in main() before runApp().
class SupabaseClientService {
  SupabaseClientService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized {
    try {
      // Will throw if Supabase.initialize() was never called.
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}
