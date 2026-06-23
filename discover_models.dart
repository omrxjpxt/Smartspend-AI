import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY is not set in .env');
    return;
  }

  print('Discovering models...');
  
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List<dynamic>;
      
      print('--- Available Models ---');
      for (var model in models) {
        final name = model['name'];
        final supportedGenerationMethods = model['supportedGenerationMethods'];
        print('- Name: $name');
        print('  Supported Methods: $supportedGenerationMethods');
      }
    } else {
      print('Failed to load models. Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error discovering models: $e');
  }
}
