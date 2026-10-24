import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/app_languages.dart';
import '../controllers/chat_controller.dart';

class LanguageDropdown extends StatelessWidget {
  final ChatController c;
  const LanguageDropdown({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locked = c.isListening.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFF1F3F2) : Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: c.selectedLang.value,
            onChanged: locked ? null : (v) => c.setLanguage(v!),
            style: TextStyle(
              fontSize: 15,
              fontWeight: c.selectedLang.value == 'km'
                  ? AppTextStyles.khmerFontWeight
                  : FontWeight.w600,
              color: Colors.black87,
            ),
            items: appLanguages.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
          ),
        ),
      );
    });
  }
}
