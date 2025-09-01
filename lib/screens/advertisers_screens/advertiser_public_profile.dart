import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/api_client.dart';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/conversations_service.dart';
import 'package:escort/screens/messages/chat_screen.dart';
import 'package:escort/screens/advertisers%20screens/post_detail.dart';
import 'package:flutter/material.dart';

class AdvertiserPublicProfileScreen extends StatefulWidget {
  final int advertiserId;
  const AdvertiserPublicProfileScreen({super.key, required this.advertiserId});

  @override
  State<AdvertiserPublicProfileScreen> createState() => _AdvertiserPublicProfileScreenState();
}

class _AdvertiserPublicProfileScreenState extends State<AdvertiserPublicProfileScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool messaging = false;
  List<Map<String, dynamic>> posts = [];

  bool _isUrlValid(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('via.placeholder.com') || lower.contains('placeholder.com') || lower.contains('picsum.photos')) {
      return false;
    }
    return url.startsWith('http');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await AdvertiserService.getById(widget.advertiserId);
      final postsRes = await ApiClient.getJson(
        '${ApiConfig.api}/posts/advertiser/${widget.advertiserId}',
        auth: true,
      );
      final list = (postsRes['posts'] is List)
          ? (postsRes['posts'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      setState(() {
        data = res;
        posts = list;
        loading = false;
      });
    } catch (_) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _startChat() async {
    setState(() => messaging = true);
    try {
      final conv = await ConversationsService.getOrCreateWithAdvertiser(widget.advertiserId);
      final cid = int.tryParse('${conv['id'] ?? conv['conversation_id'] ?? 0}') ?? 0;
      if (cid > 0 && mounted) {
        final title = (data?['username'] ?? data?['name'] ?? 'Chat').toString();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(conversationId: cid, title: title)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    } finally {
      if (mounted) setState(() => messaging = false);
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
          (data == null)
              ? 'Advertiser'
              : (data!['username']?.toString().isNotEmpty == true
                  ? '@${data!['username']}'
                  : (data!['name'] ?? 'Advertiser').toString()),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.yellow),
            tooltip: 'Messages',
            onPressed: () => Navigator.of(context).pushNamed('/messages'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Not found', style: TextStyle(color: Colors.white70)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (_) {
                            final raw = (data!['profile_image_url']?.toString() ?? '');
                            final valid = _isUrlValid(raw);
                            return CircleAvatar(
                              radius: 40,
                              backgroundImage: valid ? NetworkImage(raw) : null,
                              backgroundColor: Colors.grey[800],
                              child: valid
                                  ? null
                                  : const Icon(Icons.person, color: Colors.white70, size: 40),
                            );
                          }),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data!['name'] ?? data!['username'] ?? 'Advertiser').toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${(data!['username'] ?? '').toString()}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (data!['location'] ?? '').toString(),
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: messaging ? null : _startChat,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.yellow,
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: messaging
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                              ),
                                            )
                                          : const Icon(Icons.send),
                                      label: Text(messaging ? 'Messaging…' : 'Message'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      if ((data!['bio']?.toString() ?? '').isNotEmpty)
                        Text(
                          (data!['bio'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Text('Posts', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      posts.isEmpty
                          ? Container(
                              height: 160,
                              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
                              child: const Center(
                                child: Text('No posts yet', style: TextStyle(color: Colors.white70)),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final p = posts[index];
                                final url = (p['image_url'] ?? '').toString();
                                final valid = _isUrlValid(url);
                                return GestureDetector(
                                  onTap: () async {
                                    // Lazily import to avoid circular import warnings
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)),
                                    );
                                  },
                                  child: Container(
                                    color: Colors.grey[900],
                                    child: valid
                                        ? Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white24),
                                          )
                                        : const Icon(Icons.image_not_supported, color: Colors.white24),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
