import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print("Loading environment...");
  await dotenv.load(fileName: ".env");

  final apiKey = dotenv.env['GEMINI_API_KEY'];
  print("Environment Loaded");
  print("API Key Exists: \${apiKey != null && apiKey.isNotEmpty}");
  if (apiKey != null) {
    print("API Key Length: \${apiKey.length}");
    print("API Key Prefix: \${apiKey.substring(0, 6)}");
  }

  if (apiKey == null || apiKey.isEmpty) {
    print("Error: Missing API key");
    return;
  }

  print("\n=========== GEMINI REQUEST ===========");
  print("Question: Say Hello.");
  print("Model Name: gemini-2.5-flash"); // As requested by user
  print("Time Started: \${DateTime.now()}");
  print("======================================");

  try {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final response = await model.generateContent([
      Content.text('Say Hello.'),
    ]);

    print("\n=========== GEMINI RESPONSE ===========");
    print("Candidates: \${response.candidates.length}");
    print("Finish Reason: \${response.candidates.first.finishReason}");
    print("Safety Blocks: \${response.promptFeedback?.safetyRatings}");
    print("Raw Text: \${response.text}");
    print("=======================================");
  } catch (e, stack) {
    print("\n========== GEMINI ERROR ==========");
    print(e);
    print(stack);
    print("==================================");
  }
}
