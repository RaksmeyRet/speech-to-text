import 'package:flutter/material.dart';
import '../controllers/screen_controller.dart';

class TypeBox extends StatelessWidget {
  const TypeBox({super.key, required this.label, required this.controller});

  final String label;
  final ScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBACCF5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.inputController,
            onChanged: controller.onTyped,
            minLines: 3,
            maxLines: null,
            cursorColor: const Color(0xFFBACCF5),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.25,
            ),
            decoration: const InputDecoration(
              hintText: 'Tap here to type...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}