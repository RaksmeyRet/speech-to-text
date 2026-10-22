import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/knowledge_document.dart';
import '../models/knowledge_overview.dart';

class KnowledgeApiException implements Exception {
  final String message;
  final int? statusCode;

  const KnowledgeApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class KnowledgeApi {
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  final http.Client _client;
  final String _baseUrl;
  final bool _ownsClient;

  KnowledgeApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/$'), '');

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  Future<KnowledgeOverview> searchOverview({
    required String question,
    required String language,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/rag/knowledge/search/ai-overview/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'language': language,
        'top_k': 5,
        'threshold': 0.25,
        'weights': {
          'question': 0.40,
          'keyword': 0.30,
          'summary': 0.20,
          'topic': 0.10,
        },
      }),
    );
    final data = _decodeResponse(response);
    if (data['results'] is! List) {
      throw const KnowledgeApiException(
        'The knowledge search response did not contain a results list.',
      );
    }
    return KnowledgeOverview.fromJson(data);
  }

  Future<KnowledgeDocument> getKnowledge(String id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/rag/knowledge/$id/'),
    );
    return KnowledgeDocument.fromJson(_decodeResponse(response));
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    // bodyBytes + utf8 keeps Khmer text correct even without a charset header
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw KnowledgeApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      throw const KnowledgeApiException(
        'The server returned an invalid response. Check that the API is running.',
      );
    }
  }

  String _errorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;
        return decoded.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
      }
    } on FormatException {
      // Use a clear status message for responses that are not JSON.
    }
    return 'The server returned HTTP $statusCode.';
  }
}
