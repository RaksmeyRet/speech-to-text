import 'knowledge_search_result.dart';

class KnowledgeOverview {
  final String? summary;
  final List<KnowledgeOverviewStep> steps;
  final List<KnowledgeSearchResult> results;

  const KnowledgeOverview({
    required this.summary,
    required this.steps,
    required this.results,
  });

  factory KnowledgeOverview.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final rawResults = json['results'];

    return KnowledgeOverview(
      summary: json['summary'] as String?,
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map<String, dynamic>>()
                .map(KnowledgeOverviewStep.fromJson)
                .toList()
          : const [],
      results: rawResults is List
          ? rawResults
                .whereType<Map<String, dynamic>>()
                .map(KnowledgeSearchResult.fromJson)
                .toList()
          : const [],
    );
  }
}

class KnowledgeOverviewStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String segmentId;

  const KnowledgeOverviewStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.segmentId,
  });

  factory KnowledgeOverviewStep.fromJson(Map<String, dynamic> json) =>
      KnowledgeOverviewStep(
        stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        instruction: json['instruction'] as String? ?? '',
        segmentId: json['segment_id'] as String? ?? '',
      );
}
