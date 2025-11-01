import 'package:escort/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;
  static final Map<String, dynamic> _listeners = {};
  static bool _isConnecting = false;

  /// Get or create Socket.IO connection
  static IO.Socket socket() {
    _socket ??= IO.io(
      ApiConfig.base,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .enableForceNew()
          .build(),
    );
    
    if (!(_socket!.connected)) {
      _attemptConnect();
    }
    
    _setupErrorHandlers();
    return _socket!;
  }

  /// Attempt to establish connection with error handling
  static void _attemptConnect() {
    if (_isConnecting) return;
    
    _isConnecting = true;
    try {
      _socket?.connect();
      print('Socket.IO connecting...');
    } catch (e) {
      print('Error establishing Socket.IO connection: $e');
      _isConnecting = false;
    }
  }

  /// Setup global error handlers
  static void _setupErrorHandlers() {
    _socket?.on('connect', (_) {
      print('WebSocket connected successfully');
      _isConnecting = false;
    });

    _socket?.on('connect_error', (error) {
      print('WebSocket connection error: $error');
      _isConnecting = false;
    });

    _socket?.on('disconnect', (reason) {
      print('WebSocket disconnected: $reason');
      _isConnecting = false;
    });

    _socket?.on('error', (error) {
      print('WebSocket error: $error');
    });

    _socket?.on('joined_conversation', (data) {
      print('Successfully joined conversation: $data');
    });

    _socket?.on('left_conversation', (data) {
      print('Successfully left conversation: $data');
    });
  }

  /// Join a conversation room
  static void joinConversation(int conversationId) {
    try {
      final s = socket();
      s.emit('join_conversation', {'conversation_id': conversationId});
      print('Emitted join_conversation for ID: $conversationId');
    } catch (e) {
      print('Error joining conversation: $e');
    }
  }

  /// Leave a conversation room
  static void leaveConversation(int conversationId) {
    try {
      final s = socket();
      s.emit('leave_conversation', {'conversation_id': conversationId});
      print('Emitted leave_conversation for ID: $conversationId');
    } catch (e) {
      print('Error leaving conversation: $e');
    }
  }

  /// Listen for new messages in a conversation
  static void onNewMessage(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    
    // Remove old listener if exists
    if (_listeners.containsKey('new_message')) {
      s.off('new_message');
    }
    
    _listeners['new_message'] = handler;
    
    s.on('new_message', (data) {
      try {
        if (data is Map<String, dynamic>) {
          handler(data);
        } else if (data is Map) {
          handler(Map<String, dynamic>.from(data));
        } else {
          print('Unexpected data type for new_message: ${data.runtimeType}');
        }
      } catch (e) {
        print('Error handling new message: $e');
      }
    });
  }

  /// Stop listening for new messages
  static void offNewMessage() {
    try {
      _socket?.off('new_message');
      _listeners.remove('new_message');
      print('Stopped listening for new_message');
    } catch (e) {
      print('Error stopping new_message listener: $e');
    }
  }

  /// Listen for message updates
  static void onMessageUpdated(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    
    if (_listeners.containsKey('message_updated')) {
      s.off('message_updated');
    }
    
    _listeners['message_updated'] = handler;
    
    s.on('message_updated', (data) {
      try {
        if (data is Map<String, dynamic>) {
          handler(data);
        } else if (data is Map) {
          handler(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('Error handling message update: $e');
      }
    });
  }

  /// Stop listening for message updates
  static void offMessageUpdated() {
    try {
      _socket?.off('message_updated');
      _listeners.remove('message_updated');
    } catch (e) {
      print('Error stopping message_updated listener: $e');
    }
  }

  /// Listen for message deletions
  static void onMessageDeleted(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    
    if (_listeners.containsKey('message_deleted')) {
      s.off('message_deleted');
    }
    
    _listeners['message_deleted'] = handler;
    
    s.on('message_deleted', (data) {
      try {
        if (data is Map<String, dynamic>) {
          handler(data);
        } else if (data is Map) {
          handler(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('Error handling message deletion: $e');
      }
    });
  }

  /// Stop listening for message deletions
  static void offMessageDeleted() {
    try {
      _socket?.off('message_deleted');
      _listeners.remove('message_deleted');
    } catch (e) {
      print('Error stopping message_deleted listener: $e');
    }
  }

  /// Listen for typing indicators
  static void onUserTyping(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    
    if (_listeners.containsKey('user_typing')) {
      s.off('user_typing');
    }
    
    _listeners['user_typing'] = handler;
    
    s.on('user_typing', (data) {
      try {
        if (data is Map<String, dynamic>) {
          handler(data);
        } else if (data is Map) {
          handler(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('Error handling typing indicator: $e');
      }
    });
  }

  /// Stop listening for typing indicators
  static void offUserTyping() {
    try {
      _socket?.off('user_typing');
      _listeners.remove('user_typing');
    } catch (e) {
      print('Error stopping user_typing listener: $e');
    }
  }

  /// Emit typing indicator
  static void emitTyping(int conversationId, int userId, String username) {
    try {
      final s = socket();
      s.emit('typing', {
        'conversation_id': conversationId,
        'user_id': userId,
        'username': username
      });
    } catch (e) {
      print('Error emitting typing indicator: $e');
    }
  }

  /// Emit stop typing indicator
  static void emitStopTyping(int conversationId, int userId) {
    try {
      final s = socket();
      s.emit('stop_typing', {
        'conversation_id': conversationId,
        'user_id': userId
      });
    } catch (e) {
      print('Error emitting stop typing: $e');
    }
  }

  /// Listen for read receipts
  static void onMessageReadReceipt(void Function(Map<String, dynamic>) handler) {
    final s = socket();
    
    if (_listeners.containsKey('message_read_receipt')) {
      s.off('message_read_receipt');
    }
    
    _listeners['message_read_receipt'] = handler;
    
    s.on('message_read_receipt', (data) {
      try {
        if (data is Map<String, dynamic>) {
          handler(data);
        } else if (data is Map) {
          handler(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('Error handling read receipt: $e');
      }
    });
  }

  /// Stop listening for read receipts
  static void offMessageReadReceipt() {
    try {
      _socket?.off('message_read_receipt');
      _listeners.remove('message_read_receipt');
    } catch (e) {
      print('Error stopping message_read_receipt listener: $e');
    }
  }

  /// Emit message read receipt
  static void emitMessageRead(int conversationId, int messageId, int userId) {
    try {
      final s = socket();
      s.emit('message_read', {
        'conversation_id': conversationId,
        'message_id': messageId,
        'user_id': userId
      });
    } catch (e) {
      print('Error emitting message read receipt: $e');
    }
  }

  /// Disconnect socket
  static void disconnect() {
    try {
      _socket?.disconnect();
      _socket = null;
      _listeners.clear();
      print('Socket.IO disconnected');
    } catch (e) {
      print('Error disconnecting socket: $e');
    }
  }

  /// Check if socket is connected
  static bool isConnected() {
    return _socket?.connected ?? false;
  }

  /// Reconnect socket
  static void reconnect() {
    try {
      if (_socket != null && !_socket!.connected) {
        _attemptConnect();
      }
    } catch (e) {
      print('Error reconnecting socket: $e');
    }
  }
}