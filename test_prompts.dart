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

  final modelName = 'gemini-pro';
  final model = GenerativeModel(model: modelName, apiKey: apiKey);

  final prompts = [
    'Hello',
    'Analyze my spending',
    'Give saving tips',
    'How much did I spend this month?'
  ];

  print('Testing model $modelName...');
  for (final prompt in prompts) {
    print('\n--- Prompt: "$prompt" ---');
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      print('Response: ${response.text?.replaceAll('\n', ' ')}');
    } catch (e) {
      print('Error: $e');
    }
  }
  exit(0);
}
