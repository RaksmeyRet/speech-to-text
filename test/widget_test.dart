import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_app/constants/app_constants.dart';
import 'package:speech_to_text_app/constants/app_languages.dart';
import 'package:speech_to_text_app/controllers/chat_controller.dart';
import 'package:speech_to_text_app/main.dart';

void main() {
  test('only Khmer and English are available', () {
    expect(appLanguages.keys.toSet(), {'en', 'km'});
  });

  testWidgets('chat title follows the selected language', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ខេមរាបុត្រ'), findsOneWidget);
    expect(find.text(AppStrings.greetingKhmer), findsOneWidget);
    expect(find.byTooltip('Add knowledge'), findsNothing);
    expect(find.byTooltip('Select a voice file'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);

    final controller = Get.find<ChatController>();
    controller.setLanguage('en');
    await tester.pump();

    expect(find.text('Khemra bot'), findsOneWidget);
    expect(find.text(AppStrings.greeting), findsOneWidget);

    controller.setLanguage('km');
    await tester.pump();

    expect(find.text(AppStrings.greetingKhmer), findsOneWidget);
  });
}
