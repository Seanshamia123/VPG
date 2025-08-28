import 'package:escort/services/advertiser_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await AdvertiserService.getById(widget.advertiserId);
    setState(() {
      data = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Advertiser', style: TextStyle(color: Colors.white)),
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
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: (data!['profile_image_url']?.toString() ?? '').isNotEmpty
                                ? NetworkImage(data!['profile_image_url'])
                                : null,
                            backgroundColor: Colors.grey[800],
                            child: (data!['profile_image_url']?.toString() ?? '').isEmpty
                                ? const Icon(Icons.person, color: Colors.white70, size: 36)
                                : null,
                          ),
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
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (data!['bio'] ?? '').toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
    );
  }
}

