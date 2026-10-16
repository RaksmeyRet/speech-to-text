import 'video_segment.dart';

enum Sender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final String? original; // NEW: original text (Khmer or other language)
  final Sender sender;
  final String? videoUrl;
  final List<VideoSegment> segments;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.original,
    this.videoUrl,
    this.segments = const [],
  });

  bool get isUser => sender == Sender.user;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory ChatMessage.user(String text, {String? original}) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.user,
    original: original,
  );

  factory ChatMessage.bot(
    String text, {
    String? videoUrl,
    List<VideoSegment> segments = const [],
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.bot,
    videoUrl: videoUrl,
    segments: segments,
  );
}
