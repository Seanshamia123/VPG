import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:escort/l10n/app_localizations.dart';

class DownloadPreferencesScreen extends StatefulWidget {
  const DownloadPreferencesScreen({super.key});

  @override
  State<DownloadPreferencesScreen> createState() => _DownloadPreferencesScreenState();
}

class _DownloadPreferencesScreenState extends State<DownloadPreferencesScreen> {
  bool wifiOnly = true;
  bool autoPhotos = true;
  bool autoVideos = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      wifiOnly = p.getBool('dl_wifi_only') ?? wifiOnly;
      autoPhotos = p.getBool('dl_auto_photos') ?? autoPhotos;
      autoVideos = p.getBool('dl_auto_videos') ?? autoVideos;
      loading = false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dl_wifi_only', wifiOnly);
    await p.setBool('dl_auto_photos', autoPhotos);
    await p.setBool('dl_auto_videos', autoVideos);
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.downloadPreferencesTitle, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              await _save();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download preferences saved')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.yellow)),
          )
        ],
      ),
      body: ListView(
        children: [
          _switchTile(
            icon: Icons.wifi,
            title: 'Wi‑Fi only',
            subtitle: 'Download media on Wi‑Fi only',
            value: wifiOnly,
            onChanged: (v) => setState(() => wifiOnly = v),
          ),
          _switchTile(
            icon: Icons.photo,
            title: 'Auto‑download photos',
            subtitle: 'Automatically download photos you receive',
            value: autoPhotos,
            onChanged: (v) => setState(() => autoPhotos = v),
          ),
          _switchTile(
            icon: Icons.videocam,
            title: 'Auto‑download videos',
            subtitle: 'Automatically download videos you receive',
            value: autoVideos,
            onChanged: (v) => setState(() => autoVideos = v),
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
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])),
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
/// Feature: Settings
/// Screen: DownloadPreferencesScreen
