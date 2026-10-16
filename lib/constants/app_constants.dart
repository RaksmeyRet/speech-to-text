import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F766E);
  static const recording = Color(0xFFB42318);
  static const botBubble = Color(0xFFE6ECE9);
  static const background = Color(0xFFF6F7F5);
  static const inputFill = Color(0xFFEEF1EF);
  static const border = Color(0xFFDDE3E0);
}

class AppStrings {
  static const greeting =
      'Hi! Ask me anything about your videos. You can type or use the mic.';
  static const noResult = "Sorry, I couldn't find a clip for that. Try rephrasing.";
  static const error = 'Sorry, something went wrong. Please try again.';
  static const inputHint = 'Type or tap the mic…';
}

class AppConfig {
  // Dummy video until the backend returns a real video_url
  static const demoVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  static const segmentsAsset = 'assets/segments.json';
  static const maxSegmentsPerAnswer = 3;

  // Words ignored by the dummy keyword matcher
  static const stopWords = {
    'how', 'what', 'where', 'the', 'can', 'for', 'and', 'you',
    'does', 'need', 'why', 'are', 'with', 'this', 'that', 'use', 'do',
  };
}