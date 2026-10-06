import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/screen_controller.dart';
import '../models/languages.dart';
import '../widgets/language_picker.dart';
import '../widgets/language_widget.dart';
import '../widgets/mic_button.dart';
import '../widgets/translation_widget.dart';
import '../widgets/type_box.dart';

class SpeechScreen extends StatelessWidget {
  const SpeechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ScreenController());

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 7, 24),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode switch
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: LanguageWidget(
                        label: 'Speak',
                        selected: !c.isTextMode.value,
                        onTap: () => c.setMode(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LanguageWidget(
                        label: 'Type',
                        selected: c.isTextMode.value,
                        onTap: () => c.setMode(true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Text boxes
              Expanded(
                child: Obx(() {
                  final sourceLabel = appLanguages[c.sourceCode]!;
                  final targetLabel = appLanguages[c.targetCode]!;
                  final typeMode = c.isTextMode.value;

                  final sourceText = c.text.value.isNotEmpty
                      ? c.text.value
                      : c.isListening.value
                      ? 'Listening...'
                      : 'Spoken words will appear here';
                  final targetText = c.isTranslating.value
                      ? 'Translating...'
                      : c.translatedText.value.isNotEmpty
                      ? c.translatedText.value
                      : 'Translation will appear here';

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      typeMode
                          ? TypeBox(label: sourceLabel, controller: c)
                          : TranslationWidget(
                              label: sourceLabel,
                              text: sourceText,
                            ),
                      const SizedBox(height: 12),
                      TranslationWidget(label: targetLabel, text: targetText),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Bottom controls
              Obx(() {
                final sourceLabel = appLanguages[c.sourceCode]!;
                final targetLabel = appLanguages[c.targetCode]!;
                final typeMode = c.isTextMode.value;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LanguageWidget(
                            label: sourceLabel,
                            selected: true,
                            onTap: typeMode
                                ? () => showLanguagePicker(
                                    context,
                                    c.textFrom.value,
                                    c.setTextFrom,
                                  )
                                : () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Switch language direction',
                          onPressed: typeMode ? c.swap : null,
                          icon: const Icon(Icons.swap_horiz),
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LanguageWidget(
                            label: targetLabel,
                            selected: false,
                            onTap: typeMode
                                ? () => showLanguagePicker(
                                    context,
                                    c.textTo.value,
                                    c.setTextTo,
                                  )
                                : () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!typeMode)
                      MicButton(
                        isListening: c.isListening.value,
                        onTap: c.toggle,
                      ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}