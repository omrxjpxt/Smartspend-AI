abstract class AIProvider {
  Future<String> generateResponse({
    required String systemPrompt,
    required String context,
    required String userPrompt,
  });
}
