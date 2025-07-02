import 'package:escort/models/messages/converstaion.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:flutter/material.dart';

class ChatList extends StatelessWidget {
  final List<Conversation> conversations;
  final Function(String) onSelectConversation;

  const ChatList({
    super.key,
    required this.conversations,
    required this.onSelectConversation,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final colorScheme = Theme.of(context).colorScheme;

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
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: context.isMobile
                          ? Sizes.avatarRadiusSm
                          : context.isTablet
                          ? Sizes.avatarRadiusMd
                          : Sizes.avatarRadiusLg,
                      backgroundImage: AssetImage(conversation.profilePicture),
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
                      onSelectConversation(conversation.id);
                    },
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Insets.med,
                      vertical: Insets.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.cardRadiusSm),
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
