import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger(
  printer: SimplePrinter(colors: true),
);

void logBlock(String label, String value) {
  logger.i('---------- $label START ----------');
  logger.i(value);
  logger.i('---------- $label END ----------');
}

class GroqDataSource {
  final String apiKey;

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String model = 'llama-3.1-8b-instant';

  GroqDataSource({required this.apiKey});

  Future<String> summarizeText(String rawText) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final prompt = '''
Summarize the text below in a clear and simple way.

Rules:
- Use simple language
- Give a practical example
- Include one question to test understanding
- No filler or extra commentary
- Answer in paragraph

Text:
$rawText
''';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are an expert educator who gives concise summaries.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.3,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final aiOutput =
          data['choices']?[0]?['message']?['content']?.toString() ?? '';

      if (aiOutput.isEmpty) {
        throw Exception('Empty response from Groq');
      }

      logBlock('RAW TEXT', rawText);
      logBlock('PROMPT', prompt);
      logBlock('AI OUTPUT', aiOutput);

      return aiOutput.trim();
    } else {
      logger.e('Groq API Error: ${response.statusCode}');
      logger.e(response.body);

      throw Exception(
        'Groq API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }
}