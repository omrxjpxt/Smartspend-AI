import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider((ref) => AiService());

class AiCooldownNotifier extends StateNotifier<int> {
  Timer? _timer;
  
  AiCooldownNotifier() : super(0);

  void startCooldown(int seconds) {
    state = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final aiCooldownProvider = StateNotifierProvider<AiCooldownNotifier, int>((ref) {
  return AiCooldownNotifier();
});

class _CacheEntry {
  final String response;
  final DateTime timestamp;
  _CacheEntry(this.response, this.timestamp);
}

class AiService {
  GenerativeModel? _model;
  
  // Rate Limit Sliding Windows
  final List<DateTime> _minuteWindow = [];
  final List<DateTime> _hourWindow = [];

  // Cache to store identical requests: hash(prompt + context) -> _CacheEntry
  final Map<String, _CacheEntry> _cache = {};

  AiService() {
    _initModel();
  }

  void _initModel() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );
      }
    } catch (e) {
      debugPrint('Failed to initialize AI model: $e');
    }
  }

  String _generateCacheKey(String prompt, String context) {
    final bytes = utf8.encode(prompt + context);
    return sha256.convert(bytes).toString();
  }

  void _cleanWindows() {
    final now = DateTime.now();
    _minuteWindow.removeWhere((t) => now.difference(t).inSeconds >= 60);
    _hourWindow.removeWhere((t) => now.difference(t).inMinutes >= 60);
  }

  int _getSecondsUntilNextRequest() {
    _cleanWindows();
    if (_minuteWindow.length >= 10) {
      return 60 - DateTime.now().difference(_minuteWindow.first).inSeconds;
    }
    if (_hourWindow.length >= 100) {
      return 3600 - DateTime.now().difference(_hourWindow.first).inSeconds;
    }
    return 0;
  }

  void _recordRequest() {
    final now = DateTime.now();
    _minuteWindow.add(now);
    _hourWindow.add(now);
  }

  Future<String> generateInsight({
    required String systemPrompt, 
    required String context, 
    required String userPrompt, 
    dynamic ref,
    bool bypassRateLimit = false, // Sometimes we might want to bypass (e.g. initial silent fetch)
  }) async {
    // Attempt re-init if API key was added later
    if (_model == null) _initModel();

    if (_model == null) {
      return "AI is currently unavailable. Please check your API key in .env.";
    }

    final cacheKey = _generateCacheKey(userPrompt, context);
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp).inMinutes < 30) {
        debugPrint("--- AI CACHE HIT ---");
        return entry.response;
      } else {
        _cache.remove(cacheKey); // Expired
      }
    }

    debugPrint("--- AI CACHE MISS - Gemini request sent ---");

    final currentCooldown = ref.read(aiCooldownProvider);
    if (!bypassRateLimit && currentCooldown > 0) {
      return "Too many requests. Try again in $currentCooldown seconds.";
    }

    if (!bypassRateLimit) {
      final waitSeconds = _getSecondsUntilNextRequest();
      if (waitSeconds > 0) {
        ref.read(aiCooldownProvider.notifier).startCooldown(waitSeconds);
        return "Too many requests. Try again in $waitSeconds seconds.";
      }
    }

    final fullPrompt = '''
$systemPrompt

--- USER FINANCIAL DATA ---
$context

--- USER PROMPT ---
$userPrompt
''';

    try {
      if (!bypassRateLimit) {
        _recordRequest();
      }

      final response = await _model!.generateContent(
        [Content.text(fullPrompt)],
      ).timeout(const Duration(seconds: 15));

      final result = response.text ?? "I couldn't process that. Please try again.";
      _cache[cacheKey] = _CacheEntry(result, DateTime.now());
      return result;
    } on TimeoutException {
      return "Connection timeout. Try again.";
    } catch (e) {
      debugPrint("AI Request Error: $e");
      if (kDebugMode) {
        return "Gemini API Error:\n$e";
      }
      return "AI is currently unavailable. Please try again later.";
    }
  }

  // A method for generating streams if needed for chat
  Stream<String> generateChatStream({
    required String systemPrompt,
    required String context,
    required List<Content> chatHistory,
    dynamic ref,
  }) async* {
    if (_model == null) _initModel();
    if (_model == null) {
      yield "AI is currently unavailable.";
      return;
    }

    final currentCooldown = ref.read(aiCooldownProvider);
    if (currentCooldown > 0) {
      yield "Too many requests. Try again in $currentCooldown seconds.";
      return;
    }

    final waitSeconds = _getSecondsUntilNextRequest();
    if (waitSeconds > 0) {
      ref.read(aiCooldownProvider.notifier).startCooldown(waitSeconds);
      yield "Too many requests. Try again in $waitSeconds seconds.";
      return;
    }

    try {
      _recordRequest();

      final chat = _model!.startChat(history: chatHistory);
      
      final enhancedPrompt = '''
$systemPrompt

--- USER FINANCIAL DATA ---
$context
''';

      // We prepend the financial context silently as part of the new message.
      final responseStream = chat.sendMessageStream(Content.text(enhancedPrompt));
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } on TimeoutException {
      yield "Connection timeout. Try again.";
    } catch (e) {
      debugPrint("AI Stream Error: $e");
      if (kDebugMode) {
        yield "Gemini API Error:\n$e";
      } else {
        yield "AI is currently unavailable.";
      }
    }
  }
}
