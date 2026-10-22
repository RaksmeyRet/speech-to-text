import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speech_to_text_app/controllers/chat_controller.dart';
import 'package:speech_to_text_app/services/knowledge_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    );
    controller.selectedLang.value = 'km';
    controller.inputController.text = 'តើខ្ញុំចូលដោយរបៀបណា?';

    await controller.send();

    expect(requestBody['question'], 'How do I sign in?');
    expect(requestBody['language'], 'km');
    expect(controller.messages.first.text, 'How do I sign in?');
    expect(controller.messages.first.original, 'តើខ្ញុំចូលដោយរបៀបណា?');
    expect(
      controller.messages.last.text,
      'Use the sign-in page.\n\n'
      '1. Sign in: Enter your username and password.',
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
      );
      controller.selectedLang.value = 'km';
      controller.inputController.text = 'How do I set up an account?';
      controller.originalText.value = 'តើខ្ញុំបង្កើតគណនីដោយរបៀបណា?';

      await controller.send();

      expect(requestBody['question'], 'How do I set up an account?');
      expect(requestBody['language'], 'km');
      expect(
        controller.messages.last.text,
        'Create an account: Open Settings and select Create account.\n\n'
        'Verify your account: Enter the verification code sent to your email.',
      );
      expect(controller.messages.last.searchResults, hasLength(2));

      controller.inputController.dispose();
      controller.scrollController.dispose();
      client.close();
    },
  );
}
