import 'package:escort/models/messages/chat_message.dart';
import 'package:escort/models/messages/converstaion.dart';
import 'package:escort/widgets/messages/chat_list.dart';
import 'package:escort/widgets/messages/converstion_view.dart';
import 'package:escort/widgets/messages/placeholder.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:flutter/material.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  String? selectedConversationId;

  final List<Conversation> conversations = [
    Conversation(
      id: '1',
      username: 'Honei_Atlanta',
      profilePicture: 'assets/images/profile.png',
      lastMessage: 'You sent a post',
      timestamp: '8m',
    ),
    Conversation(
      id: '2',
      username: 'Sweet_Caroline',
      profilePicture: 'assets/images/profile.png',
      lastMessage: 'Hey, how are you?',
      timestamp: '4h',
    ),
  ];

  final Map<String, List<ChatMessage>> conversationMessages = {
    '1': [
      ChatMessage(text: 'Hello!', isSentByMe: false, timestamp: '10:00 AM'),
      ChatMessage(text: 'Hi there!', isSentByMe: true, timestamp: '10:01 AM'),
    ],
    '2': [
      ChatMessage(
        text: 'How are you?',
        isSentByMe: false,
        timestamp: '11:00 AM',
      ),
      ChatMessage(
        text: 'I\'m good, thanks!',
        isSentByMe: true,
        timestamp: '11:02 AM',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = context.textStyle;
    final insets = context.insets;
    double screenWidth = MediaQuery.of(context).size.width;

    return screenWidth < 600
        ? _buildMobileLayout(context, colorScheme, textStyle, insets)
        : _buildDesktopTabletLayout(context, colorScheme, textStyle);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    colorScheme,
    textStyle,
    insets,
  ) {
    return Scaffold(
      appBar: selectedConversationId == null
          ? AppBar(
              title: Text(
                'Escort',
                style: textStyle.titleMdMedium.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              backgroundColor: colorScheme.surface,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {},
                  tooltip: 'Home',
                ),
                Padding(
                  padding: EdgeInsets.all(Insets.sm),
                  child: CircleAvatar(
                    radius: context.isMobile
                        ? Sizes.avatarRadiusSm
                        : context.isTablet
                        ? Sizes.avatarRadiusMd
                        : Sizes.avatarRadiusLg,
                    backgroundImage: AssetImage("assets/images/profile.png"),
                  ),
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedConversationId = null;
                  });
                },
                tooltip: 'Back',
              ),
              title: Text(
                conversations
                    .firstWhere((conv) => conv.id == selectedConversationId)
                    .username,
                style: textStyle.titleMdMedium,
              ),
              backgroundColor: colorScheme.surface,
              elevation: 1,
            ),
      body: Padding(
        padding: EdgeInsets.all(Insets.med),
        child: selectedConversationId == null
            ? ChatList(
                conversations: conversations,
                onSelectConversation: (id) {
                  setState(() {
                    selectedConversationId = id;
                  });
                },
              )
            : ConversationView(
                messages: conversationMessages[selectedConversationId] ?? [],
                onSendMessage: (newMessage) {
                  setState(() {
                    conversationMessages[selectedConversationId]!.add(
                      newMessage,
                    );
                  });
                },
              ),
      ),
    );
  }

  Widget _buildDesktopTabletLayout(
    BuildContext context,
    colorScheme,
    textStyle,
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {},
            tooltip: 'Home',
          ),
          Padding(
            padding: EdgeInsets.all(Insets.sm),
            child: CircleAvatar(
              radius: context.isMobile
                  ? Sizes.avatarRadiusSm
                  : context.isTablet
                  ? Sizes.avatarRadiusMd
                  : Sizes.avatarRadiusLg,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            color: colorScheme.surfaceVariant,
            child: ChatList(
              conversations: conversations,
              onSelectConversation: (id) {
                setState(() {
                  selectedConversationId = id;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: colorScheme.outline)),
                color: colorScheme.background,
              ),
              child: selectedConversationId == null
                  ? const PlaceholderWidget()
                  : ConversationView(
                      messages:
                          conversationMessages[selectedConversationId] ?? [],
                      onSendMessage: (newMessage) {
                        setState(() {
                          conversationMessages[selectedConversationId]!.add(
                            newMessage,
                          );
                        });
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
