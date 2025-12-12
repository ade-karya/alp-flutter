import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class GeminiOpenAIService {
  static const String _defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai';

  Future<String> generateContent({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    String? baseUrl,
  }) async {
    final effectiveBaseUrl = baseUrl ?? _defaultBaseUrl;
    final url = Uri.parse('$effectiveBaseUrl/chat/completions');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
            }),
          )
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception(
          'Failed to generate content: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error generating content: $e');
    }
  }

  Future<List<String>> fetchModels(String apiKey, {String? baseUrl}) async {
    final effectiveBaseUrl = baseUrl ?? _defaultBaseUrl;
    final url = Uri.parse('$effectiveBaseUrl/models');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['data'] ?? [];
        return models.map<String>((m) => m['id'] as String).toList();
      } else {
        throw Exception(
          'Failed to fetch models: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }
}
