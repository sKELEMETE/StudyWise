import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studywise/service/env_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OutputFormat { paragraph, bullet }
enum Difficulty { easy, medium }

class GroqDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<String> generateQuizJson({
    required String rawText,
    required String mode,
    required int count,
  }) async {
    if (rawText.trim().isEmpty) {
      throw Exception('No readable text was found in this folder.');
    }

    final cleanedText = _cleanText(rawText);
    final quizText = cleanedText.length > 14000
        ? cleanedText.substring(0, 14000)
        : cleanedText;

    final prompt = mode == 'multiple_choice'
        ? _buildMultipleChoicePrompt(quizText, count)
        : _buildFlashcardPrompt(quizText, count);

    return await _callGroq(prompt, temperature: 0.35);
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

  String _buildMultipleChoicePrompt(String text, int count) {
    return '''
Create a multiple choice quiz from the study material only.

Rules:
- Use only facts from the provided study material
- Return valid JSON only, with no markdown
- Create up to $count questions
- Each question must have exactly 4 options
- correctIndex must be 0, 1, 2, or 3
- Include one short hint that helps without giving away the answer
- Do not invent facts if the material is insufficient

JSON shape:
{
  "questions": [
    {
      "question": "Question text",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctIndex": 0,
      "hint": "Short hint"
    }
  ]
}

Study material:
$text
''';
  }

  String _buildFlashcardPrompt(String text, int count) {
    return '''
Create flashcards from the study material only.

Rules:
- Use only facts from the provided study material
- Return valid JSON only, with no markdown
- Create up to $count flashcards
- Each flashcard has front and back only
- Keep front short and back clear
- Do not invent facts if the material is insufficient

JSON shape:
{
  "cards": [
    {
      "front": "Prompt or term",
      "back": "Answer or explanation"
    }
  ]
}

Study material:
$text
''';
  }

  Future<String> _callGroq(
    String prompt, {
    double temperature = 0.2,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User authentication required');

    final headers = {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'prompt': prompt,
      'temperature': temperature,
    });

    final uri = Uri.parse('${EnvService.supabaseUrl}/functions/v1/groq_ai');
    final response = await http
        .post(
          uri,
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final aiOutput = data['output']?.toString() ?? '';

      if (aiOutput.isEmpty) {
        throw Exception('Empty response from Groq');
      }

      return aiOutput.trim();
    } else {
      throw Exception(_errorMessageFromResponse(response.body));
    }
  }

  String _errorMessageFromResponse(String body) {
    try {
      final data = jsonDecode(body);
      final message = data['error']?.toString().trim() ?? '';
      if (message.isNotEmpty && message.length <= 120) return message;
    } catch (_) {}

    return 'AI service is unavailable right now.';
  }
}
