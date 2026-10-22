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
      color: const Color(0xF0F6F7F5),
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
                child: const Icon(Icons.mic, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => Text(
              AppStrings.listening(c.selectedLang.value),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Text(
              AppStrings.listeningHint(c.selectedLang.value),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4A5651),
              ),
            ),
          ),
        ],
      ),
    );
  }
}