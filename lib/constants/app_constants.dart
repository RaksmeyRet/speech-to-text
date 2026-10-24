import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F766E);
  static const recording = Color(0xFFB42318);
  static const botBubble = Color(0xFFE6ECE9);
  static const background = Color(0xFFF6F7F5);
  static const inputFill = Color(0xFFEEF1EF);
  static const border = Color(0xFFDDE3E0);
}

class AppTextStyles {
  static const khmerFontWeight = FontWeight.w300;
}

class AppStrings {
  static const greeting =
      'Hi! Ask me anything about apps. '
      'You can type, speak, or upload a voice file.';
  static const greetingKhmer =
      'សួស្តី! អ្នកអាចសួរខ្ញុំអំពីកម្មវិធីបានគ្រប់ពេល។ '
      'អ្នកអាចវាយ សួរដោយសំឡេង ឬផ្ទុកឡើងឯកសារសំឡេង។';
  static const noResult =
      "Sorry, I couldn't find an answer for that. Try rephrasing.";
  static const error = 'Sorry, something went wrong. Please try again.';
  static const noResultKhmer =
      'សូមអភ័យទោស ខ្ញុំរកមិនឃើញចម្លើយទេ។ សូមសាកល្បងសួរម្តងទៀត។';
  static const errorKhmer = 'សូមអភ័យទោស មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀត។';
  static const inputHint = 'Type or tap the mic…';

  static String greetingFor(String languageCode) =>
      languageCode == 'km' ? greetingKhmer : greeting;

  static String noResultFor(String languageCode) =>
      languageCode == 'km' ? noResultKhmer : noResult;

  static String errorFor(String languageCode) =>
      languageCode == 'km' ? errorKhmer : error;

  // ---------- recording screen ----------
  static String listening(String languageCode) => languageCode == 'km'
      ? 'កំពុងស្តាប់ជាភាសាខ្មែរ…'
      : 'Listening in English…';

  static String listeningHint(String languageCode) => languageCode == 'km'
      ? 'និយាយឥឡូវនេះ។ ពាក្យរបស់អ្នកនឹងត្រូវបកប្រែជាភាសាអង់គ្លេសនៅពេលអ្នកឈប់។'
      : 'Speak now. Your words are translated to English when you stop.';

  static String youSaid(String languageCode) =>
      languageCode == 'km' ? 'អ្នកបាននិយាយ' : 'YOU SAID';

  static String translating(String languageCode) =>
      languageCode == 'km' ? 'កំពុងបកប្រែ' : 'Translating';
}
