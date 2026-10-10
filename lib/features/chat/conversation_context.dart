import '../community/data/community_repository.dart';

class ConversationContext {
  const ConversationContext(this.label, this.route);
  final String label, route;
  static ConversationContext? fromConversation(Json? conversation) {
    final id = conversation?['context_id'];
    if (id is! String || id.trim().isEmpty) return null;
    final segment = Uri.encodeComponent(id);
    return switch (conversation?['kind']) {
      // Returning to a group here creates group -> chat -> group loops.
      'group' => null,
      'event' => ConversationContext('Открыть встречу', '/event/$segment'),
      'walk' => ConversationContext('Открыть договорённость', '/walk/$segment'),
      _ => null,
    };
  }
}
