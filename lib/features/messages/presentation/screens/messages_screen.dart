import 'package:escort/features/messages/presentation/screens/chat_screen.dart';
import 'package:escort/services/messages_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> with WidgetsBindingObserver {
  bool loading = true;
  List<Map<String, dynamic>> conversations = [];
  String searchQuery = '';
  late TextEditingController _searchController;
  Timer? _refreshTimer;
  int? currentUserId;
  String? currentUserType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _loadCurrentUser();
    _load();
    
    // Auto-refresh every 10 seconds to keep conversations updated
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (searchQuery.isEmpty && mounted) {
        _load(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  /// Load current user info for message comparison
  Future<void> _loadCurrentUser() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      final userType = await UserSession.getUserType();
      
      // Normalize the user type
      String normalizedType = _normalizeSenderType(userType ?? 'user');
      
      print('[Message] Current user: $normalizedType:$uid');
      
      if (mounted) {
        setState(() {
          currentUserId = uid;
          currentUserType = normalizedType;
        });
      }
    } catch (e) {
      print('[Message] Error loading current user: $e');
      if (mounted) {
        setState(() {
          currentUserType = 'user'; // Default fallback
        });
      }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() => loading = true);
    }
    
    try {
      final recent = await MessagesService.fetchRecent();
      
      print('[Message] Loaded ${recent.length} conversations');
      for (var conv in recent) {
        print('  Conv: ${conv['conversation_id']}');
        print('  Last msg: ${conv['last_message']}');
      }
      
      if (mounted) {
        setState(() {
          conversations = recent;
          loading = false;
        });
      }
    } catch (e) {
      print('[Message] Error loading conversations: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _search(String query) async {
    setState(() => searchQuery = query);
    
    if (query.isEmpty) {
      await _load();
      return;
    }

    try {
      final results = await MessagesService.searchConversations(query);
      if (mounted) {
        setState(() => conversations = results);
      }
    } catch (e) {
      print('[Message] Error searching conversations: $e');
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(dt.year, dt.month, dt.day);

      if (msgDate == today) {
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '${hour}:${dt.minute.toString().padLeft(2, '0')} $period';
      } else if (msgDate == yesterday) {
        return 'Yesterday';
      } else if (now.difference(dt).inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatMessagePreview(String? content, bool isFromMe) {
    if (content == null || content.trim().isEmpty) {
      return 'Tap to start chatting';
    }
    
    String preview = content.trim();
    
    // Add "You: " prefix if message is from current user
    if (isFromMe) {
      preview = 'You: $preview';
    }
    
    // Truncate if too long
    if (preview.length > 65) {
      preview = '${preview.substring(0, 65)}...';
    }
    
    return preview;
  }

  bool _isMessageFromMe(Map<String, dynamic>? lastMessage) {
    if (lastMessage == null || currentUserId == null || currentUserType == null) {
      return false;
    }
    
    try {
      final messageSenderId = int.tryParse((lastMessage['sender_id'] ?? '').toString());
      final rawSenderType = (lastMessage['sender_type'] ?? 'user').toString();
      final messageSenderType = _normalizeSenderType(rawSenderType);
      
      final isMe = messageSenderId == currentUserId && messageSenderType == currentUserType;
      
      print('[Message] Checking message from: $messageSenderType:$messageSenderId');
      print('  Current user: $currentUserType:$currentUserId');
      print('  Is from me: $isMe');
      
      return isMe;
    } catch (e) {
      print('[Message] Error checking message sender: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = context.textStyle;
    final insets = context.insets;

    if (loading && conversations.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: _buildAppBar(context, colorScheme, textStyle, insets),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(context, colorScheme, textStyle, insets),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(colorScheme),
          // Conversations list
          Expanded(
            child: conversations.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildConversationsList(colorScheme),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    dynamic textStyle,
    dynamic insets,
  ) {
    return AppBar(
      title: Text(
        'Messages',
        style: textStyle.titleMdMedium.copyWith(color: colorScheme.primary),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 1,
      actions: [
        // Total unread count badge
        FutureBuilder<int>(
          future: MessagesService.getUnreadCount(),
          builder: (context, snapshot) {
            final totalUnread = snapshot.data ?? 0;
            if (totalUnread > 0) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalUnread > 99 ? '99+' : totalUnread.toString(),
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Profile avatar
        FutureBuilder<String?>(
          future: UserSession.getProfileImageUrl(),
          builder: (context, snap) {
            final avatar = (snap.data ?? '').toString();
            return Padding(
              padding: EdgeInsets.all(Insets.sm),
              child: CircleAvatar(
                radius: context.isMobile
                    ? Sizes.avatarRadiusSm
                    : context.isTablet
                        ? Sizes.avatarRadiusMd
                        : Sizes.avatarRadiusLg,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                backgroundColor: colorScheme.surfaceVariant,
                child: avatar.isEmpty
                    ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _search,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No conversations yet'
                : 'No results found',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Start a conversation to see it here'
                : 'Try a different search term',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _load,
      color: colorScheme.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 88,
          endIndent: 16,
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          return _buildConversationTile(conversations[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conv,
    ColorScheme colorScheme,
  ) {
    final convId = int.tryParse(
        (conv['conversation_id'] ?? conv['id'] ?? '').toString());
    
    final participant = conv['participant'] as Map<String, dynamic>?;
    final lastMsg = conv['last_message'] as Map<String, dynamic>?;
    final sender = lastMsg?['sender'] as Map<String, dynamic>?;

    print('[Message] Building tile for conv $convId');
    print('  Participant: $participant');
    print('  Last message: $lastMsg');
    print('  Sender: $sender');

    // Get participant info
    final participantName = participant != null
        ? (participant['name'] ?? participant['username'] ?? 'User').toString()
        : (sender?['name'] ?? sender?['username'] ?? 'User').toString();

    final participantAvatar = participant != null
        ? (participant['profile_image_url'] ?? '').toString()
        : (sender?['profile_image_url'] ?? '').toString();

    // Message details
    final lastMessageContent = (lastMsg?['content'] ?? '').toString();
    final lastMessageTime = (conv['last_message_at'] ?? '').toString();
    final timeFormatted = _formatTimestamp(lastMessageTime);
    
    // Unread count
    final unreadCount = int.tryParse((conv['unread_count'] ?? 0).toString()) ?? 0;
    final hasUnread = unreadCount > 0;

    // Check if message is from current user
    final isFromMe = _isMessageFromMe(lastMsg);
    final messagePreview = _formatMessagePreview(lastMessageContent, isFromMe);

    print('  Preview: $messagePreview');
    print('  Is from me: $isFromMe');
    print('  Unread: $unreadCount');

    return Material(
      color: hasUnread
          ? colorScheme.primary.withOpacity(0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: convId != null
            ? () async {
                // Mark as read when opening
                if (hasUnread && convId != null) {
                  MessagesService.markConversationAsRead(convId);
                }
                
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: convId,
                      otherParticipantName: participantName,
                    ),
                  ),
                );
                
                // Refresh list when returning
                await _load(silent: false);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.surfaceVariant,
                backgroundImage: participantAvatar.isNotEmpty
                    ? NetworkImage(participantAvatar)
                    : null,
                child: participantAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Conversation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            color: hasUnread
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Message preview and unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messagePreview,
                            style: TextStyle(
                              color: hasUnread
                                  ? colorScheme.onSurface.withOpacity(0.9)
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread count badge (WhatsApp style)
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 999
                                    ? '999+'
                                    : unreadCount.toString(),
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}