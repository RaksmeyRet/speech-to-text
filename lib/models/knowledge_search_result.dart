class KnowledgeSearchResult {
  final String segmentId;
  final String knowledgeId;
  final String knowledgeTitle;
  final String sourceType;
  final int segmentIndex;
  final String title;
  final String summary;
  final String transcript;
  final int? pageStart;
  final int? pageEnd;
  final double? startTimeSeconds;
  final double? endTimeSeconds;
  final double score;
  final String? fileUrl;

  const KnowledgeSearchResult({
    required this.segmentId,
    required this.knowledgeId,
    required this.knowledgeTitle,
    required this.sourceType,
    required this.segmentIndex,
    required this.title,
    required this.summary,
    required this.transcript,
    required this.pageStart,
    required this.pageEnd,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
    required this.score,
    required this.fileUrl,
  });

  factory KnowledgeSearchResult.fromJson(Map<String, dynamic> json) {
    // older shape: matched_source.file_url, newer shape: file_url at the top
    final source = json['matched_source'];
    final sourceMap = source is Map<String, dynamic> ? source : null;
    final fileUrl = (json['file_url'] ?? sourceMap?['file_url']) as String?;

    return KnowledgeSearchResult(
      segmentId: json['segment_id'] as String? ?? '',
      knowledgeId: json['knowledge_id'] as String? ?? '',
      knowledgeTitle: json['knowledge_title'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? '',
      segmentIndex: (json['segment_index'] as num?)?.toInt() ?? 0,
      title: (json['segment_title'] ?? json['title']) as String? ?? '',
      summary: (json['segment_summary'] ?? json['summary']) as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      pageStart: (json['page_start'] as num?)?.toInt(),
      pageEnd: (json['page_end'] as num?)?.toInt(),
      startTimeSeconds: (json['start_time_seconds'] as num?)?.toDouble(),
      endTimeSeconds: (json['end_time_seconds'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      fileUrl: fileUrl == null || fileUrl.isEmpty ? null : fileUrl,
    );
  }
}