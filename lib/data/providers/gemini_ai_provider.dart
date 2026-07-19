import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/interfaces/ai_provider.dart';

class GeminiAIProvider implements AIProvider {
  final GenerativeModel _model;

  GeminiAIProvider(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
        );

  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String context,
    required String userPrompt,
  }) async {
    print("\n=========== GEMINI REQUEST ===========");
    print("Question: $userPrompt");
    print("Context Length: ${context.length}");
    print("Model Name: gemini-2.5-flash");
    print("Time Started: ${DateTime.now()}");
    print("======================================");

    final stopWatch = Stopwatch()..start();

    try {
      final response = await _model.generateContent([
        Content.text('$systemPrompt\n\nFinancial Context:\n$context'),
        Content.text(userPrompt),
      ]);
      
      stopWatch.stop();

      print("\n=========== GEMINI RESPONSE ===========");
      print("Latency: ${stopWatch.elapsedMilliseconds}ms");
      print("Candidates: ${response.candidates.length}");
      print("Finish Reason: ${response.candidates.firstOrNull?.finishReason}");
      print("Safety Blocks: ${response.promptFeedback?.safetyRatings}");
      print("Token Usage: ${response.usageMetadata?.totalTokenCount}");
      print("Raw Text: ${response.text}");
      print("=======================================");

      if (response.text == null || response.text!.isEmpty) {
        print("Finish Reason: ${response.candidates.firstOrNull?.finishReason}");
        print("Candidates: ${response.candidates.length}");
        print("Safety: ${response.promptFeedback?.safetyRatings}");
        print("Prompt Feedback: ${response.promptFeedback}");
      }

      return response.text ?? 'I was unable to generate a response.';
    } catch (e, stack) {
      stopWatch.stop();
      print("\n========== GEMINI ERROR ==========");
      print(e);
      print(stack);
      print("==================================");
      
      // Determine error type
      if (e.toString().contains('API key not valid') || e.toString().contains('API_KEY_INVALID')) {
        print("Exact reason: Invalid API key");
      } else if (e.toString().contains('quota')) {
        print("Exact reason: Quota exceeded");
      } else if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        print("Exact reason: Network/HTTP failure");
      } else if (e.toString().contains('Timeout')) {
        print("Exact reason: Timeout");
      } else if (e.toString().contains('Model not found')) {
        print("Exact reason: Model unavailable");
      } else if (e.toString().contains('FormatException')) {
        print("Exact reason: JSON parsing");
      } else {
        print("Exact reason: Unknown / SDK bug / Safety block");
      }
      
      rethrow;
    }
  }
}
