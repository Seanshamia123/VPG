/// Feature: Messages
/// Screen: ChatScreen
///
/// Displays a single conversation's messages and allows sending new ones.
/// Properly distinguishes messages by both sender_id AND sender_type (user vs advertiser)
/// AUTO-MARKS messages as read when conversation is opened
import 'dart:async';
import 'package:escort/services/conversations_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/socket_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String? title;
  final String? otherParticipantName;
  final String? otherParticipantAvatar;
  
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.otherParticipantName,
    this.otherParticipantAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  Timer? _poller;
  bool _sending = false;
  Timer? _typingTimer;
  int? currentUserId;
  String? currentUserType;
  String? otherParticipantName;
  String? otherParticipantAvatar;

  @override
  void initState() {
    super.initState();
    otherParticipantName = widget.otherParticipantName;
    otherParticipantAvatar = widget.otherParticipantAvatar;
    _loadCurrentUser();
    _load();
    _setupWebSocket();
  }

  /// Load current user ID and type from session
  Future<void> _loadCurrentUser() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      final userType = await UserSession.getUserType();
      
      // NORMALIZE the user type to match API expectations
      String normalizedType = _normalizeSenderType(userType ?? 'user');
      
      print('[ChatScreen] Loaded current user:');
      print('  - ID: $uid');
      print('  - Type: $normalizedType (raw: $userType)');
      
      if (mounted) {
        setState(() {
          currentUserId = uid;
          currentUserType = normalizedType;
        });
      }
    } catch (e) {
      print('[ChatScreen] Error loading current user: $e');
      if (mounted) {
        setState(() {
          currentUserType = 'user'; // Default fallback
        });
      }
    }
  }

  /// Set up WebSocket listeners for real-time updates
  void _setupWebSocket() {
    try {
      // Join the conversation room
      SocketService.joinConversation(widget.conversationId);

      // Listen for new messages
      SocketService.onNewMessage((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              messages.add(payload);
            });
            _scrollToBottom();
            // Auto-mark as read when new message arrives
            _markAsRead();
          }
        }
      });

      // Listen for message updates
      SocketService.onMessageUpdated((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              final index = messages.indexWhere((m) => m['id'] == payload['message_id']);
              if (index != -1) {
                messages[index].addAll(payload);
              }
            });
          }
        }
      });

      // Listen for message deletions
      SocketService.onMessageDeleted((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              messages.removeWhere((m) => m['id'] == payload['message_id']);
            });
          }
        }
      });
    } catch (e) {
      print('[ChatScreen] Error setting up WebSocket: $e');
    }

    // Fallback polling - runs every 20 seconds
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  /// Load messages from conversation
  /// CRITICAL: Backend automatically marks messages as read when fetching
  Future<void> _load() async {
    try {
      print('[ChatScreen] Loading messages for conversation ${widget.conversationId}');
      
      // Fetch messages - backend automatically marks them as read
      final msgs = await ConversationsService.getMessages(widget.conversationId);
      if (!mounted) return;
      
      print('[ChatScreen] Loaded ${msgs.length} messages');
      
      // Extract other participant's name from messages if not provided
      if (otherParticipantName == null && msgs.isNotEmpty) {
        for (var msg in msgs) {
          final senderId = int.tryParse((msg['sender_id'] ?? '').toString());
          final rawSenderType = (msg['sender_type'] ?? 'user').toString();
          final senderType = _normalizeSenderType(rawSenderType);
          
          // Find a message from the OTHER participant
          // Must compare BOTH ID and TYPE
          if (senderId != currentUserId || senderType != currentUserType) {
            final sender = msg['sender'] as Map<String, dynamic>?;
            if (sender != null) {
              otherParticipantName = (sender['name'] ?? sender['username'] ?? 'User').toString();
              otherParticipantAvatar = sender['profile_image_url']?.toString();
              print('[ChatScreen] Other participant identified: $otherParticipantName ($senderType:$senderId)');
              break;
            }
          }
        }
      }
      
      setState(() {
        messages = msgs;
        loading = false;
      });
      
      // Scroll to bottom after loading
      _scrollToBottom();
      
      // Explicitly mark as read for extra reliability
      await _markAsRead();
      
    } catch (e) {
      print('[ChatScreen] Error loading messages: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  /// CRITICAL: Mark all messages in this conversation as read
  Future<void> _markAsRead() async {
    try {
      await ConversationsService.markConversationAsRead(widget.conversationId);
      print('[ChatScreen] Marked conversation ${widget.conversationId} as read');
    } catch (e) {
      print('[ChatScreen] Error marking as read: $e');
    }
  }

  /// Normalize sender types to standard format
  String _normalizeSenderType(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'advertiser' || 
        normalized == 'escort' || 
        normalized == 'provider') {
      return 'advertiser';
    }
    return 'user';
  }

  /// Helper to check if message is from current user
  /// IMPORTANT: Must compare BOTH sender_id AND sender_type
  bool _isMessageFromCurrentUser(
    int? senderId, 
    String rawSenderType,
  ) {
    if (currentUserId == null || currentUserType == null) {
      return false;
    }
    
    final senderType = _normalizeSenderType(rawSenderType);
    final isMe = senderId == currentUserId && senderType == currentUserType;
    
    return isMe;
  }

  /// Handle typing indicator
  void _onTyping() {
    _typingTimer?.cancel();
    _getAndEmitTyping();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _getAndEmitStopTyping();
    });
  }

  /// Emit typing event via WebSocket
  Future<void> _getAndEmitTyping() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      if (uid != null) {
        SocketService.emitTyping(widget.conversationId, uid, currentUserType ?? 'user');
      }
    } catch (e) {
      print('[ChatScreen] Error emitting typing: $e');
    }
  }

  /// Emit stop typing event via WebSocket
  Future<void> _getAndEmitStopTyping() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      if (uid != null) {
        SocketService.emitStopTyping(widget.conversationId, uid);
      }
    } catch (e) {
      print('[ChatScreen] Error emitting stop typing: $e');
    }
  }

  /// Send message to conversation
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Get current user info
    final uidDyn = await UserSession.getUserId();
    final uid = int.tryParse(uidDyn.toString());
    if (uid == null) {
      print('[ChatScreen] ERROR: Could not get user ID');
      _showErrorSnackBar('Error: Could not identify user');
      return;
    }

    if (currentUserType == null) {
      print('[ChatScreen] ERROR: User type not loaded');
      _showErrorSnackBar('Error: User type not loaded');
      return;
    }

    setState(() => _sending = true);
    _controller.clear();

    _typingTimer?.cancel();
    SocketService.emitStopTyping(widget.conversationId, uid);

    try {
      print('[ChatScreen] ===== SENDING MESSAGE =====');
      print('[ChatScreen] Conversation ID: ${widget.conversationId}');
      print('[ChatScreen] Sender: $currentUserType:$uid');
      print('[ChatScreen] Content: $text');
      
      await ConversationsService.sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderType: currentUserType!,
        content: text,
      );
      
      print('[ChatScreen] ===== MESSAGE SENT SUCCESSFULLY =====');
      
      // Reload messages to ensure consistency
      await _load();
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] ===== ERROR SENDING MESSAGE =====');
      print('[ChatScreen] Error: $e');
      _showErrorSnackBar('Failed to send message');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Format timestamp for display
  String _formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(dt.year, dt.month, dt.day);

      if (msgDate == today) {
        // Today: show time
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '${hour}:${dt.minute.toString().padLeft(2, '0')} $period';
      } else {
        // Other days: show date and time
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    try {
      SocketService.leaveConversation(widget.conversationId);
      SocketService.offNewMessage();
      SocketService.offMessageUpdated();
      SocketService.offMessageDeleted();
    } catch (e) {
      print('[ChatScreen] Error in dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Dynamic title: "Chatting with [name]" or fallback
    final displayTitle = otherParticipantName != null
        ? 'Chatting with $otherParticipantName'
        : (widget.title ?? 'Chat');
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: otherParticipantAvatar != null &&
                      otherParticipantAvatar!.isNotEmpty
                  ? NetworkImage(otherParticipantAvatar!)
                  : null,
              child: otherParticipantAvatar == null ||
                      otherParticipantAvatar!.isEmpty
                  ? Text(
                      otherParticipantName != null && otherParticipantName!.isNotEmpty
                          ? otherParticipantName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                displayTitle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final m = messages[i];
                              final content = (m['content'] ?? '').toString();
                              final ts = (m['created_at'] ?? '').toString();
                              
                              // Extract sender information
                              final senderId = int.tryParse((m['sender_id'] ?? '').toString());
                              final rawSenderType = (m['sender_type'] ?? 'user').toString();
                              final senderType = _normalizeSenderType(rawSenderType);
                              
                              // Extract sender details
                              final sender = m['sender'] as Map<String, dynamic>? ?? {};
                              final senderName =
                                  (sender['name'] ?? sender['username'] ?? 'Unknown')
                                      .toString();
                              final senderAvatar = sender['profile_image_url']?.toString();
                              
                              // Check if message is from current user
                              // CRITICAL: Compare BOTH sender_id AND sender_type
                              final isMe = _isMessageFromCurrentUser(senderId, rawSenderType);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Other person's avatar (left side)
                                    if (!isMe) ...[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                                        backgroundImage: senderAvatar != null &&
                                                senderAvatar.isNotEmpty
                                            ? NetworkImage(senderAvatar)
                                            : null,
                                        child: senderAvatar == null || senderAvatar.isEmpty
                                            ? Text(
                                                senderName.isNotEmpty
                                                    ? senderName[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Message bubble
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? colorScheme.primary
                                                  : colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                                bottomRight: Radius.circular(isMe ? 4 : 18),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Show sender name for received messages
                                                if (!isMe) ...[
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        senderName,
                                                        style: TextStyle(
                                                          color: colorScheme.primary,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (senderType == 'advertiser') ...[
                                                        const SizedBox(width: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.tertiary,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'Advertiser',
                                                            style: TextStyle(
                                                              color: colorScheme.onTertiary,
                                                              fontSize: 9,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                ],
                                                // Message content
                                                Text(
                                                  content,
                                                  style: TextStyle(
                                                    color: isMe
                                                        ? colorScheme.onPrimary
                                                        : colorScheme.onSurfaceVariant,
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Timestamp
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              _formatMessageTime(ts),
                                              style: TextStyle(
                                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Message input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (_) => _onTyping(),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            minLines: 1,
                            maxLength: 1000,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                            textCapitalization: TextCapitalization.sentences,
                            enabled: !_sending,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _sending
                                ? colorScheme.primary.withOpacity(0.5)
                                : colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _sending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 20,
                                  ),
                            onPressed: _sending ? null : _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}