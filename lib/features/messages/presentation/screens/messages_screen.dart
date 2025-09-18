/// Feature: Messages
/// Screen: MessagesScreen
///
/// Shows the list of recent conversations for the current user.
/// Extracted from `lib/screens/home_screen.dart` to keep files focused.
import 'package:flutter/material.dart';
import 'package:escort/services/messages_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _futureConversations;

  @override
  void initState() {
    super.initState();
    _futureConversations = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final res = await MessagesService.fetchRecent(page: 1, perPage: 20);
      return res;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Messages', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(child: Text('No conversations yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final conv = items[index];
              final last = conv['last_message'] as Map<String, dynamic>?;
              final sender = last?['sender'] as Map<String, dynamic>?;
              final name = sender?['name'] ?? sender?['username'] ?? 'Conversation';
              final message = last?['content'] ?? '';
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: Theme.of(context).colorScheme.outlineVariant, child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                              Text('', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(message.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
