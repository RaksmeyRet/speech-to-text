import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speech_to_text_app/models/knowledge_search_result.dart';
import 'package:speech_to_text_app/services/knowledge_api.dart';

void main() {
  test('search sends API query and parses matched source fields', () async {
    late http.Request request;
    final client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({
          'question': 'account setup',
          'language': 'km',
          'summary': 'Follow the account setup steps.',
          'steps': [
            {
              'step_number': 1,
              'title': 'Open Settings',
              'instruction': 'Select Create account.',
              'segment_id': 'segment-id',
            },
          ],
          'count': 1,
          'weights_used': {},
          'results': [
            {
              'segment_id': 'segment-id',
              'knowledge_id': 'knowledge-id',
              'knowledge_title': 'Account guide',
              'source_type': 'video',
              'segment_index': 2,
              'title': 'Create an account',
              'summary': 'Follow the account setup steps.',
              'transcript': 'Open the settings page.',
              'start_time_seconds': 30.0,
              'end_time_seconds': 50.0,
              'page_start': null,
              'page_end': null,
              'keywords': ['account'],
              'score': 0.88,
              'confidence': 0.88,
              'best_match': 'question',
              'confidence_by_type': {'question': 0.9},
              'matched_source': {
                'id': 'source-id',
                'language': 'km',
                'file_url': 'https://example.com/account.mp4',
                'duration_seconds': 90.0,
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
    final api = KnowledgeApi(client: client, baseUrl: 'http://localhost:8000');

    final overview = await api.searchOverview(
      question: 'account setup',
      language: 'km',
    );

    expect(request.url.path, '/api/rag/knowledge/search/ai-overview/');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['question'], 'account setup');
    expect(body['language'], 'km');
    expect((body['weights'] as Map<String, dynamic>)['question'], 0.4);
    expect(overview.summary, 'Follow the account setup steps.');
    expect(overview.steps.single.stepNumber, 1);
    expect(overview.steps.single.segmentId, 'segment-id');
    expect(overview.results, hasLength(1));
    expect(overview.results.single, isA<KnowledgeSearchResult>());
    expect(overview.results.single.segmentIndex, 2);
    expect(overview.results.single.fileUrl, 'https://example.com/account.mp4');
    expect(overview.results.single.startTimeSeconds, 30);

    api.close();
    client.close();
  });

  test('connection errors identify the configured backend URL', () async {
    final client = MockClient((_) async {
      throw http.ClientException('Connection timed out');
    });
    final api = KnowledgeApi(
      client: client,
      baseUrl: 'http://172.16.10.101:8000',
    );

    await expectLater(
      api.searchOverview(question: 'test', language: 'en'),
      throwsA(
        isA<KnowledgeApiException>()
            .having(
              (error) => error.message,
              'message',
              contains('http://172.16.10.101:8000'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('computer LAN IP'),
            ),
      ),
    );

    api.close();
    client.close();
  });
}
