import 'package:escort/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket socket() {
    _socket ??= IO.io(
      ApiConfig.base,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    if (!(_socket!.connected)) {
      _socket!.connect();
    }
    return _socket!;
  }

  static void joinConversation(int conversationId) {
    final s = socket();
    s.emit('join_conversation', {'conversation_id': conversationId});
  }

  static void leaveConversation(int conversationId) {
    final s = socket();
    s.emit('leave_conversation', {'conversation_id': conversationId});
  }

  static void onNewMessage(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    s.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        handler(data);
      } else if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  static void offNewMessage() {
    _socket?.off('new_message');
  }
}

