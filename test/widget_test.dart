import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_app/constants/app_constants.dart';
import 'package:speech_to_text_app/constants/app_languages.dart';
import 'package:speech_to_text_app/controllers/chat_controller.dart';
import 'package:speech_to_text_app/main.dart';
import 'package:speech_to_text_app/models/chat_message.dart';
import 'package:speech_to_text_app/models/knowledge_overview.dart';
import 'package:speech_to_text_app/models/knowledge_search_result.dart';
import 'package:speech_to_text_app/widgets/knowledge_detail_sheet.dart';

void main() {
  test('only Khmer and English are available', () {
    expect(appLanguages.keys.toSet(), {'en', 'km'});
  });

  testWidgets('chat title follows the selected language', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ខេមរាបុត្រ'), findsOneWidget);
    expect(find.text(AppStrings.greetingKhmer), findsOneWidget);
    final khmerTitle = tester.widget<Text>(find.text('ខេមរាបុត្រ'));
    expect(khmerTitle.style?.fontWeight, FontWeight.w600);
    expect(
      khmerTitle.style?.fontVariations,
      AppTextStyles.khmerBoldFontVariations,
    );
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

  testWidgets('Khmer greeting and input text use normal weight', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final greeting = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains(AppStrings.greetingKhmer),
      ),
    );
    final input = tester.widget<TextField>(find.byType(TextField));

    expect(
      greeting.text.style?.fontWeight,
      AppTextStyles.khmerAnswerFontWeight,
    );
    expect(greeting.text.style?.fontFamily, AppTextStyles.khmerFontFamily);
    expect(input.style?.fontWeight, FontWeight.w300);
    expect(input.style?.fontFamily, AppTextStyles.khmerFontFamily);
  });

  testWidgets('user messages display only their original input language', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final controller = Get.find<ChatController>();
    controller.messages.add(
      ChatMessage.user('Hello', original: 'សួស្តី', responseLanguage: 'km'),
    );
    controller.messages.add(
      ChatMessage.user('How are you?', responseLanguage: 'en'),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'សួស្តី',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == 'How are you?',
      ),
      findsOneWidget,
    );
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('English step labels and titles are bold', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final controller = Get.find<ChatController>();
    controller.messages.add(
      ChatMessage.bot(
        'Set up your account.\n\nStep 1: Open settings: Go to Settings.',
        overview: const KnowledgeOverview(
          summary: 'Set up your account.',
          steps: [
            KnowledgeOverviewStep(
              stepNumber: 1,
              title: 'Open settings',
              instruction: 'Go to Settings.',
              segmentId: 'segment-1',
            ),
          ],
          results: [],
        ),
      ),
    );
    await tester.pump();

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Step 1: Open settings'),
      ),
    );
    final spans = <TextSpan>[];
    void collectSpans(InlineSpan span) {
      if (span is TextSpan) {
        spans.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          collectSpans(child);
        }
      }
    }

    collectSpans(richText.text);
    final stepLabel = spans.singleWhere((span) => span.text == 'Step 1:');
    final title = spans.singleWhere((span) => span.text == 'Open settings');
    expect(stepLabel.style?.fontWeight, FontWeight.bold);
    expect(title.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('Khmer step labels and titles are bold', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final controller = Get.find<ChatController>();
    controller.messages.add(
      ChatMessage.bot(
        'រៀបចំគណនីរបស់អ្នក។\n\n'
        'ជំហានទី១៖ បកប្រែ៖ បើកការកំណត់៖ ចូលទៅកាន់ការកំណត់។',
        responseLanguage: 'km',
        overview: const KnowledgeOverview(
          summary: 'រៀបចំគណនីរបស់អ្នក។',
          steps: [
            KnowledgeOverviewStep(
              stepNumber: 1,
              title: 'បកប្រែ៖ បើកការកំណត់',
              instruction: 'ចូលទៅកាន់ការកំណត់។',
              segmentId: 'segment-1',
            ),
          ],
          results: [],
        ),
      ),
    );
    await tester.pump();

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('ជំហានទី១៖ បកប្រែ៖ បើកការកំណត់'),
      ),
    );
    final spans = <TextSpan>[];
    void collectSpans(InlineSpan span) {
      if (span is TextSpan) {
        spans.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          collectSpans(child);
        }
      }
    }

    collectSpans(richText.text);
    final stepLabel = spans.singleWhere((span) => span.text == 'ជំហានទី១៖');
    final title = spans.singleWhere(
      (span) => span.text == 'បកប្រែ៖ បើកការកំណត់',
    );
    final instruction = spans.singleWhere(
      (span) => span.text?.contains('ចូលទៅកាន់ការកំណត់។') ?? false,
    );
    expect(stepLabel.style?.fontWeight, FontWeight.w600);
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(
      stepLabel.style?.fontVariations,
      AppTextStyles.khmerBoldFontVariations,
    );
    expect(title.style?.fontVariations, AppTextStyles.khmerBoldFontVariations);
    expect(instruction.style?.fontWeight, AppTextStyles.khmerAnswerFontWeight);
    expect(
      instruction.style?.fontVariations,
      AppTextStyles.khmerRegularFontVariations,
    );
    expect(
      richText.text.style?.fontWeight,
      AppTextStyles.khmerAnswerFontWeight,
    );
    expect(richText.text.style?.fontFamily, AppTextStyles.khmerFontFamily);
  });

  testWidgets(
    'PDF detail sheet does not substitute the summary for page text',
    (tester) async {
      const result = KnowledgeSearchResult(
        segmentId: 'segment-1',
        knowledgeId: 'knowledge-1',
        knowledgeTitle: 'ចំណងជើងឯកសារ',
        sourceType: 'pdf',
        segmentIndex: 0,
        title: 'ចំណងជើងផ្នែក',
        summary: 'សេចក្តីសង្ខេបធម្មតា',
        transcript: '',
        pageStart: null,
        pageEnd: null,
        startTimeSeconds: null,
        endTimeSeconds: null,
        score: 0.9,
        fileUrl: null,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeDetailSheet(result: result, languageCode: 'km'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sectionTitle = tester.widget<Text>(find.text('ចំណងជើងផ្នែក'));
      expect(sectionTitle.style?.fontWeight, FontWeight.w600);
      expect(sectionTitle.style?.fontFamily, AppTextStyles.khmerFontFamily);
      expect(find.text('សេចក្តីសង្ខេបធម្មតា'), findsNothing);
      expect(find.text('មិនមានអត្ថបទសម្រាប់ផ្នែកនេះទេ។'), findsOneWidget);
      expect(find.text('ចំណងជើងឯកសារ'), findsNothing);
      expect(find.text('ការពិពណ៌នាធម្មតា'), findsNothing);
    },
  );

  testWidgets(
    'page-numbered PDF segment displays page text instead of summary',
    (tester) async {
      const result = KnowledgeSearchResult(
        segmentId: 'segment-8',
        knowledgeId: 'knowledge-1',
        knowledgeTitle: 'Business guide',
        sourceType: 'pdf',
        segmentIndex: 7,
        title: 'Business Ideas',
        summary: 'This is a generated summary that must not be shown.',
        transcript: 'Exact text extracted from page eight.',
        pageStart: 8,
        pageEnd: 8,
        startTimeSeconds: null,
        endTimeSeconds: null,
        score: 0.9,
        fileUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeDetailSheet(result: result, languageCode: 'en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Ideas'), findsOneWidget);
      expect(find.text('Page 8'), findsOneWidget);
      expect(
        find.text('Exact text extracted from page eight.'),
        findsOneWidget,
      );
      expect(
        find.text('This is a generated summary that must not be shown.'),
        findsNothing,
      );
    },
  );

  testWidgets('video detail popup hides text and shows only video', (
    tester,
  ) async {
    const result = KnowledgeSearchResult(
      segmentId: 'segment-1',
      knowledgeId: 'knowledge-1',
      knowledgeTitle: 'Seller putting items up for sale',
      sourceType: 'video',
      segmentIndex: 0,
      title: 'Adding Products and Pricing',
      summary: 'The user searches for products and sets prices.',
      transcript: '',
      pageStart: null,
      pageEnd: null,
      startTimeSeconds: 27,
      endTimeSeconds: 35,
      score: 0.9,
      fileUrl: 'https://example.com/training.mp4',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeDetailSheet(result: result, languageCode: 'en'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Seller putting items up for sale'), findsNothing);
    expect(find.text('Video training about product sales.'), findsNothing);
    expect(find.text('Adding Products and Pricing'), findsNothing);
    expect(
      find.text('The user searches for products and sets prices.'),
      findsNothing,
    );
    expect(find.text('Start: 27.0 sec · End: 35.0 sec'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);
  });

  testWidgets('video preview appears inline in the detail view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const result = KnowledgeSearchResult(
      segmentId: 'segment-1',
      knowledgeId: 'knowledge-1',
      knowledgeTitle: 'Video guide',
      sourceType: 'video',
      segmentIndex: 0,
      title: 'Video section',
      summary: 'Video summary',
      transcript: '',
      pageStart: null,
      pageEnd: null,
      startTimeSeconds: 27,
      endTimeSeconds: 35,
      score: 0.9,
      fileUrl: 'https://example.com/training.mp4',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KnowledgeDetailSheet(result: result)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Video guide'), findsNothing);
    expect(find.text('Video description'), findsNothing);
    expect(find.text('Video section'), findsNothing);
    expect(find.text('Video summary'), findsNothing);
    expect(find.text('Start: 27.0 sec · End: 35.0 sec'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF popup displays only the matched text segment', (
    tester,
  ) async {
    const result = KnowledgeSearchResult(
      segmentId: 'segment-1',
      knowledgeId: 'knowledge-1',
      knowledgeTitle: 'សៀវភៅណែនាំ',
      sourceType: 'pdf',
      segmentIndex: 0,
      title: 'ការណែនាំ',
      summary: 'សេចក្តីសង្ខេប',
      transcript: 'អត្ថបទផ្នែកដែលត្រូវគ្នា',
      pageStart: 1,
      pageEnd: 2,
      startTimeSeconds: null,
      endTimeSeconds: null,
      score: 0.9,
      fileUrl: 'https://example.com/guide.pdf',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeDetailSheet(result: result, languageCode: 'km'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ការណែនាំ'), findsOneWidget);
    expect(find.text('អត្ថបទផ្នែកដែលត្រូវគ្នា'), findsOneWidget);
    expect(find.text('សេចក្តីសង្ខេប'), findsNothing);
    expect(find.text('សៀវភៅណែនាំ'), findsNothing);
    expect(find.text('ឯកសារណែនាំ'), findsNothing);
    expect(find.text('ទំព័រ 1–2'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
