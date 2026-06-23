import '../../domain/interfaces/ai_provider.dart';

class DisabledAIProvider implements AIProvider {
  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String context,
    required String userPrompt,
  }) async {
    // Artificial delay to simulate processing
    await Future.delayed(const Duration(milliseconds: 800));
    return "Advanced AI advice is currently unavailable. I am only able to provide analysis of your immediate financial data at this time.";
  }
}
