import '../community/data/community_repository.dart';

class ConversationContext {
  const ConversationContext(this.label, this.route);
  final String label, route;
  static ConversationContext? fromConversation(Json? conversation) {
    final id = conversation?['context_id'];
    if (id is! String || id.trim().isEmpty) return null;
    return switch (conversation?['kind']) {
      // Returning to a group here creates group -> chat -> group loops.
      'group' => null,
      'event' => null,
      // Walk logistics open in a sheet over their chat.
      'walk' => null,
      _ => null,
    };
  }
}
