/// Feature: Messages
/// Widget: ConversationView
///
/// Chat conversation UI used for freeform conversation UIs.
import 'package:escort/styles/app_size.dart';
import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/features/messages/domain/models/chat_message.dart';

class ConversationView extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onSendMessage;

  const ConversationView({
    super.key,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  _ConversationViewState createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message =
                  widget.messages[widget.messages.length - 1 - index];
              return Container(
                margin: EdgeInsets.symmetric(
                  vertical: Insets.xs,
                  horizontal: Insets.med,
                ),
                alignment: message.isSentByMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.all(Insets.med),
                  decoration: BoxDecoration(
                    color: message.isSentByMe
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(Sizes.cardRadiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: message.isSentByMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: textStyle.bodyMdMedium.copyWith(
                          color: message.isSentByMe
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: Insets.xs),
                      Text(
                        message.timestamp,
                        style: textStyle.bodyMdMedium.copyWith(
                          fontSize: 10,
                          color: message.isSentByMe
                              ? colorScheme.onPrimary.withOpacity(0.6)
                              : colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(Insets.med),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: textStyle.bodyMdMedium.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: Insets.sm,
                      horizontal: Insets.med,
                    ),
                    fillColor: colorScheme.surface,
                    filled: true,
                  ),
                  style: textStyle.bodyMdMedium,
                ),
              ),
              SizedBox(width: Insets.sm),
              IconButton(
                icon: Icon(Icons.send, color: colorScheme.primary),
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    final newMessage = ChatMessage(
                      text: _messageController.text,
                      isSentByMe: true,
                      timestamp: 'Just now',
                    );
                    widget.onSendMessage(newMessage);
                    _messageController.clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
