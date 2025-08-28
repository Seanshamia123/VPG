import 'package:escort/screens/advertisers_screens/advertiser_public_profile.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:flutter/material.dart';

class AdvertiserSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search advertisers by name or @username';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Future<List<Map<String, dynamic>>> _search(String q) async {
    return AdvertiserService.search(q);
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No advertisers found', style: TextStyle(color: Colors.white70)));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            final name = (a['name'] ?? a['username'] ?? 'Advertiser').toString();
            final username = (a['username'] ?? '').toString();
            final location = (a['location'] ?? '').toString();
            final avatar = (a['profile_image_url'] ?? '').toString();
            final id = int.tryParse(a['id']?.toString() ?? '') ?? 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                backgroundColor: Colors.grey[800],
                child: avatar.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${username.isNotEmpty ? '@$username • ' : ''}$location', style: TextStyle(color: Colors.grey[400])),
              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
              onTap: () {
                if (id > 0) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdvertiserPublicProfileScreen(advertiserId: id)),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}

