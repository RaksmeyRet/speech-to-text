import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/chat_controller.dart';

class ListeningView extends StatelessWidget {
  final ChatController c;
  const ListeningView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.94),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFFDE4E1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.recording,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: AppColors.whiteColor,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => Text(
              AppStrings.listening(c.selectedLang.value),
              style: TextStyle(
                fontSize: 17,
                fontWeight: c.selectedLang.value == 'km'
                    ? AppTextStyles.khmerFontWeight
                    : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Text(
              AppStrings.listeningHint(c.selectedLang.value),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.darkGreyColor,
                fontWeight: c.selectedLang.value == 'km'
                    ? AppTextStyles.khmerFontWeight
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
