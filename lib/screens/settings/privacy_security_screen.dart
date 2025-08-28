import 'package:escort/services/settings_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool loading = true;
  bool showOnlineStatus = true;
  bool readReceipts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await UserSession.getUserId();
    if (id != null) {
      final data = await SettingsService.getByUserId(int.parse(id.toString()));
      if (data != null) {
        setState(() {
          showOnlineStatus = data['show_online_status'] ?? true;
          readReceipts = data['read_receipts'] ?? true;
        });
      }
    }
    setState(() => loading = false);
  }

  Future<void> _persist() async {
    final id = await UserSession.getUserId();
    if (id == null) return;
    await SettingsService.createOrUpdate(int.parse(id.toString()), {
      'show_online_status': showOnlineStatus,
      'read_receipts': readReceipts,
    });
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
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _switchTile(
            icon: Icons.visibility,
            title: 'Show Online Status',
            subtitle: 'Let others see when you\'re online',
            value: showOnlineStatus,
            onChanged: (v) async {
              setState(() => showOnlineStatus = v);
              await _persist();
            },
          ),
          _switchTile(
            icon: Icons.done_all,
            title: 'Read Receipts',
            subtitle: 'Show when you\'ve read messages',
            value: readReceipts,
            onChanged: (v) async {
              setState(() => readReceipts = v);
              await _persist();
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.shield, color: Colors.white),
            title: const Text('Two-Factor Authentication', style: TextStyle(color: Colors.white)),
            subtitle: Text('Coming soon', style: TextStyle(color: Colors.grey[400])),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Two-Factor Authentication will be available soon'), backgroundColor: Colors.grey[800]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5))),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.yellow,
          activeTrackColor: Colors.yellow.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[700],
        ),
      ),
    );
  }
}

