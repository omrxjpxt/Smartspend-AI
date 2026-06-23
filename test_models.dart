import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  
  if (apiKey == null || apiKey.isEmpty) {
    print('No API key found in .env');
    exit(1);
  }

  final modelsToTest = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.0-pro',
    'gemini-pro',
  ];

  for (final modelName in modelsToTest) {
    print('Testing model: $modelName');
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final content = [Content.text('Say hello.')];
      final response = await model.generateContent(content);
      print('SUCCESS with $modelName: ${response.text}');
    } catch (e) {
      print('FAILED with $modelName: $e');
    }
    print('---');
  }
  exit(0);
}
