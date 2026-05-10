class EnvService {
  static Future<void> init() async {}

  static String get supabaseUrl {
    const value = String.fromEnvironment('SUPABASE_URL');
    if (value.isEmpty) {
      throw Exception('SUPABASE_URL is missing.');
    }
    return value;
  }

  static String get supabaseAnonKey {
    const value = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (value.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is missing.');
    }
    return value;
  }
}