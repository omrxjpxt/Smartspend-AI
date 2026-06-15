import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("API KEY IS MISSING in .env");
      return;
    }
    
    print("API Key detected: true");
    
    final modelNames = ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-2.0-flash'];
    
    for (var name in modelNames) {
      try {
        print("Testing model: $name");
        final model = GenerativeModel(model: name, apiKey: apiKey);
        final response = await model.generateContent([Content.text("Say hello")]);
        print("Response from $name: ${response.text}");
      } catch (e) {
        print("Error from $name: $e");
      }
    }
  } catch (e) {
    print("Error loading .env: $e");
  }
}
