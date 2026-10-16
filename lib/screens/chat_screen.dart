import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/listening_view.dart';
import '../widgets/you_said_strip.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Chatbot',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [LanguageDropdown(c: c), const SizedBox(width: 12)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  final extra = c.isTyping.value ? 1 : 0;
                  return ListView.builder(
                    controller: c.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    itemCount: c.messages.length + extra,
                    itemBuilder: (_, i) => i == c.messages.length
                        ? const _TypingBubble()
                        : _Bubble(message: c.messages[i]),
                  );
                }),
                Obx(() => c.isListening.value
                    ? Positioned.fill(child: ListeningView(c: c))
                    : const SizedBox.shrink()),
              ],
            ),
          ),
          YouSaidStrip(c: c),
          _InputBar(c: c),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.botBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // English text
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: isUser ? Colors.white : const Color(0xFF1C2523),
              ),
            ),

            // NEW: original text (Khmer or other language) under the English
            if (isUser && message.original != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.original!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),

            // segment titles (task 3): delete this block if you removed segments
            for (final s in message.segments)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${s.title} · ${s.timeLabel}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.botBubble,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _InputBar extends StatelessWidget {
  final ChatController c;
  const _InputBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.inputController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => c.send(),
                  decoration: InputDecoration(
                    hintText: AppStrings.inputHint,
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final listening = c.isListening.value;
                final canSend =
                    c.hasText.value && !listening && !c.isTyping.value;
                final icon = listening
                    ? Icons.stop_rounded
                    : (canSend ? Icons.send_rounded : Icons.mic);

                return GestureDetector(
                  onTap: canSend ? c.send : c.toggleListening,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          listening ? AppColors.recording : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}