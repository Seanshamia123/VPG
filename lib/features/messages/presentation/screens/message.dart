import 'package:escort/features/messages/domain/models/converstaion.dart';
import 'package:escort/features/messages/presentation/widgets/chat_list.dart';
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
  List<Conversation> conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recent = await MessagesService.fetchRecent();
    setState(() {
      conversations = recent.map<Conversation>((c) {
        final id = (c['conversation_id'] ?? c['id'] ?? '').toString();
        final lm = c['last_message'] as Map<String, dynamic>?;
        final participant = c['participant'] as Map<String, dynamic>?;
        final username =
            (participant != null
                    ? (participant['name'] ?? participant['username'])
                    : (lm != null
                          ? (lm['sender']?['name'] ?? lm['sender']?['username'])
                          : 'Conversation $id'))
                .toString();
        final avatar =
            (participant != null
                    ? (participant['profile_image_url'] ?? '')
                    : '')
                .toString();
        final ts = (c['last_message_at'] ?? '').toString();
        return Conversation(
          id: id,
          username: username,
          profilePicture: avatar.isNotEmpty
              ? avatar
              : 'assets/images/profile.png',
          lastMessage: (lm != null ? (lm['content'] ?? '') : '').toString(),
          timestamp: ts,
        );
      }).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = context.textStyle;
    final insets = context.insets;
    double screenWidth = MediaQuery.of(context).size.width;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _buildMobileLayout(context, colorScheme, textStyle, insets);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    colorScheme,
    textStyle,
    insets,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Escort',
          style: textStyle.titleMdMedium.copyWith(color: colorScheme.primary),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        actions: [
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
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: avatar.isEmpty ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(Insets.med),
        child: ChatList(
          conversations: conversations,
          onSelectConversation: (id) async {
            final cid = int.tryParse(id);
            if (cid != null) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(conversationId: cid),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
/// Feature: Messages
/// Screen: Message (conversation hub)
