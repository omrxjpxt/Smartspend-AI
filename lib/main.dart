import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await dotenv.load(fileName: ".env");
    print("\nEnvironment Loaded");
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    print("API Key Exists: ${apiKey != null && apiKey.trim().isNotEmpty}");
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      print("API Key Length: ${apiKey.length}");
      print("First 6 characters: ${apiKey.substring(0, 6)}");
    }
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }
  runApp(const ProviderScope(child: SmartSpendApp()));
}
