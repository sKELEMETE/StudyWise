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

enum OutputFormat { paragraph, bullet }
enum Difficulty { easy, medium }

class GroqDataSource {
  final String apiKey;

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String model = 'llama-3.1-8b-instant';

  GroqDataSource({required this.apiKey});

  Future<String> summarizeText(
    String rawText, {
    OutputFormat format = OutputFormat.paragraph,
    Difficulty difficulty = Difficulty.easy,
    String language = 'English',
  }) async {
    if (rawText.trim().isEmpty) {
      throw Exception('Input text is empty');
    }

    final cleanedText = _cleanText(rawText);
    final chunks = _splitIntoChunks(cleanedText, 1500);

    List<String> summaries = [];

    for (final chunk in chunks) {
      final prompt = _buildChunkPrompt(
        chunk,
        format: format,
        difficulty: difficulty,
        language: language,
      );

      final result = await _callGroq(prompt);
      summaries.add(result);
    }

    if (summaries.length == 1) {
      return summaries.first;
    }

    final mergedPrompt = _buildMergePrompt(
      summaries,
      format: format,
      difficulty: difficulty,
      language: language,
    );

    return await _callGroq(mergedPrompt);
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  List<String> _splitIntoChunks(String text, int maxLength) {
    List<String> chunks = [];
    int start = 0;

    while (start < text.length) {
      int end = start + maxLength;
      if (end > text.length) end = text.length;

      chunks.add(text.substring(start, end));
      start = end;
    }

    return chunks;
  }

  String _difficultyRule(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Use very simple words. Short sentences.';
      case Difficulty.medium:
        return 'Use clear words. Slight detail allowed.';
    }
  }

  String _formatRule(OutputFormat format) {
    switch (format) {
      case OutputFormat.paragraph:
        return '''
Write in paragraph form.
Include explanation and example in the same paragraph.
''';
      case OutputFormat.bullet:
        return '''
Use this format:

Topic:
- Explanation
- Key points
- Example
''';
    }
  }

  String _buildChunkPrompt(
    String text, {
    required OutputFormat format,
    required Difficulty difficulty,
    required String language,
  }) {
    return '''
Summarize clearly.

Rules:
- ${_difficultyRule(difficulty)}
- Use $language language
- Break into sections if topics change
- One example per topic
- No filler

${_formatRule(format)}

Text:
$text
''';
  }

  String _buildMergePrompt(
    List<String> summaries, {
    required OutputFormat format,
    required Difficulty difficulty,
    required String language,
  }) {
    final combined = summaries.join('\n\n');

    return '''
Combine and simplify.

Rules:
- ${_difficultyRule(difficulty)}
- Use $language language
- Merge similar ideas
- Keep structure if topics differ
- Add one final question

${_formatRule(format)}

Summaries:
$combined
''';
  }

  Future<String> _callGroq(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a teacher explaining to a beginner. Be clear and direct.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.2,
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