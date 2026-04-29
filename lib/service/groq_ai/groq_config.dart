import 'package:groq/groq.dart';
import '../env_service.dart';

class GroqAIConfig {
  static final Configuration config = Configuration(
    model: "qwen/qwen3-32b",
    temperature: 0.7,
    seed: 10,
  );

  static Groq createClient() {
    final apiKey = EnvService.groqApiKey;

    if (apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY is missing');
    }

    return Groq(
      apiKey: apiKey,
      configuration: config,
    );
  }
}