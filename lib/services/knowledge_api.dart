import 'dart:convert';
import 'dart:io';

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
  // Direct default base URL without requiring any .env or --dart-define
  static const String directBaseUrl =
      'https://memphis-composite-incorporate-flyer.trycloudflare.com';

  final http.Client _client;
  String _baseUrl;
  final bool _ownsClient;
  final bool _allowCandidateFallback;

  KnowledgeApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = (baseUrl ?? directBaseUrl).replaceFirst(RegExp(r'/$'), ''),
      _allowCandidateFallback = baseUrl == null;

  String get baseUrl => _baseUrl;

  List<String> get _candidateBaseUrls {
    if (!_allowCandidateFallback) return [_baseUrl];
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const [
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
        'http://192.168.1.29:8000',
      ];
    }
    return const ['http://127.0.0.1:8000', 'http://localhost:8000'];
  }

  Future<KnowledgeOverview> searchOverview({
    required String question,
    required String language,
    int topK = 1,
    double threshold = 0.10,
  }) async {
    final response = await _postJson('/api/rag/knowledge/search/ai-overview/', {
      'question': question,
      'language': language,
      'top_k': topK,
      'threshold': threshold,
      'weights': {
        'question': 0.40,
        'keyword': 0.30,
        'summary': 0.20,
        'topic': 0.10,
      },
    });
    final data = _decodeResponse(response);
    if (data['results'] is! List) {
      throw const KnowledgeApiException(
        'The knowledge search response did not contain a results list.',
      );
    }
    return KnowledgeOverview.fromJson(data);
  }

  Future<KnowledgeDocument> getKnowledge(String id) async {
    final response = await _getJson('/api/rag/knowledge/$id/');
    return KnowledgeDocument.fromJson(_decodeResponse(response));
  }

  Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final payload = jsonEncode(body);
    final headers = const {'Content-Type': 'application/json'};

    final candidates = [
      _baseUrl,
      ..._candidateBaseUrls.where((u) => u != _baseUrl),
    ];
    Object? lastError;

    for (final base in candidates) {
      final uri = Uri.parse('$base$path');
      try {
        final response = await _client.post(
          uri,
          headers: headers,
          body: payload,
        );
        _baseUrl = base;
        return response;
      } on SocketException catch (e) {
        lastError = e;
        if (!_allowCandidateFallback) rethrow;
      } on http.ClientException catch (e) {
        lastError = e;
        if (!_allowCandidateFallback) rethrow;
      }
    }

    throw KnowledgeApiException(
      'Cannot connect to backend at $_baseUrl. Please ensure the backend is running. ($lastError)',
    );
  }

  Future<http.Response> _getJson(String path) async {
    final candidates = [
      _baseUrl,
      ..._candidateBaseUrls.where((u) => u != _baseUrl),
    ];
    Object? lastError;

    for (final base in candidates) {
      final uri = Uri.parse('$base$path');
      try {
        final response = await _client.get(uri);
        _baseUrl = base;
        return response;
      } on SocketException catch (e) {
        lastError = e;
        if (!_allowCandidateFallback) rethrow;
      } on http.ClientException catch (e) {
        lastError = e;
        if (!_allowCandidateFallback) rethrow;
      }
    }

    throw KnowledgeApiException(
      'Cannot connect to backend at $_baseUrl. Please ensure the backend is running. ($lastError)',
    );
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
