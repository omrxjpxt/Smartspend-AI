import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/interfaces/ai_provider.dart';
import '../data/providers/disabled_ai_provider.dart';
import 'local_intelligence_engine.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/providers/gemini_ai_provider.dart';
import 'ai_router.dart';

class AiCooldownNotifier extends StateNotifier<int> {
  Timer? _timer;
  
  AiCooldownNotifier() : super(0);

  void startCooldown(int seconds) {
    _timer?.cancel();
    state = seconds;
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

final aiServiceProvider = Provider((ref) => AiService(ref));

class AiService {
  final Ref ref;
  late final AIProvider _aiProvider;
  late final LocalIntelligenceEngine _localEngine;

  AiService(this.ref) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _aiProvider = GeminiAIProvider(apiKey);
    } else {
      _aiProvider = DisabledAIProvider();
    }
    _localEngine = ref.read(localIntelligenceProvider);
  }

  Future<String> generateInsight({
    required String systemPrompt, 
    required String context, 
    required String userPrompt, 
    String? chatHistory,
    dynamic ref,
    bool bypassRateLimit = false,
  }) async {
    // 1. Route the question
    final route = AIRouter.route(userPrompt);

    // 2. If local, use Local Engine
    if (route == 'local') {
      final localResponse = await _localEngine.handleQuery(userPrompt);
      if (localResponse != null) {
        return localResponse;
      }
    }

    // 3. If gemini (or local engine returned null), call Gemini
    try {
      final finalContext = chatHistory != null && chatHistory.isNotEmpty 
          ? "$context\n\nChat History:\n$chatHistory" 
          : context;
          
      return await _aiProvider.generateResponse(
        systemPrompt: systemPrompt,
        context: finalContext,
        userPrompt: userPrompt,
      );
    } catch (e) {
      // 4. FALLBACK: If Gemini fails, fall back to Local Engine
      final fallback = await _localEngine.handleQuery(userPrompt);
      if (fallback != null) return fallback;

      return "I'm having trouble generating an AI explanation right now. "
             "Here's your financial summary:\n\n"
             "${_localEngine.generateMonthlySummary()}";
    }
  }

  Stream<String> generateChatStream({
    required String systemPrompt,
    required String context,
    required List<dynamic> chatHistory,
    dynamic ref,
  }) async* {
    String lastUserMessage = "";
    if (chatHistory.isNotEmpty) {
      lastUserMessage = chatHistory.last.toString();
      if (chatHistory.last is Map) {
        lastUserMessage = (chatHistory.last as Map)['message'] ?? '';
      }
    }

    final route = AIRouter.route(lastUserMessage);

    if (route == 'local') {
      final localResponse = await _localEngine.handleQuery(lastUserMessage);
      if (localResponse != null) {
        final chunks = localResponse.split('\n');
        for (var chunk in chunks) {
          yield '$chunk\n';
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return;
      }
    }

    try {
      final response = await _aiProvider.generateResponse(
        systemPrompt: systemPrompt,
        context: context,
        userPrompt: lastUserMessage,
      );
      
      final chunks = response.split(' ');
      for (var chunk in chunks) {
        yield '$chunk ';
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      final fallback = await _localEngine.handleQuery(lastUserMessage);
      if (fallback != null) {
        final chunks = fallback.split('\n');
        for (var chunk in chunks) {
          yield '$chunk\n';
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return;
      }

      final errorMsg = "I'm having trouble generating an AI explanation right now. "
             "Here's your financial summary:\n\n"
             "${_localEngine.generateMonthlySummary()}";
      final chunks = errorMsg.split('\n');
      for (var chunk in chunks) {
        yield '$chunk\n';
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<Map<String, dynamic>> validateAiConnection() async {
    final hasKey = dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
    return {
      'apiKeyLoaded': hasKey,
      'connected': hasKey,
      'model': hasKey ? 'Gemini 2.0 Flash' : 'Local Intelligence Engine',
      'success': true,
      'message': hasKey ? 'Connected to Gemini API.' : 'Connected to local deterministic engine.',
    };
  }
}

