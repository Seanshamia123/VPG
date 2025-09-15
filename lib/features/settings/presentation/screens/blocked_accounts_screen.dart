import 'package:escort/services/user_service.dart';
import 'package:flutter/material.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> blocked = [];
  final TextEditingController _blockIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await UserService.getBlockedUsers();
    final users = data['blocked_users'] as List<dynamic>? ?? [];
    setState(() {
      blocked = users.cast<Map<String, dynamic>>();
      loading = false;
    });
  }

  Future<void> _block() async {
    final idStr = _blockIdController.text.trim();
    if (idStr.isEmpty) return;
    final id = int.tryParse(idStr);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid numeric user ID')));
      return;
    }
    final res = await UserService.blockUser(id);
    if ((res['statusCode'] ?? 500) >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Failed to block user')));
    }
    _blockIdController.clear();
    await _load();
  }

  Future<void> _unblock(int userId) async {
    final res = await UserService.unblockUser(userId);
    if ((res['statusCode'] ?? 500) >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Failed to unblock')));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Blocked Accounts', style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blockIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter user ID to block',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _block,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                        child: const Text('Block'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: blocked.isEmpty
                      ? const Center(
                          child: Text('No blocked users', style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.separated(
                          itemCount: blocked.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
                          itemBuilder: (context, i) {
                            final u = blocked[i];
                            final name = (u['name'] ?? u['username'] ?? 'User').toString();
                            final id = (u['id'] ?? 0) as int;
                            return ListTile(
                              leading: const Icon(Icons.person_off, color: Colors.white),
                              title: Text(name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text('ID: $id', style: TextStyle(color: Colors.grey[400])),
                              trailing: TextButton(
                                onPressed: () => _unblock(id),
                                child: const Text('Unblock', style: TextStyle(color: Colors.yellow)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
/// Feature: Settings
/// Screen: BlockedAccountsScreen
