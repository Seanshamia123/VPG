/// Feature: Messages
/// Screen: ChatScreen
///
/// Displays a single conversation's messages and allows sending new ones.
import 'dart:async';
import 'package:escort/services/conversations_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/socket_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String? title;
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.title,
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

  @override
  void initState() {
    super.initState();
    _load();
    // Realtime via Socket.IO
    try {
      SocketService.joinConversation(widget.conversationId);
      SocketService.onNewMessage((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          setState(() {
            messages.add(payload);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.jumpTo(_scroll.position.maxScrollExtent);
            }
          });
        }
      });
    } catch (_) {}
    // Fallback polling
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scroll.dispose();
    try {
      SocketService.leaveConversation(widget.conversationId);
      SocketService.offNewMessage();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    final msgs = await ConversationsService.getMessages(widget.conversationId);
    if (!mounted) return;
    setState(() {
      messages = msgs;
      loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uidDyn = await UserSession.getUserId();
    final uid = int.tryParse(uidDyn.toString());
    if (uid == null) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ConversationsService.sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        content: text,
      );
      await _load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.title ?? 'Chat',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final content = (m['content'] ?? '').toString();
                      final ts = (m['created_at'] ?? '').toString();
                      final senderId =
                          int.tryParse(m['sender_id']?.toString() ?? '') ?? -1;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                content,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ts,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.yellow,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.yellow),
                        onPressed: _sending ? null : _send,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
