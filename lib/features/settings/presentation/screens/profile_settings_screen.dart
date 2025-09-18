import 'package:escort/services/user_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await UserSession.getUserId();
    if (id != null) {
      final data = await UserService.getProfile(int.parse(id.toString()));
      if (data != null) {
        _nameCtrl.text = data['name']?.toString() ?? '';
        _phoneCtrl.text = data['phone_number']?.toString() ?? '';
        _locationCtrl.text = data['location']?.toString() ?? '';
      }
    }
    setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = await UserSession.getUserId();
    if (id == null) return;
    final res = await UserService.updateProfile(
      int.parse(id.toString()),
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
    );
    if ((res['statusCode'] ?? 500) >= 400) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
      return;
    }
    // Update local session cache for immediate reflect
    await UserSession.updateUserData({
      'name': _nameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
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
        title: const Text('Profile Settings', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.yellow)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field('Full name', _nameCtrl),
              const SizedBox(height: 12),
              _field('Phone number', _phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Location', _locationCtrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
      ),
      validator: (v) {
        if (label == 'Phone number' && v != null && v.isNotEmpty && v.length < 7) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }
}
/// Feature: Settings
/// Screen: ProfileSettingsScreen
