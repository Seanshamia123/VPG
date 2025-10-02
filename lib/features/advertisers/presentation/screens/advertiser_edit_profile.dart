/// Feature: Advertisers
/// Screen: AdvertiserEditProfileScreen
import 'dart:convert';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdvertiserEditProfileScreen extends StatefulWidget {
  const AdvertiserEditProfileScreen({super.key});

  @override
  State<AdvertiserEditProfileScreen> createState() => _AdvertiserEditProfileScreenState();
}

class _AdvertiserEditProfileScreenState extends State<AdvertiserEditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  bool _saving = false;
  bool _isOnline = false;
  int? _advertiserId;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await UserSession.getCurrentUserData();
    setState(() {
      _advertiserId = data?['id'] as int?;
      _nameController.text = (data?['name'] ?? data?['username'] ?? '').toString();
      _phoneController.text = (data?['phone_number'] ?? '').toString();
      _locationController.text = (data?['location'] ?? '').toString();
      _bioController.text = (data?['bio'] ?? '').toString();
      _isOnline = (data?['is_online'] ?? false) == true;
      _avatarUrl = (data?['profile_image_url'] ?? '').toString();
    });
  }

  Future<void> _pickAvatarFrom(ImageSource source) async {
    try {
      final img = await _picker.pickImage(source: source, maxWidth: 1024);
      if (img == null) return;
      final bytes = await img.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _saving = true);
      final uploaded = await AdvertiserService.uploadAvatarBase64(base64Str, folder: 'vpg/advertisers/avatars');
      if (!mounted) return;
      if (uploaded != null) {
        setState(() => _avatarUrl = uploaded);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _promptAvatarSource() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarFrom(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_advertiserId == null) return;
    setState(() => _saving = true);
    try {
      final res = await AdvertiserService.updateProfile(
        _advertiserId!,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        profileImageUrl: (_avatarUrl ?? '').isEmpty ? null : _avatarUrl,
        isOnline: _isOnline,
      );

      // The API client wraps responses as Map; it may contain advertiser fields directly or under 'data'
      final updated = res['advertiser'] ?? res['data'] ?? res;

      // Update session cache
      final existing = await UserSession.getCurrentUserData() ?? {};
      final merged = {...existing, ...Map<String, dynamic>.from(updated)};
      await UserSession.saveUserSession(
        userData: merged,
        accessToken: (await UserSession.getAccessToken()) ?? '',
        refreshToken: null,
        userType: (await UserSession.getUserType()) ?? 'advertiser',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      Navigator.of(context).pop(merged);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final surface = scheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor ?? onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleMedium?.copyWith(
                color: theme.appBarTheme.foregroundColor ?? onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: theme.appBarTheme.foregroundColor ?? onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      backgroundColor: scheme.surfaceVariant,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? Icon(Icons.person, color: onSurfaceVariant, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _promptAvatarSource,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt, color: scheme.onPrimary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField(controller: _nameController, label: 'Name', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildField(controller: _bioController, label: 'Bio', icon: Icons.info_outline, maxLines: 3),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v),
                title: Text(
                  'Online status',
                  style: textTheme.bodyMedium?.copyWith(color: onSurface) ??
                      TextStyle(color: onSurface),
                ),
                activeColor: scheme.primary,
              ),
              if (_saving) const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface) ??
          TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant) ??
            TextStyle(color: scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: scheme.primary),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}
