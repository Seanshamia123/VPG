/// Feature: Settings
/// Screen: SettingsScreen (hub for settings)
import 'package:flutter/material.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/settings_service.dart';
import 'package:escort/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:escort/localization/locale_controller.dart';
import 'package:escort/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:escort/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:escort/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:escort/features/settings/presentation/screens/privacy_security_screen.dart';
import 'package:escort/features/settings/presentation/screens/download_preferences_screen.dart';
import 'package:escort/features/settings/presentation/screens/blocked_accounts_screen.dart';
import 'package:escort/features/settings/presentation/screens/profile_settings_screen.dart';
import 'package:escort/l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:escort/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  // bool _darkModeEnabled = true;
  bool _autoPlayVideos = false;
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Dark';
  bool _loading = true;

  // Local preference keys
  static const _kPrefLocationEnabled = 'pref_location_enabled';
  static const _kPrefAutoPlayVideos = 'pref_auto_play_videos';

  @override
  void initState() {
    super.initState();
    final mode = context.read<ThemeController>().mode;
    _selectedTheme = _labelForMode(mode);
    _loadLocalPrefs().then((_) => _loadSettings());
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationEnabled = prefs.getBool(_kPrefLocationEnabled) ?? _locationEnabled;
      _autoPlayVideos = prefs.getBool(_kPrefAutoPlayVideos) ?? _autoPlayVideos;
    });
  }

  Future<void> _loadSettings() async {
    final id = await UserSession.getUserId();
    if (id == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final data = await SettingsService.getByUserId(int.parse(id.toString()));
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _notificationsEnabled = data['notification_enabled'] ?? _notificationsEnabled;
        _showOnlineStatus = data['show_online_status'] ?? _showOnlineStatus;
        _readReceipts = data['read_receipts'] ?? _readReceipts;
        _selectedLanguage = data['selected_language']?.toString() ?? _selectedLanguage;
        final theme = data['selected_theme']?.toString() ?? _selectedTheme.toLowerCase();
        _selectedTheme = theme.substring(0, 1).toUpperCase() + theme.substring(1);
        _loading = false;
      });
      await _applyThemePreference(_selectedTheme);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _persist() async {
    final id = await UserSession.getUserId();
    if (id == null) return;
    final payload = {
      'notification_enabled': _notificationsEnabled,
      'show_online_status': _showOnlineStatus,
      'read_receipts': _readReceipts,
      'selected_language': _selectedLanguage.toLowerCase(),
      'selected_theme': _selectedTheme.toLowerCase(),
    };
    await SettingsService.createOrUpdate(int.parse(id.toString()), payload);
  }

  String _labelForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  ThemeMode _modeFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _applyThemePreference(String label) async {
    if (!mounted) return;
    await context.read<ThemeController>().setMode(_modeFromLabel(label));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final t = AppLocalizations.of(context)!;
    final names = LocaleNames.of(context);
    final currentLocale = LocaleController.locale.value;
    final currentLocaleTag = currentLocale.countryCode == null || currentLocale.countryCode!.isEmpty
        ? currentLocale.languageCode
        : '${currentLocale.languageCode}_${currentLocale.countryCode}';
    final currentLocaleName = names?.nameOf(currentLocaleTag) ?? _selectedLanguage;

    final scheme = Theme.of(context).colorScheme;
    final appBarBg = Theme.of(context).appBarTheme.backgroundColor ?? scheme.surface;
    final onAppBar = Theme.of(context).appBarTheme.foregroundColor ?? scheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onAppBar),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.settingsTitle,
          style: TextStyle(
            color: onAppBar,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _buildSectionHeader(t.accountSection),
            _buildSettingItem(
              icon: Icons.person,
              title: t.profileSettingsTitle,
              subtitle: 'Edit your profile information',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.security,
              title: t.privacySecurityTitle,
              subtitle: 'Manage your privacy settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.block,
              title: t.blockedAccountsTitle,
              subtitle: 'Manage blocked users',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()),
                );
              },
            ),

            // Notifications Section
            _buildSectionHeader(t.notificationsSection),
            _buildSwitchItem(
              icon: Icons.notifications,
              title: t.pushNotificationsTitle,
              subtitle: 'Receive notifications on your device',
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _persist();
              },
            ),
            _buildSettingItem(
              icon: Icons.tune,
              title: t.notificationPreferencesTitle,
              subtitle: 'Customize notification types',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                );
              },
            ),

            // Privacy Section
            _buildSectionHeader(t.privacySection),
            _buildSwitchItem(
              icon: Icons.location_on,
              title: t.locationServicesTitle,
              subtitle: 'Allow location access',
              value: _locationEnabled,
              onChanged: (value) async {
                setState(() => _locationEnabled = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_kPrefLocationEnabled, value);
              },
            ),
            _buildSwitchItem(
              icon: Icons.visibility,
              title: t.showOnlineStatusTitle,
              subtitle: 'Let others see when you\'re online',
              value: _showOnlineStatus,
              onChanged: (value) async {
                setState(() => _showOnlineStatus = value);
                await _persist();
              },
            ),
            _buildSwitchItem(
              icon: Icons.done_all,
              title: t.readReceiptsTitle,
              subtitle: 'Show when you\'ve read messages',
              value: _readReceipts,
              onChanged: (value) async {
                setState(() => _readReceipts = value);
                await _persist();
              },
            ),

            // App Preferences Section
            _buildSectionHeader(t.appPreferencesSection),
            _buildSettingItem(
              icon: Icons.language,
              title: t.languageTitle,
              subtitle: currentLocaleName,
              onTap: () async {
                final selected = await Navigator.of(context).push<Locale>(
                  MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                );
                if (selected != null) {
                  final tag = selected.countryCode == null || selected.countryCode!.isEmpty
                      ? selected.languageCode
                      : '${selected.languageCode}_${selected.countryCode}';
                  final display = LocaleNames.of(context)?.nameOf(tag) ?? tag.toUpperCase();
                  setState(() => _selectedLanguage = display);
                  await _persist();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.snackbarLanguageSaved)),
                    );
                  }
                }
              },
            ),
            _buildDropdownItem(
              icon: Icons.palette,
              title: t.themeTitle,
              subtitle: _selectedTheme,
              items: ['Dark', 'Light', 'Auto'],
              selectedValue: _selectedTheme,
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _selectedTheme = value);
                await _persist();
                await _applyThemePreference(_selectedTheme);
              },
            ),
            _buildSwitchItem(
              icon: Icons.play_circle,
              title: t.autoPlayVideosTitle,
              subtitle: 'Automatically play videos in feed',
              value: _autoPlayVideos,
              onChanged: (value) async {
                setState(() { _autoPlayVideos = value; });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_kPrefAutoPlayVideos, value);
              },
            ),

            // Data & Storage Section
            _buildSectionHeader(t.dataStorageSection),
            _buildSettingItem(
              icon: Icons.storage,
              title: t.storageUsageTitle,
              subtitle: 'Manage app storage',
              onTap: () {
                _showStorageInfo();
              },
            ),
            _buildSettingItem(
              icon: Icons.download,
              title: t.downloadPreferencesTitle,
              subtitle: 'Media download settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DownloadPreferencesScreen()),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.delete_sweep,
              title: t.clearCacheTitle,
              subtitle: 'Free up storage space',
              onTap: () {
                _showClearCacheDialog();
              },
            ),

            // Reset settings to defaults
            _buildSettingItem(
              icon: Icons.restore,
              title: t.resetSettingsTitle,
              subtitle: 'Restore defaults for this account',
              onTap: _confirmReset,
            ),

            // Support Section
            _buildSectionHeader(t.supportSection),
            _buildSettingItem(
              icon: Icons.help,
              title: t.helpCenterTitle,
              subtitle: 'Get help and support',
              onTap: () {
                // Navigate to help center
              },
            ),
            _buildSettingItem(
              icon: Icons.feedback,
              title: t.sendFeedbackTitle,
              subtitle: 'Share your thoughts with us',
              onTap: () {
                _showFeedbackDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.star_rate,
              title: t.rateAppTitle,
              subtitle: 'Rate us on the app store',
              onTap: () {
                // Open app store rating
              },
            ),

            // About Section
            _buildSectionHeader(t.aboutSection),
            _buildSettingItem(
              icon: Icons.info,
              title: t.aboutAppTitle,
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.description,
              title: t.termsTitle,
              subtitle: 'Read our terms and conditions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.shield,
              title: t.privacyPolicyTitle,
              subtitle: 'Read our privacy policy',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
        inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return InkWell(
      onTap: () => _showDropdownMenu(title, items, selectedValue, onChanged),
      child: _buildSettingItem(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => _showDropdownMenu(title, items, selectedValue, onChanged),
      ),
    );
  }

  void _showDropdownMenu(
    String title,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select $title',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ...items.map(
                (item) => ListTile(
                  title: Text(item, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: selectedValue == item
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    onChanged(item);
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacySettings() {
    // Implementation for privacy settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Privacy settings opened'),
      ),
    );
  }

  void _showNotificationPreferences() {
    // Implementation for notification preferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification preferences opened'),
      ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.storageUsageTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStorageItem('Photos', '245 MB', 0.6),
            _buildStorageItem('Videos', '1.2 GB', 0.8),
            _buildStorageItem('Cache', '89 MB', 0.3),
            _buildStorageItem('Other', '45 MB', 0.2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonClose, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String type, String size, double progress) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(type, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          SizedBox(width: 8),
          Text(size, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  void _showDownloadSettings() {
    // Implementation for download settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download settings opened'),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  Future<void> _confirmReset() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogResetTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          AppLocalizations.of(context)!.resetSettingsDescription,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllSettings();
            },
            child: Text(AppLocalizations.of(context)!.commonReset, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    final id = await UserSession.getUserId();
    if (id == null) return;
    try {
      await SettingsService.reset(int.parse(id.toString()));

      // Reset local prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefLocationEnabled);
      await prefs.remove(_kPrefAutoPlayVideos);
      // Notification prefs (if present)
      await prefs.remove('notif_messages');
      await prefs.remove('notif_comments');
      await prefs.remove('notif_mentions');
      await prefs.remove('notif_marketing');
      // Download prefs (if present)
      await prefs.remove('dl_wifi_only');
      await prefs.remove('dl_auto_photos');
      await prefs.remove('dl_auto_videos');

      // Reset local toggles to defaults
      setState(() {
        _locationEnabled = true;
        _autoPlayVideos = false;
        _notificationsEnabled = true;
        _showOnlineStatus = true;
        _readReceipts = true;
        _selectedLanguage = 'English';
        _selectedTheme = 'Light';
      });

      // Reload server settings and apply theme
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.snackbarSettingsReset)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset: $e')),
        );
      }
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogClearCacheTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          AppLocalizations.of(context)!.dialogClearCacheDescription,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.snackbarCacheCleared),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.commonClear, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sendFeedbackTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: feedbackController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.snackbarFeedbackSent),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.commonSend, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.aboutAppTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.dialogAboutBuild}: 100', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 16),
            Text(
              'Connect with people around you and discover new experiences.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonClose, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
