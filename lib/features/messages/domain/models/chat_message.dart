/// Feature: Messages
/// Model: ChatMessage (single message in a conversation)
class ChatMessage {
  final String text;
  final bool isSentByMe;
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}
