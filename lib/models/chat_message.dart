import 'knowledge_overview.dart';
import 'knowledge_search_result.dart';

enum Sender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final String? original; // original text (Khmer or other language)
  final Sender sender;
  final KnowledgeOverview? overview;
  final List<KnowledgeSearchResult> searchResults;
  final String responseLanguage;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.original,
    this.overview,
    this.searchResults = const [],
    this.responseLanguage = 'en',
  });

  bool get isUser => sender == Sender.user;

  String get displayText => isUser ? original ?? text : text;

  factory ChatMessage.user(
    String text, {
    String? original,
    String responseLanguage = 'en',
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.user,
    original: original,
    responseLanguage: responseLanguage,
  );

  factory ChatMessage.bot(
    String text, {
    KnowledgeOverview? overview,
    List<KnowledgeSearchResult> searchResults = const [],
    String responseLanguage = 'en',
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: text,
    sender: Sender.bot,
    overview: overview,
    searchResults: searchResults.isNotEmpty
        ? searchResults
        : (overview?.results ?? const []),
    responseLanguage: responseLanguage,
  );
}
