import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/ai_service.dart';
import 'dart:ui';

class ChatInput extends ConsumerStatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInput({
    super.key, 
    required this.onSend,
    this.isLoading = false,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _handleSend() {
    final cooldown = ref.read(aiCooldownProvider);
    if (cooldown > 0) return;

    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
      if (_isListening) {
        _speech.stop();
        setState(() => _isListening = false);
      }
    }
  }

  void _toggleListening() async {
    final cooldown = ref.read(aiCooldownProvider);
    if (cooldown > 0 || widget.isLoading) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: ${errorNotification.errorMsg}')),
            );
          }
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone access denied or speech recognition unavailable.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = ref.watch(aiCooldownProvider);
    final isBlocked = cooldown > 0 || widget.isLoading;
    final hintText = cooldown > 0 
        ? 'Wait $cooldown seconds...' 
        : _isListening 
            ? 'Listening...' 
            : 'Ask your financial AI...';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !isBlocked,
                            onSubmitted: (_) => _handleSend(),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cooldown > 0 ? AppColors.negative : AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? AppColors.negative.withValues(alpha: 0.2) : Colors.transparent,
                            ),
                            child: Icon(
                              cooldown > 0 ? Icons.timer : (_isListening ? Icons.mic : Icons.mic_none), 
                              color: cooldown > 0 
                                  ? AppColors.negative 
                                  : (_isListening ? AppColors.negative : AppColors.textSecondary)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isBlocked ? AppColors.textSecondary : AppColors.accentAI,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isLoading 
                      ? const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(cooldown > 0 ? Icons.hourglass_empty : Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
