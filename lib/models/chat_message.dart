import 'knowledge_search_result.dart';

enum Sender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final String? original; // NEW: original text (Khmer or other language)
  final Sender sender;
  final List<KnowledgeSearchResult> searchResults;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.original,
    this.searchResults = const [],
  });

  bool get isUser => sender == Sender.user;

  factory ChatMessage.user(String text, {String? original}) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.user,
    original: original,
  );

  factory ChatMessage.bot(
    String text, {
    List<KnowledgeSearchResult> searchResults = const [],
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.bot,
    searchResults: searchResults,
  );
}
