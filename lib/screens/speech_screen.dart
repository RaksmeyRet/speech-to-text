import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/screen_controller.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation.dart';

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
              Row(
                children: [
                  const Spacer(),
                  const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final sourceLanguage = c.lang.value;
                  final targetLanguage = sourceLanguage == 'en' ? 'km' : 'en';
                  final sourceLabel = sourceLanguage == 'en'
                      ? 'English'
                      : 'Khmer';
                  final targetLabel = targetLanguage == 'en'
                      ? 'English'
                      : 'Khmer';
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
                      TranslationPanel(label: sourceLabel, text: sourceText),
                      const SizedBox(height: 12),
                      TranslationPanel(label: targetLabel, text: targetText),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 18),
              Obx(() {
                final sourceCode = c.lang.value;
                final targetCode = sourceCode == 'en' ? 'km' : 'en';
                final sourceLabel = sourceCode == 'en' ? 'English' : 'Khmer';
                final targetLabel = targetCode == 'en' ? 'English' : 'Khmer';

                return Row(
                  children: [
                    Expanded(
                      child: LanguageSelector(
                        label: sourceLabel,
                        selected: true,
                        onTap: () => c.setLanguage(sourceCode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Switch language direction',
                      onPressed: () => c.setLanguage(targetCode),
                      icon: const Icon(Icons.swap_horiz),
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LanguageSelector(
                        label: targetLabel,
                        selected: false,
                        onTap: () => c.setLanguage(targetCode),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              Obx(
                () => Center(
                  child: Semantics(
                    button: true,
                    label: c.isListening.value
                        ? 'Stop recording'
                        : 'Start recording',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: c.toggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: c.isListening.value
                                ? const Color(0xFFFF7777)
                                : const Color(0xFFBACCF5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            c.isListening.value ? Icons.stop : Icons.mic,
                            size: 34,
                            color: const Color(0xFF1B1D22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
