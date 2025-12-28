import 'dart:convert';
import '../../../core/services/gemini_openai_service.dart';

class AIAgentService {
  final GeminiOpenAIService _aiService;

  AIAgentService(this._aiService);

  static const String systemPrompt = '''
You are an AI App Agent for the "Sikolah Apps" educational platform. 
Your goal is to help teachers perform tasks within the application using natural language.

CURRENT SUPPORTED ACTIONS:
1. CREATE_CLASS:
   - When a user wants to create a new class.
   - Required parameters: "name" (string).
   - Optional parameters: "description" (string).
   - Output format: {"action": "CREATE_CLASS", "params": {"name": "...", "description": "..."}}

2. ANALYZE_LEARNING:
   - When a user wants to analyze student learning outcomes or see their scores.
   - Optional parameters: "class" (string), "subject" (string).
   - Output format: {"action": "ANALYZE_LEARNING", "params": {"class": "...", "subject": "..."}}

INSTRUCTIONS:
- If the user's request matches a supported action, extract the parameters and return ONLY a JSON object in the specified format.
- If parameters are missing but the intent is clear, you can ask for the missing parameters conversationally (return a string instead of JSON).
- If the intent is not clear or not supported, respond politely and explain what you can do.
- ALWAYS return the JSON block if the intent and required parameters are present.
- Do NOT include any markdown formatting if you are returning JSON, just the raw JSON string.
- If you are responding conversationally, do NOT return JSON.

Example User Input: "Buatkan kelas baru Matematika Dasar untuk kelas 7"
Example Output: {"action": "CREATE_CLASS", "params": {"name": "Matematika Dasar", "description": "untuk kelas 7"}}

Example User Input: "Halo, apa kabar?"
Example Output: "Halo! Saya adalah asisten AI Anda. Saya dapat membantu Anda membuat kelas baru dengan cepat. Ada yang bisa saya bantu?"
''';

  Future<dynamic> processCommand({
    required String apiKey,
    required String model,
    required String userMessage,
    String? baseUrl,
  }) async {
    final response = await _aiService.generateContent(
      apiKey: apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      baseUrl: baseUrl,
    );

    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        return jsonDecode(trimmed);
      } catch (e) {
        // If it looks like JSON but fails to decode, return as plain text
        return trimmed;
      }
    }
    return trimmed;
  }
}
