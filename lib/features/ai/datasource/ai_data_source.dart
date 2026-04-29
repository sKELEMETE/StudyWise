import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqDataSource {
  final String apiKey;
  final String endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  GroqDataSource({required this.apiKey});

  Future<String> summarizeText(String rawText) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final prompt = '''
You are an expert educator with 20+ years of experience.
Summarize the text provided below.
Use simple, clear language.
Provide practical examples.
Incorporate active learning methods.
Ask the reader a question to test their understanding.
Output pure summary.
Do not include conversational filler.

Text to summarize:
$rawText
''';

    final body = jsonEncode({
      'model': 'llama3-8b-8192',
      'messages': [
        {'role': 'system', 'content': 'You provide strict, pure summaries.'},
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
    });

    final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiOutput = data['choices'][0]['message']['content'];
      print('GROQ AI OUTPUT:');
      print(aiOutput);
      return aiOutput;
    } else {
      throw Exception('Failed to generate summary.');
    }
  }
}