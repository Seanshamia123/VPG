import 'package:escort/features/messages/presentation/screens/chat_screen.dart';
import 'package:escort/services/messages_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:flutter/material.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  bool loading = true;
  List<Map<String, dynamic>> conversations = [];
  String searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final recent = await MessagesService.fetchRecent();
      
      // Sort by last_message_at (most recent first) - already handled by backend
      recent.sort((a, b) {
        final aTime = a['last_message_at'] ?? '';
        final bTime = b['last_message_at'] ?? '';
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        conversations = recent;
        loading = false;
      });
    } catch (e) {
      print('[Message] Error loading conversations: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      await _load();
      return;
    }

    setState(() => loading = true);
    try {
      final results = await MessagesService.searchConversations(query);
      setState(() {
        conversations = results;
        searchQuery = query;
        loading = false;
      });
    } catch (e) {
      print('[Message] Error searching conversations: $e');
      setState(() => loading = false);
    }
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
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

  String _formatMessagePreview(String content, int senderId, int currentUserId) {
    if (content.isEmpty) return 'Tap to start chatting';
    
    // Add "You: " prefix if current user sent the message
    final prefix = senderId == currentUserId ? 'You: ' : '';
    final maxLength = 65;
    
    if (content.length > maxLength) {
      return '$prefix${content.substring(0, maxLength)}...';
    }
    return '$prefix$content';
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
          _buildSearchBar(context, colorScheme),
          Expanded(
            child: conversations.isEmpty
                ? _buildEmptyState(context, colorScheme)
                : _buildConversationsList(context, colorScheme),
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
        style: textStyle.titleMdMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ) ?? TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      actions: [
        FutureBuilder<String?>(
          future: UserSession.getProfileImageUrl(),
          builder: (context, snap) {
            final avatar = (snap.data ?? '').toString();
            return Padding(
              padding: EdgeInsets.all(Insets.sm ?? 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: avatar.isEmpty
                    ? Icon(Icons.person, size: 20, color: colorScheme.primary)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(Insets.med ?? 12.0),
      color: colorScheme.surface,
      child: TextField(
        controller: _searchController,
        onChanged: _search,
        style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            size: 22,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
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
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Start a conversation to see it here',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _load,
      color: colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          return _buildConversationTile(context, colorScheme, conv);
        },
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ColorScheme colorScheme,
    Map<String, dynamic> conv,
  ) {
    final convId = int.tryParse(
        (conv['conversation_id'] ?? conv['id'] ?? '').toString());
    final participant = conv['participant'] as Map<String, dynamic>?;
    final lastMsg = conv['last_message'] as Map<String, dynamic>?;
    final sender = lastMsg?['sender'] as Map<String, dynamic>?;

    // Get participant info
    final participantName = participant?['name']?.toString() ??
        participant?['username']?.toString() ??
        sender?['name']?.toString() ??
        sender?['username']?.toString() ??
        'Unknown';

    final participantAvatar = participant?['profile_image_url']?.toString() ??
        sender?['profile_image_url']?.toString() ??
        '';

    // Get message info
    final lastMessageContent = lastMsg?['content']?.toString() ?? '';
    final senderId = int.tryParse((lastMsg?['sender_id'] ?? 0).toString()) ?? 0;
    final lastMessageTime = conv['last_message_at']?.toString() ?? '';
    
    // Get current user ID for "You:" prefix
    final currentUserId = 0; // You'll need to pass this from UserSession
    
    final messagePreview = _formatMessagePreview(
      lastMessageContent,
      senderId,
      currentUserId,
    );
    final timeFormatted = _formatTimestamp(lastMessageTime);

    // Unread count
    final unreadCount = int.tryParse((conv['unread_count'] ?? 0).toString()) ?? 0;
    final hasUnread = unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: convId != null
            ? () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: convId,
                      otherParticipantName: participantName,
                    ),
                  ),
                );
                await _load();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                backgroundImage:
                    participantAvatar.isNotEmpty ? NetworkImage(participantAvatar) : null,
                child: participantAvatar.isEmpty
                    ? Text(
                        participantName.isNotEmpty
                            ? participantName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Expanded(
                          child: Text(
                            participantName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            color: hasUnread
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Message preview
                        Expanded(
                          child: Text(
                            messagePreview,
                            style: TextStyle(
                              color: hasUnread
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge
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
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 12,
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