import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../models/knowledge_overview.dart';
import '../models/knowledge_search_result.dart';
import '../widgets/knowledge_detail_sheet.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/listening_view.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        surfaceTintColor: AppColors.whiteColor,
        title: Obx(
          () => Text(
            c.selectedLang.value == 'km' ? 'ខេមរាបុត្រ' : 'Khemra bot',
            style: TextStyle(
              fontSize: 20,
              fontFamily: c.selectedLang.value == 'km'
                  ? AppTextStyles.khmerFontFamily
                  : null,
              fontVariations: c.selectedLang.value == 'km'
                  ? AppTextStyles.khmerBoldFontVariations
                  : null,
              fontWeight: c.selectedLang.value == 'km'
                  ? FontWeight.w600
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
          _InputBar(c: c),
        ],
      ),
    );
  }

  void _showKnowledgeDetail(
    BuildContext context,
    KnowledgeSearchResult result,
    String languageCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) =>
          KnowledgeDetailSheet(result: result, languageCode: languageCode),
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
    final textStyle = TextStyle(
      fontSize: 15,
      height: 1.45,
      fontFamily: message.responseLanguage == 'km'
          ? AppTextStyles.khmerFontFamily
          : null,
      fontVariations: message.responseLanguage == 'km'
          ? AppTextStyles.khmerRegularFontVariations
          : null,
      fontWeight: message.responseLanguage == 'km'
          ? isUser
                ? AppTextStyles.khmerFontWeight
                : AppTextStyles.khmerAnswerFontWeight
          : FontWeight.normal,
      color: isUser ? AppColors.whiteColor : AppColors.blackColor,
    );
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
            Text.rich(_answerTextSpan(message, textStyle), style: textStyle),

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

TextSpan _answerTextSpan(ChatMessage message, TextStyle style) {
  if (message.isUser) {
    return TextSpan(text: message.displayText, style: style);
  }

  final overview = message.overview;
  if (overview == null || overview.steps.isEmpty) {
    return TextSpan(text: message.text, style: style);
  }

  final boldStyle = style.copyWith(
    fontWeight: message.responseLanguage == 'km'
        ? FontWeight.w600
        : FontWeight.bold,
    fontVariations: message.responseLanguage == 'km'
        ? AppTextStyles.khmerBoldFontVariations
        : null,
  );
  if (message.responseLanguage == 'km') {
    return _khmerAnswerTextSpan(overview, style, boldStyle);
  }
  if (message.responseLanguage != 'en') {
    return TextSpan(text: message.text, style: style);
  }

  final summary = overview.summary?.trim() ?? '';
  final steps = overview.steps
      .map((step) {
        final title = step.title.trim();
        final instruction = step.instruction.trim();
        final content = [
          title,
          instruction,
        ].where((part) => part.isNotEmpty).join(': ');
        return content.isEmpty ? null : (step.stepNumber, title, instruction);
      })
      .whereType<(int, String, String)>()
      .toList();
  final spans = <InlineSpan>[];

  if (summary.isNotEmpty) {
    spans.add(TextSpan(text: summary));
  }
  for (final (number, title, instruction) in steps) {
    if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n\n'));
    spans.addAll([
      TextSpan(text: 'Step $number:', style: boldStyle),
      const TextSpan(text: ' '),
      if (title.isNotEmpty) TextSpan(text: title, style: boldStyle),
      if (title.isNotEmpty && instruction.isNotEmpty)
        const TextSpan(text: ': '),
      if (instruction.isNotEmpty) TextSpan(text: instruction),
    ]);
  }
  if (spans.isEmpty) return TextSpan(text: message.text, style: style);
  return TextSpan(children: spans, style: style);
}

TextSpan _khmerAnswerTextSpan(
  KnowledgeOverview overview,
  TextStyle style,
  TextStyle boldStyle,
) {
  final spans = <InlineSpan>[];
  final summary = overview.summary?.trim() ?? '';
  if (summary.isNotEmpty) {
    spans.add(TextSpan(text: summary, style: style));
  }

  for (final step in overview.steps) {
    final title = step.title.trim();
    final instruction = step.instruction.trim();
    if (title.isEmpty && instruction.isEmpty) continue;
    if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n\n'));
    spans.add(
      TextSpan(
        text: 'ជំហានទី${_khmerNumber(step.stepNumber)}៖',
        style: boldStyle,
      ),
    );
    if (title.isNotEmpty) {
      spans.add(const TextSpan(text: ' '));
      spans.add(TextSpan(text: title, style: boldStyle));
    }
    if (instruction.isNotEmpty) {
      spans.add(
        TextSpan(
          text: title.isNotEmpty ? '៖ $instruction' : ' $instruction',
          style: style,
        ),
      );
    }
  }

  return spans.isEmpty
      ? TextSpan(text: overview.summary ?? '', style: style)
      : TextSpan(children: spans, style: style);
}

String _khmerNumber(int number) {
  const digits = '០១២៣៤៥៦៧៨៩';
  return number
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
}

String _pageRangeLabel(KnowledgeSearchResult result, String languageCode) {
  final start = result.pageStart;
  final end = result.pageEnd;

  if (start == null && end == null) {
    return languageCode == 'km' ? 'ឯកសារ' : 'Document';
  }
  if (start == null) {
    return languageCode == 'km' ? 'ទំព័រ $end' : 'Page $end';
  }
  if (end == null || end == start) {
    return languageCode == 'km' ? 'ទំព័រ $start' : 'Page $start';
  }

  return languageCode == 'km' ? 'ទំព័រ $start–$end' : 'Page $start–$end';
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
        : _pageRangeLabel(result, languageCode);

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Material(
        color: AppColors.whiteColor,
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
                  color: AppColors.secondaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: languageCode == 'km'
                              ? AppTextStyles.khmerFontFamily
                              : null,
                          fontVariations: languageCode == 'km'
                              ? AppTextStyles.khmerBoldFontVariations
                              : null,
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
                                ? AppTextStyles.khmerAnswerFontWeight
                                : FontWeight.normal,
                            fontFamily: languageCode == 'km'
                                ? AppTextStyles.khmerFontFamily
                                : null,
                            fontVariations: languageCode == 'km'
                                ? AppTextStyles.khmerRegularFontVariations
                                : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontSize: 12,
                          fontWeight: languageCode == 'km'
                              ? AppTextStyles.khmerAnswerFontWeight
                              : FontWeight.normal,
                          fontFamily: languageCode == 'km'
                              ? AppTextStyles.khmerFontFamily
                              : null,
                          fontVariations: languageCode == 'km'
                              ? AppTextStyles.khmerRegularFontVariations
                              : null,
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
      color: AppColors.whiteColor,
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
                          fontFamily: c.selectedLang.value == 'km'
                              ? AppTextStyles.khmerFontFamily
                              : null,
                          fontVariations: c.selectedLang.value == 'km'
                              ? AppTextStyles.khmerRegularFontVariations
                              : null,
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
                                  color: AppColors.whiteColor,
                                ),
                              )
                            : Icon(icon, color: AppColors.whiteColor),
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
