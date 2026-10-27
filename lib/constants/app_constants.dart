import 'package:flutter/material.dart';

class AppColors {
  // ---------- brand palette ----------
  static const primaryColor = Color(0xFF092469); // blue
  static const secondaryColor = Color(0xFFCF951B); // gold
  static const greyColor = Color(0xFFBDBDBD); // disabled button
  static const hintColor = Color(0xFF6B7280); // hint in input field
  static const strokeColor = Color(0xFFEAEAEA); // gray stroke
  static const redColor = Color(0xFFE53935); // error / recording
  static const ratingColor = Color(0xFFFFC107); // rating star
  static const darkGreyColor = Color(0xFF505050);
  static const blackColor = Color(0xFF3F3F3F);
  static const whiteColor = Color(0xFFFFFFFF);
  static const textWhiteColor = Color(0xFFE5E5E5);

  // ---------- names the chat screen already uses ----------
  static const primary = primaryColor; // user bubble, send and mic buttons
  static const recording = redColor; // stop button while recording
  static const border = strokeColor;
  static const muted = hintColor;

  // light tints of the blue, because the palette has no soft background
  static const botBubble = Color(0xFFE8ECF6); // bot bubble
  static const background = Color(0xFFF7F8FB); // screen background
  static const inputFill = Color(0xFFF1F2F6); // text field
}

class AppTextStyles {
  static const khmerFontFamily = 'NotoSansKhmer';
  static const khmerFontWeight = FontWeight.w300;
  static const khmerAnswerFontWeight = FontWeight.w200;
  static const khmerRegularFontVariations = [FontVariation('wght', 200)];
  static const khmerBoldFontVariations = [FontVariation('wght', 600)];
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
