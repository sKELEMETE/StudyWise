import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_URL is missing in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is missing in .env');
    }
    return value;
  }

  static String get groqApiKey {
    final value = dotenv.env['GROQ_API_KEY'];
    if (value == null || value.isEmpty) {
      throw Exception('GROQ_API_KEY is missing in .env');
    }
    return value;
  }
}