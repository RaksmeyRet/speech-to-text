class VideoSegment {
  final String id;
  final String title;
  final String summary;
  final String timeLabel; //"00:21 - 00:30"
  final Duration start;
  final Duration end;
  final List<String> keywords;
  final List<String> possibleQuestions;

  VideoSegment({
    required this.id,
    required this.title,
    required this.summary,
    required this.timeLabel,
    required this.start,
    required this.end,
    required this.keywords,
    required this.possibleQuestions,
  });

  factory VideoSegment.fromJson(Map<String, dynamic> j){
    final parts = (j['time'] as String).split(RegExp(r'\s*-\s*'));
    return VideoSegment(
      id: j['segment_id'],
      title: j['title'],
      summary: j['summary'],
      timeLabel: (j['time'] as String).replaceAll('-','-'),
      start: _parse(parts[0]),
      end: _parse(parts[1]),
      keywords: List<String>.from(j['keywords'] ?? []),
      possibleQuestions: List<String>.from(j['possibleQuestions'] ?? []),
    );
  }

  static Duration _parse(String s){
    final p = s.trim().split(':').map(int.parse).toList();
    return p.length == 2
        ? Duration(hours: p[0], minutes: p[1], seconds: p[2])
        : Duration(minutes: p[0], seconds: p[1]);
  }
}
