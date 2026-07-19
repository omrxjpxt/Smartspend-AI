import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/interfaces/ai_provider.dart';

class GeminiAIProvider implements AIProvider {
  final GenerativeModel _model;

  GeminiAIProvider(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );

  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String context,
    required String userPrompt,
  }) async {
    final response = await _model.generateContent([
      Content.text('$systemPrompt\n\nFinancial Context:\n$context'),
      Content.text(userPrompt),
    ]);
    return response.text ?? 'I was unable to generate a response.';
  }
}
