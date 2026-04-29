import 'package:groq/groq.dart';
import '../../../service/groq_ai/groq_config.dart';

class GroqDataSource {
  final Groq _groq = GroqAIConfig.createClient();

  Future<String> generateFromText(String text) async {
    _groq.startChat();

    final prompt = """
You are a helpful assistant.

Summarize this content clearly:

$text
""";

    final response = await _groq.sendMessage(prompt);

    return response.choices.first.message.content;
  }
}