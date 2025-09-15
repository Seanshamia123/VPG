/// Feature: Settings
/// Screen: NotificationPreferencesScreen
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool messages = true;
  bool comments = true;
  bool mentions = true;
  bool marketing = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      messages = p.getBool('notif_messages') ?? messages;
      comments = p.getBool('notif_comments') ?? comments;
      mentions = p.getBool('notif_mentions') ?? mentions;
      marketing = p.getBool('notif_marketing') ?? marketing;
      loading = false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif_messages', messages);
    await p.setBool('notif_comments', comments);
    await p.setBool('notif_mentions', mentions);
    await p.setBool('notif_marketing', marketing);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notification Preferences', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              await _save();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification preferences saved')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.yellow)),
          )
        ],
      ),
      body: ListView(
        children: [
          _tile('Messages', 'New message alerts', messages, (v) => setState(() => messages = v)),
          _tile('Comments', 'When someone comments', comments, (v) => setState(() => comments = v)),
          _tile('Mentions', 'When you are mentioned', mentions, (v) => setState(() => mentions = v)),
          _tile('Marketing', 'Product updates and offers', marketing, (v) => setState(() => marketing = v)),
        ],
      ),
    );
  }

  Widget _tile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5))),
      child: ListTile(
        leading: const Icon(Icons.tune, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
        trailing: Switch(
          value: value,
          onChanged: (v) {
            onChanged(v);
          },
          activeColor: Colors.yellow,
          activeTrackColor: Colors.yellow.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[700],
        ),
      ),
    );
  }
}
