import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/app_languages.dart';
import '../controllers/chat_controller.dart';

class YouSaidStrip extends StatelessWidget {
  final ChatController c;
  const YouSaidStrip({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.originalText.isEmpty) return const SizedBox.shrink();
      final lang = (appLanguages[c.selectedLang.value] ?? '').toUpperCase();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOU SAID · $lang',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF4A5651),
                  ),
                ),
                if (c.isTranslating.value)
                  const Row(
                    children: [
                      Icon(Icons.refresh, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Translating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              c.originalText.value,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      );
    });
  }
}