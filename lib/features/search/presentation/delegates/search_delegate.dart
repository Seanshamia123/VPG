/// Feature: Search
/// Delegate: AppSearchDelegate
///
/// General search across posts and users.
import 'package:flutter/material.dart';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class AppSearchDelegate extends SearchDelegate {
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

  @override
  String get searchFieldLabel => 'Search posts or users...';

  Future<List<Map<String, dynamic>>> _search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final posts = await ApiClient.getJson(
        '${ApiConfig.api}/posts/search?q=${Uri.encodeQueryComponent(query)}',
        auth: true,
      );
      final users = await ApiClient.getJson(
        '${ApiConfig.api}/users/search?q=${Uri.encodeQueryComponent(query)}',
        auth: true,
      );
      final items = <Map<String, dynamic>>[];
      if (posts['items'] is List) {
        for (final p in (posts['items'] as List)) {
          if (p is Map<String, dynamic>) items.add({'type': 'post', ...p});
        }
      } else if (posts['posts'] is List) {
        for (final p in (posts['posts'] as List)) {
          if (p is Map)
            items.add({'type': 'post', ...Map<String, dynamic>.from(p)});
        }
      }
      if (users['users'] is List) {
        for (final u in (users['users'] as List)) {
          if (u is Map)
            items.add({'type': 'user', ...Map<String, dynamic>.from(u)});
        }
      }
      return items;
    } catch (_) {
      return [];
    }
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
          return const Center(
            child: Text('No results', style: TextStyle(color: Colors.white70)),
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isPost = item['type'] == 'post';
            return ListTile(
              leading: Icon(
                isPost ? Icons.image : Icons.person,
                color: Colors.yellow,
              ),
              title: Text(
                isPost
                    ? (item['caption']?.toString() ?? 'Post')
                    : (item['name']?.toString() ??
                          item['username']?.toString() ??
                          'User'),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: isPost
                  ? Text(
                      'Post ID: ${item['id']}',
                      style: const TextStyle(color: Colors.white70),
                    )
                  : Text(
                      item['location']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
