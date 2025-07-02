import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = true;
  bool _autoPlayVideos = false;
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingItem(
              icon: Icons.person,
              title: 'Profile Settings',
              subtitle: 'Edit your profile information',
              onTap: () {
                // Navigate to profile settings
              },
            ),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () {
                _showPrivacySettings();
              },
            ),
            _buildSettingItem(
              icon: Icons.block,
              title: 'Blocked Accounts',
              subtitle: 'Manage blocked users',
              onTap: () {
                // Navigate to blocked accounts
              },
            ),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchItem(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            _buildSettingItem(
              icon: Icons.tune,
              title: 'Notification Preferences',
              subtitle: 'Customize notification types',
              onTap: () {
                _showNotificationPreferences();
              },
            ),

            // Privacy Section
            _buildSectionHeader('Privacy'),
            _buildSwitchItem(
              icon: Icons.location_on,
              title: 'Location Services',
              subtitle: 'Allow location access',
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
              },
            ),
            _buildSwitchItem(
              icon: Icons.visibility,
              title: 'Show Online Status',
              subtitle: 'Let others see when you\'re online',
              value: _showOnlineStatus,
              onChanged: (value) {
                setState(() {
                  _showOnlineStatus = value;
                });
              },
            ),
            _buildSwitchItem(
              icon: Icons.done_all,
              title: 'Read Receipts',
              subtitle: 'Show when you\'ve read messages',
              value: _readReceipts,
              onChanged: (value) {
                setState(() {
                  _readReceipts = value;
                });
              },
            ),

            // App Preferences Section
            _buildSectionHeader('App Preferences'),
            _buildDropdownItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: _selectedLanguage,
              items: ['English', 'Spanish', 'French', 'German', 'Italian'],
              selectedValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            _buildDropdownItem(
              icon: Icons.palette,
              title: 'Theme',
              subtitle: _selectedTheme,
              items: ['Dark', 'Light', 'Auto'],
              selectedValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
              },
            ),
            _buildSwitchItem(
              icon: Icons.play_circle,
              title: 'Auto-play Videos',
              subtitle: 'Automatically play videos in feed',
              value: _autoPlayVideos,
              onChanged: (value) {
                setState(() {
                  _autoPlayVideos = value;
                });
              },
            ),

            // Data & Storage Section
            _buildSectionHeader('Data & Storage'),
            _buildSettingItem(
              icon: Icons.storage,
              title: 'Storage Usage',
              subtitle: 'Manage app storage',
              onTap: () {
                _showStorageInfo();
              },
            ),
            _buildSettingItem(
              icon: Icons.download,
              title: 'Download Preferences',
              subtitle: 'Media download settings',
              onTap: () {
                _showDownloadSettings();
              },
            ),
            _buildSettingItem(
              icon: Icons.delete_sweep,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () {
                _showClearCacheDialog();
              },
            ),

            // Support Section
            _buildSectionHeader('Support'),
            _buildSettingItem(
              icon: Icons.help,
              title: 'Help Center',
              subtitle: 'Get help and support',
              onTap: () {
                // Navigate to help center
              },
            ),
            _buildSettingItem(
              icon: Icons.feedback,
              title: 'Send Feedback',
              subtitle: 'Share your thoughts with us',
              onTap: () {
                _showFeedbackDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.star_rate,
              title: 'Rate App',
              subtitle: 'Rate us on the app store',
              onTap: () {
                // Open app store rating
              },
            ),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingItem(
              icon: Icons.info,
              title: 'About Escort',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.description,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                // Navigate to terms
              },
            ),
            _buildSettingItem(
              icon: Icons.shield,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                // Navigate to privacy policy
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
          color: Colors.yellow,
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
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
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
        activeColor: Colors.yellow,
        activeTrackColor: Colors.yellow.withOpacity(0.3),
        inactiveThumbColor: Colors.grey[400],
        inactiveTrackColor: Colors.grey[700],
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

  void _showDropdownMenu(String title, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ...items.map((item) => ListTile(
                title: Text(
                  item,
                  style: TextStyle(color: Colors.white),
                ),
                trailing: selectedValue == item
                    ? Icon(Icons.check, color: Colors.yellow)
                    : null,
                onTap: () {
                  onChanged(item);
                  Navigator.pop(context);
                },
              )),
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
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  void _showNotificationPreferences() {
    // Implementation for notification preferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification preferences opened'),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Storage Usage',
          style: TextStyle(color: Colors.white),
        ),
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
            child: Text(
              'Close',
              style: TextStyle(color: Colors.yellow),
            ),
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
            child: Text(
              type,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
          ),
          SizedBox(width: 8),
          Text(
            size,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will clear all cached data and free up storage space. Continue?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.yellow),
            ),
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
        backgroundColor: Colors.grey[900],
        title: Text(
          'Send Feedback',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: feedbackController,
          style: TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.yellow),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feedback sent successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Send',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.yellow),
            SizedBox(width: 8),
            Text(
              'About Escort',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 8),
            Text(
              'Build: 100',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            Text(
              'Connect with people around you and discover new experiences.',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}