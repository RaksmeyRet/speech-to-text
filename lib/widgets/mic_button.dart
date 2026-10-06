import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.isListening, required this.onTap});

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: isListening ? 'Stop recording' : 'Start recording',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isListening
                    ? const Color(0xFFFF7777)
                    : const Color(0xFFBACCF5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                size: 34,
                color: const Color(0xFF1B1D22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}