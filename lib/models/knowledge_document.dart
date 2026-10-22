class KnowledgeDocument {
  final String id;
  final String title;
  final String description;
  final String sourceType;
  final List<KnowledgeSource> sources;
  final List<KnowledgeDocumentSegment> segments;

  const KnowledgeDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceType,
    required this.sources,
    required this.segments,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(KnowledgeSource.fromJson)
          .toList(),
      segments: (json['segments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(KnowledgeDocumentSegment.fromJson)
          .toList(),
    );
  }
}

class KnowledgeSource {
  final String language;
  final String? fileUrl;
  final int? pageCount;
  final double? durationSeconds;

  const KnowledgeSource({
    required this.language,
    required this.fileUrl,
    required this.pageCount,
    required this.durationSeconds,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) =>
      KnowledgeSource(
        language: json['language'] as String? ?? '',
        fileUrl: json['file_url'] as String?,
        pageCount: (json['page_count'] as num?)?.toInt(),
        durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      );
}

class KnowledgeDocumentSegment {
  final String id;
  final int segmentIndex;
  final String title;
  final String summary;
  final String transcript;
  final int? pageStart;
  final int? pageEnd;
  final double? startTimeSeconds;
  final double? endTimeSeconds;

  const KnowledgeDocumentSegment({
    required this.id,
    required this.segmentIndex,
    required this.title,
    required this.summary,
    required this.transcript,
    required this.pageStart,
    required this.pageEnd,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
  });

  factory KnowledgeDocumentSegment.fromJson(Map<String, dynamic> json) =>
      KnowledgeDocumentSegment(
        id: json['id'] as String? ?? '',
        segmentIndex: (json['segment_index'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        transcript: json['transcript'] as String? ?? '',
        pageStart: (json['page_start'] as num?)?.toInt(),
        pageEnd: (json['page_end'] as num?)?.toInt(),
        startTimeSeconds: (json['start_time_seconds'] as num?)?.toDouble(),
        endTimeSeconds: (json['end_time_seconds'] as num?)?.toDouble(),
      );
}