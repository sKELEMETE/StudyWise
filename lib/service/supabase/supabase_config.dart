import 'package:supabase_flutter/supabase_flutter.dart';
import '../env_service.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: EnvService.supabaseUrl,
      anonKey: EnvService.supabaseAnonKey,
    );
  }
}
