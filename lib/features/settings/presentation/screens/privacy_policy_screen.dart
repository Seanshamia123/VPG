/// Feature: Settings
/// Screen: PrivacyPolicyScreen
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Last Updated: January 1, 2025',
              style: TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application.\n\n'
              'Information We Collect:\n• Account details you provide\n• Usage and log information\n• Device and diagnostic data\n\n'
              'How We Use Information:\n• Provide and improve the service\n• Personalize content and features\n• Communicate with you about updates\n\n'
              'Your Choices:\n• You can manage notifications and privacy options in Settings\n• You may request account deletion and data export\n\n'
              'Contact Us: If you have questions, please reach out via in-app support.',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
