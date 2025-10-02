/// Feature: Messages
/// Widget: ChatList
///
/// Searchable conversations list with inline advertiser search.
import 'dart:async';
import 'package:escort/features/messages/domain/models/converstaion.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/conversations_service.dart' as conv;
import 'package:escort/features/messages/presentation/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class ChatList extends StatefulWidget {
  final List<Conversation> conversations;
  final Function(String) onSelectConversation;

  const ChatList({
    super.key,
    required this.conversations,
    required this.onSelectConversation,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String _query = '';
  bool _searching = false;
  List<Map<String, dynamic>> _advResults = [];
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final colorScheme = Theme.of(context).colorScheme;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.conversations
        : widget.conversations.where((c) {
            final u = c.username.toLowerCase();
            final m = c.lastMessage.toLowerCase();
            return u.contains(q) || m.contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(Insets.med),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: textStyle.bodyMdMedium.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(Sizes.inputFieldRadius),
                ),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(Sizes.inputFieldRadius),
                ),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(Sizes.inputFieldRadius),
                ),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              fillColor: colorScheme.surface,
              filled: true,
              contentPadding: EdgeInsets.symmetric(vertical: Insets.sm),
            ),
            style: textStyle.bodyMdMedium,
            onChanged: (v) async {
              setState(() => _query = v);
              _debounce?.cancel();
              if (v.trim().length < 2) {
                setState(() {
                  _advResults = [];
                  _searching = false;
                });
                return;
              }
              _debounce = Timer(const Duration(milliseconds: 300), () async {
                setState(() => _searching = true);
                try {
                  final res = await AdvertiserService.search(
                    v.trim(),
                    page: 1,
                    perPage: 8,
                  );
                  if (!mounted) return;
                  setState(() {
                    _advResults = res;
                    _searching = false;
                  });
                } catch (_) {
                  if (!mounted) return;
                  setState(() {
                    _advResults = [];
                    _searching = false;
                  });
                }
              });
            },
          ),
        ),
        if (_query.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.med),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(Sizes.cardRadiusSm),
              ),
              constraints: const BoxConstraints(maxHeight: 320),
              child: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (_advResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'No advertisers found',
                              style: textStyle.bodyMdMedium.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _advResults.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: colorScheme.outline),
                            itemBuilder: (context, i) {
                              final a = _advResults[i];
                              final id =
                                  int.tryParse(a['id']?.toString() ?? '') ?? 0;
                              final name =
                                  (a['name'] ?? a['username'] ?? 'Advertiser')
                                      .toString();
                              final username = (a['username'] ?? '').toString();
                              final rawAvatar = (a['profile_image_url'] ?? '')
                                  .toString();
                              final avatar =
                                  (rawAvatar.isNotEmpty &&
                                      !rawAvatar.contains(
                                        'via.placeholder.com',
                                      ) &&
                                      !rawAvatar.contains('placeholder.com') &&
                                      !rawAvatar.contains('picsum.photos'))
                                  ? rawAvatar
                                  : '';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  backgroundColor: Colors.grey[800],
                                  child: avatar.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: textStyle.bodyMdMedium,
                                ),
                                subtitle: Text(
                                  username.isNotEmpty ? '@$username' : '',
                                  style: textStyle.bodyMdMedium.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.send,
                                  color: Colors.yellow,
                                ),
                                onTap: id <= 0
                                    ? null
                                    : () async {
                                        try {
                                          final conversationData = await conv
                                              .ConversationsService.getOrCreateWithAdvertiser(id);
                                          final cid =
                                              int.tryParse(
                                                '${conversationData['id'] ?? conversationData['conversation_id'] ?? 0}',
                                              ) ??
                                              0;
                                          if (cid > 0 && mounted) {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  conversationId: cid,
                                                  title: name,
                                                ),
                                              ),
                                            );
                                            // Clear search after opening chat
                                            if (mounted) {
                                              setState(() {
                                                _query = '';
                                                _advResults = [];
                                              });
                                            }
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open chat: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              );
                            },
                          )),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: Insets.lg),
                    child: Text(
                      'No conversations found',
                      style: textStyle.bodyMdMedium.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final isNetwork = conversation.profilePicture.startsWith(
                      'http',
                    );
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: context.isMobile
                                ? Sizes.avatarRadiusSm
                                : context.isTablet
                                ? Sizes.avatarRadiusMd
                                : Sizes.avatarRadiusLg,
                            backgroundImage: isNetwork
                                ? NetworkImage(conversation.profilePicture)
                                : AssetImage(conversation.profilePicture)
                                      as ImageProvider,
                            backgroundColor: Colors.grey[800],
                            child: isNetwork
                                ? null
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                          ),
                          title: Text(
                            conversation.username,
                            style: textStyle.bodyLgBold,
                          ),
                          subtitle: Text(
                            conversation.lastMessage,
                            style: textStyle.bodyMdMedium.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          trailing: Text(
                            conversation.timestamp,
                            style: textStyle.bodyMdMedium.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          onTap: () {
                            widget.onSelectConversation(conversation.id);
                          },
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Insets.med,
                            vertical: Insets.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Sizes.cardRadiusSm,
                            ),
                          ),
                          hoverColor: colorScheme.primary.withOpacity(0.05),
                        ),
                        Divider(height: 1, color: colorScheme.outline),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
