import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_app/constants/app_constants.dart';
import 'package:speech_to_text_app/constants/app_languages.dart';
import 'package:speech_to_text_app/controllers/chat_controller.dart';
import 'package:speech_to_text_app/main.dart';
import 'package:speech_to_text_app/models/chat_message.dart';
import 'package:speech_to_text_app/models/knowledge_document.dart';
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

  testWidgets('Khmer detail sheet has bold headings and normal body text', (
    tester,
  ) async {
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
    const document = KnowledgeDocument(
      id: 'knowledge-1',
      title: 'ចំណងជើងឯកសារ',
      description: 'ការពិពណ៌នាធម្មតា',
      sourceType: 'pdf',
      sources: [],
      segments: [
        KnowledgeDocumentSegment(
          id: 'segment-1',
          segmentIndex: 0,
          title: 'ចំណងជើងផ្នែក',
          summary: 'សេចក្តីសង្ខេបធម្មតា',
          transcript: '',
          pageStart: null,
          pageEnd: null,
          startTimeSeconds: null,
          endTimeSeconds: null,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeDetailSheet(
            result: result,
            document: Future.value(document),
            languageCode: 'km',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final documentTitle = tester.widget<Text>(find.text('ចំណងជើងឯកសារ'));
    final description = tester.widget<Text>(find.text('ការពិពណ៌នាធម្មតា'));
    final sectionTitle = tester.widget<Text>(find.text('ចំណងជើងផ្នែក'));
    final summary = tester.widget<Text>(find.text('សេចក្តីសង្ខេបធម្មតា'));

    expect(documentTitle.style?.fontWeight, FontWeight.w600);
    expect(sectionTitle.style?.fontWeight, FontWeight.w600);
    expect(description.style?.fontWeight, AppTextStyles.khmerAnswerFontWeight);
    expect(summary.style?.fontWeight, AppTextStyles.khmerAnswerFontWeight);
    expect(documentTitle.style?.fontFamily, AppTextStyles.khmerFontFamily);
    expect(description.style?.fontFamily, AppTextStyles.khmerFontFamily);
  });

  testWidgets('English detail sheet has bold headings and normal body text', (
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
    const document = KnowledgeDocument(
      id: 'knowledge-1',
      title: 'Seller putting items up for sale',
      description: 'Video training about product sales.',
      sourceType: 'video',
      sources: [],
      segments: [
        KnowledgeDocumentSegment(
          id: 'segment-1',
          segmentIndex: 0,
          title: 'Adding Products and Pricing',
          summary: 'The user searches for products and sets prices.',
          transcript: '',
          pageStart: null,
          pageEnd: null,
          startTimeSeconds: null,
          endTimeSeconds: null,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeDetailSheet(
            result: result,
            document: Future.value(document),
            languageCode: 'en',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final documentTitle = tester.widget<Text>(
      find.text('Seller putting items up for sale'),
    );
    final description = tester.widget<Text>(
      find.text('Video training about product sales.'),
    );
    final sectionTitle = tester.widget<Text>(
      find.text('Adding Products and Pricing'),
    );
    final summary = tester.widget<Text>(
      find.text('The user searches for products and sets prices.'),
    );

    expect(documentTitle.style?.fontWeight, FontWeight.w600);
    expect(sectionTitle.style?.fontWeight, FontWeight.w600);
    expect(description.style?.fontWeight, FontWeight.normal);
    expect(summary.style?.fontWeight, FontWeight.normal);
    expect(find.text('Start: 27.0 sec · End: 35.0 sec'), findsOneWidget);
  });

  testWidgets('video displays inline without opening a popup', (tester) async {
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
    const document = KnowledgeDocument(
      id: 'knowledge-1',
      title: 'Video guide',
      description: 'Video description',
      sourceType: 'video',
      sources: [],
      segments: [
        KnowledgeDocumentSegment(
          id: 'segment-1',
          segmentIndex: 0,
          title: 'Video section',
          summary: 'Video summary',
          transcript: '',
          pageStart: null,
          pageEnd: null,
          startTimeSeconds: 27,
          endTimeSeconds: 35,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeDetailSheet(
            result: result,
            document: Future.value(document),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Start: 27.0 sec · End: 35.0 sec'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
