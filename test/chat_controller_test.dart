import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speech_to_text_app/controllers/chat_controller.dart';
import 'package:speech_to_text_app/services/knowledge_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Khmer detail view data translates while keeping video metadata',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/rag/knowledge/knowledge-id/');
        return http.Response(
          jsonEncode({
            'id': 'knowledge-id',
            'title': 'Buyer guide',
            'description': 'How a buyer makes a payment.',
            'source_type': 'video',
            'sources': [
              {
                'language': 'en',
                'file_url': 'https://example.com/video.mp4',
                'duration_seconds': 90,
                'page_count': null,
              },
            ],
            'segments': [
              {
                'id': 'segment-id',
                'segment_index': 0,
                'title': 'Scan QR code',
                'summary': 'Open the bank app.',
                'transcript': 'Scan the payment QR code.',
                'start_time_seconds': 19,
                'end_time_seconds': 34,
                'page_start': null,
                'page_end': null,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final controller = ChatController(
        knowledgeApi: KnowledgeApi(client: client, baseUrl: 'http://localhost'),
        translateToKhmer: (text) async => 'ខ្មែរ៖ $text',
      );

      final document = await controller.loadKnowledge(
        'knowledge-id',
        translateToKhmer: true,
      );

      expect(document.title, 'ខ្មែរ៖ Buyer guide');
      expect(document.description, 'ខ្មែរ៖ How a buyer makes a payment.');
      expect(document.segments.single.title, 'ខ្មែរ៖ Scan QR code');
      expect(document.segments.single.summary, 'ខ្មែរ៖ Open the bank app.');
      expect(
        document.segments.single.transcript,
        'ខ្មែរ៖ Scan the payment QR code.',
      );
      expect(document.segments.single.startTimeSeconds, 19);
      expect(document.segments.single.endTimeSeconds, 34);
      expect(document.sources.single.fileUrl, 'https://example.com/video.mp4');

      controller.inputController.dispose();
      controller.scrollController.dispose();
      client.close();
    },
  );

  test('typed Khmer is translated before backend search', () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((request) async {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'question': 'How do I sign in?',
          'language': 'km',
          'summary': 'Use the sign-in page.',
          'steps': [
            {
              'step_number': 1,
              'title': 'Sign in',
              'instruction': 'Enter your username and password.',
              'segment_id': 'video-segment',
            },
          ],
          'count': 1,
          'weights_used': {},
          'results': [
            {
              'segment_id': 'video-segment',
              'knowledge_id': 'video-knowledge',
              'knowledge_title': 'Sign-in guide',
              'source_type': 'video',
              'segment_index': 0,
              'title': 'Sign in',
              'summary': 'Enter your username and password.',
              'transcript': '',
              'start_time_seconds': 12.5,
              'end_time_seconds': 20.0,
              'page_start': null,
              'page_end': null,
              'keywords': [],
              'score': 0.9,
              'confidence': 0.9,
              'best_match': 'question',
              'confidence_by_type': {},
              'matched_source': {
                'id': 'video-source',
                'language': 'km',
                'file_url': 'https://example.com/sign-in.mp4',
                'duration_seconds': 30,
                'page_count': null,
                'is_fallback': false,
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final controller = ChatController(
      knowledgeApi: KnowledgeApi(client: client, baseUrl: 'http://localhost'),
      translateKhmer: (_) async => 'How do I sign in?',
      translateToKhmer: (text) async => 'បកប្រែ៖ $text',
    );
    controller.selectedLang.value = 'en';
    controller.inputController.text = 'តើខ្ញុំចូលដោយរបៀបណា?';

    await controller.send();

    expect(requestBody['question'], 'How do I sign in?');
    expect(requestBody['language'], 'km');
    expect(controller.messages.first.text, 'How do I sign in?');
    expect(controller.messages.first.original, 'តើខ្ញុំចូលដោយរបៀបណា?');
    expect(
      controller.messages.last.text,
      'បកប្រែ៖ Use the sign-in page.\n\n'
      'ជំហានទី១៖ បកប្រែ៖ Sign in: Enter your username and password.',
    );
    expect(controller.messages.last.responseLanguage, 'km');
    expect(
      controller.messages.last.searchResults.single.title,
      'បកប្រែ៖ Sign in',
    );
    expect(
      controller.messages.last.searchResults.single.summary,
      'បកប្រែ៖ Enter your username and password.',
    );
    expect(
      controller.messages.last.searchResults.single.fileUrl,
      'https://example.com/sign-in.mp4',
    );
    expect(
      controller.messages.last.searchResults.single.startTimeSeconds,
      12.5,
    );

    controller.inputController.dispose();
    controller.scrollController.dispose();
    client.close();
  });

  test(
    'chat displays backend answers and searches with translated English',
    () async {
      late Map<String, dynamic> requestBody;
      final client = MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'question': 'How do I set up an account?',
            'language': 'km',
            'count': 2,
            'weights_used': {},
            'results': [
              {
                'segment_id': 'segment-1',
                'knowledge_id': 'knowledge-1',
                'knowledge_title': 'Account guide',
                'source_type': 'pdf',
                'segment_index': 0,
                'title': 'Create an account',
                'summary': 'Open Settings and select Create account.',
                'transcript': '',
                'start_time_seconds': null,
                'end_time_seconds': null,
                'page_start': 1,
                'page_end': 1,
                'keywords': [],
                'score': 0.9,
                'confidence': 0.9,
                'best_match': 'question',
                'confidence_by_type': {},
                'matched_source': null,
              },
              {
                'segment_id': 'segment-2',
                'knowledge_id': 'knowledge-2',
                'knowledge_title': 'Verification guide',
                'source_type': 'pdf',
                'segment_index': 0,
                'title': 'Verify your account',
                'summary': '',
                'transcript': 'Enter the verification code sent to your email.',
                'start_time_seconds': null,
                'end_time_seconds': null,
                'page_start': 2,
                'page_end': 2,
                'keywords': [],
                'score': 0.8,
                'confidence': 0.8,
                'best_match': 'summary',
                'confidence_by_type': {},
                'matched_source': null,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final controller = ChatController(
        knowledgeApi: KnowledgeApi(client: client, baseUrl: 'http://localhost'),
        translateToKhmer: (text) async => 'បកប្រែ៖ $text',
      );
      controller.selectedLang.value = 'km';
      controller.inputController.text = 'How do I set up an account?';
      controller.originalText.value = 'តើខ្ញុំបង្កើតគណនីដោយរបៀបណា?';

      await controller.send();

      expect(requestBody['question'], 'How do I set up an account?');
      expect(requestBody['language'], 'km');
      expect(
        controller.messages.last.text,
        'បកប្រែ៖ Create an account: Open Settings and select Create account.\n\n'
        'បកប្រែ៖ Verify your account: Enter the verification code sent to your email.',
      );
      expect(controller.messages.last.searchResults, hasLength(2));
      expect(
        controller.messages.last.searchResults.first.title,
        'បកប្រែ៖ Create an account',
      );
      expect(
        controller.messages.last.searchResults.last.transcript,
        'បកប្រែ៖ Enter the verification code sent to your email.',
      );

      controller.inputController.dispose();
      controller.scrollController.dispose();
      client.close();
    },
  );
}
