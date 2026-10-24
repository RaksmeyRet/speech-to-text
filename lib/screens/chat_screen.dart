import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../models/knowledge_search_result.dart';
import '../widgets/knowledge_detail_sheet.dart';
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
        title: Obx(
          () => Text(
            c.selectedLang.value == 'km' ? 'ខេមរាបុត្រ' : 'Khemra bot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: c.selectedLang.value == 'km'
                  ? AppTextStyles.khmerFontWeight
                  : FontWeight.w700,
            ),
          ),
        ),
        actions: [
          LanguageDropdown(c: c),
          const SizedBox(width: 12),
        ],
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
                        : _Bubble(
                            message: c.messages[i],
                            onSelectResult: (result) => _showKnowledgeDetail(
                              context,
                              c,
                              result,
                              c.messages[i].responseLanguage,
                            ),
                          ),
                  );
                }),
                Obx(
                  () => c.isListening.value
                      ? Positioned.fill(child: ListeningView(c: c))
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          YouSaidStrip(c: c),
          _InputBar(c: c),
        ],
      ),
    );
  }

  void _showKnowledgeDetail(
    BuildContext context,
    ChatController controller,
    KnowledgeSearchResult result,
    String languageCode,
  ) {
    final document = controller.loadKnowledge(
      result.knowledgeId,
      translateToKhmer: languageCode == 'km',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => KnowledgeDetailSheet(
        result: result,
        document: document,
        languageCode: languageCode,
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<KnowledgeSearchResult> onSelectResult;

  const _Bubble({required this.message, required this.onSelectResult});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              (message.searchResults.isEmpty ? 0.75 : 0.9),
        ),
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
                fontWeight: message.responseLanguage == 'km'
                    ? AppTextStyles.khmerFontWeight
                    : FontWeight.normal,
                color: isUser ? Colors.white : const Color(0xFF1C2523),
              ),
            ),

            // NEW: original text (Khmer or other language) under the English
            if (isUser && message.original != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.original!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: AppTextStyles.khmerFontWeight,
                  ),
                ),
              ),

            for (final result in message.searchResults)
              _SearchResultCard(
                result: result,
                languageCode: message.responseLanguage,
                onTap: () => onSelectResult(result),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final KnowledgeSearchResult result;
  final String languageCode;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.languageCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = result.title.isNotEmpty
        ? result.title
        : result.knowledgeTitle;
    final summary = result.summary.isNotEmpty
        ? result.summary
        : result.transcript;
    final location = result.sourceType == 'video'
        ? result.startTimeSeconds == null && result.endTimeSeconds == null
              ? (languageCode == 'km' ? 'វីដេអូ' : 'Video')
              : '${languageCode == 'km' ? 'វីដេអូ' : 'Video'} · '
                    '${result.startTimeSeconds?.toStringAsFixed(1) ?? '—'}'
                    '–'
                    '${result.endTimeSeconds?.toStringAsFixed(1) ?? '—'} '
                    '${languageCode == 'km' ? 'វិនាទី' : 'sec'}'
        : result.pageStart == null
        ? (languageCode == 'km' ? 'ឯកសារ' : 'Document')
        : languageCode == 'km'
        ? 'ទំព័រ ${result.pageStart}'
        : 'Page ${result.pageStart}';

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  result.sourceType == 'video'
                      ? Icons.play_circle_outline
                      : Icons.description_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: languageCode == 'km'
                              ? AppTextStyles.khmerFontWeight
                              : FontWeight.w600,
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: languageCode == 'km'
                                ? AppTextStyles.khmerFontWeight
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: AppTextStyles.khmerFontWeight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final fileName = c.selectedAudioFileName.value;
                if (fileName == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.audio_file_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove voice file',
                        visualDensity: VisualDensity.compact,
                        onPressed: c.clearSelectedAudioFile,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                );
              }),
              Row(
                children: [
                  Obx(
                    () => Tooltip(
                      message: 'Select a voice file',
                      child: Material(
                        color: AppColors.inputFill,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: c.isListening.value || c.isTyping.value
                              ? null
                              : c.pickAudioFile,
                          icon: const Icon(
                            Icons.attach_file,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => TextField(
                        controller: c.inputController,
                        style: TextStyle(
                          fontWeight: c.selectedLang.value == 'km'
                              ? AppTextStyles.khmerFontWeight
                              : FontWeight.normal,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => c.send(),
                        decoration: InputDecoration(
                          hintText: AppStrings.inputHint,
                          filled: true,
                          fillColor: AppColors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() {
                    final listening = c.isListening.value;
                    final busy = c.isTyping.value || c.isTranslating.value;
                    final canSend =
                        (c.hasText.value ||
                            c.selectedAudioFileName.value != null) &&
                        !listening &&
                        !busy;
                    final icon = listening
                        ? Icons.stop_rounded
                        : (canSend ? Icons.send_rounded : Icons.mic);

                    return GestureDetector(
                      onTap: busy
                          ? null
                          : canSend
                          ? c.send
                          : c.toggleListening,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: listening
                              ? AppColors.recording
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: busy
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(icon, color: Colors.white),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
