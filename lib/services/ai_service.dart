import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/interfaces/ai_provider.dart';
import '../data/providers/disabled_ai_provider.dart';
import 'local_intelligence_engine.dart';
import 'dart:async';

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
  final ProviderRef ref;
  late final AIProvider _aiProvider;
  late final LocalIntelligenceEngine _localEngine;

  AiService(this.ref) {
    _aiProvider = DisabledAIProvider();
    _localEngine = ref.read(localIntelligenceProvider);
  }

  Future<String> generateInsight({
    required String systemPrompt, 
    required String context, 
    required String userPrompt, 
    dynamic ref,
    bool bypassRateLimit = false,
  }) async {
    // 1. Try Local Engine first
    final localResponse = await _localEngine.handleQuery(userPrompt);
    if (localResponse != null) {
      return localResponse;
    }

    // 2. Fallback to AI Provider
    return await _aiProvider.generateResponse(
      systemPrompt: systemPrompt,
      context: context,
      userPrompt: userPrompt,
    );
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
      // Hack for dynamic objects coming from chat screen since Content is gone.
      if (chatHistory.last is Map) {
        lastUserMessage = (chatHistory.last as Map)['message'] ?? '';
      }
    }

    final localResponse = await _localEngine.handleQuery(lastUserMessage);
    if (localResponse != null) {
      final chunks = localResponse.split('\n');
      for (var chunk in chunks) {
        yield chunk + '\n';
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    final response = await _aiProvider.generateResponse(
      systemPrompt: systemPrompt,
      context: context,
      userPrompt: lastUserMessage,
    );
    
    final chunks = response.split(' ');
    for (var chunk in chunks) {
      yield chunk + ' ';
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<Map<String, dynamic>> validateAiConnection() async {
    return {
      'apiKeyLoaded': false,
      'connected': true,
      'model': 'Local Intelligence Engine',
      'success': true,
      'message': 'Connected to local deterministic engine.',
    };
  }
}
