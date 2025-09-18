/// Feature: Settings
/// Screen: TermsAndConditionsScreen
import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  _TermsAndConditionsScreenState createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share functionality would be implemented here'),
                  backgroundColor: Colors.grey[800],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with last updated info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: January 1, 2025',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please read these terms carefully before using VipGalz.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Acceptance of Terms',
                    'By accessing and using the VipGalz mobile application ("App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.\n\nThese Terms of Service ("Terms") govern your use of our mobile application operated by VipGalz ("us", "we", or "our").',
                  ),

                  _buildSection(
                    '2. Description of Service',
                    'VipGalz is a social networking platform that allows users to connect, share content, and communicate with others. The service includes but is not limited to:\n\n• Profile creation and management\n• Content sharing (photos, videos, text)\n• Messaging and communication features\n• Location-based services\n• Advertising platform\n\nWe reserve the right to modify, suspend, or discontinue the service at any time without notice.',
                  ),

                  _buildSection(
                    '3. User Accounts and Registration',
                    'To access certain features of the App, you must register for an account. When you register for an account, you may be required to provide us with some information about yourself.\n\nYou are responsible for:\n• Maintaining the confidentiality of your account credentials\n• All activities that occur under your account\n• Ensuring the accuracy of information provided\n• Notifying us immediately of any unauthorized use\n\nYou must be at least 18 years old to create an account.',
                  ),

                  _buildSection(
                    '4. Acceptable Use Policy',
                    'You agree not to use the service to:\n\n• Violate any laws or regulations\n• Infringe on intellectual property rights\n• Harass, abuse, or harm others\n• Post false, misleading, or deceptive content\n• Spam or send unsolicited communications\n• Upload malicious code or viruses\n• Attempt to gain unauthorized access\n• Impersonate others or create fake accounts\n• Engage in commercial activities without permission\n\nViolation of these policies may result in account suspension or termination.',
                  ),

                  _buildSection(
                    '5. Content and Intellectual Property',
                    'User Content:\nYou retain ownership of content you post on VipGalz. However, by posting content, you grant us a non-exclusive, worldwide, royalty-free license to use, modify, publicly perform, publicly display, reproduce, and distribute such content.\n\nOur Content:\nThe App and its original content, features, and functionality are owned by VipGalz and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.\n\nCopyright Policy:\nWe respect intellectual property rights and expect users to do the same. We will respond to clear notices of alleged copyright infringement.',
                  ),

                  _buildSection(
                    '6. Privacy and Data Protection',
                    'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service.\n\nKey points:\n• We collect information you provide and usage data\n• We use data to provide and improve our services\n• We may share data with third parties as described in our Privacy Policy\n• You can control many privacy settings in your account\n• We implement security measures to protect your data\n\nBy using our service, you consent to the collection and use of information in accordance with our Privacy Policy.',
                  ),

                  _buildSection(
                    '7. Location Services',
                    'Our App may use location services to provide location-based features. You can control location permissions through your device settings.\n\nLocation data may be used to:\n• Show nearby users and content\n• Provide location-based advertising\n• Improve our services\n• Comply with legal requirements\n\nYou can disable location services at any time, though this may limit certain features.',
                  ),

                  _buildSection(
                    '8. Advertising and Commercial Use',
                    'VipGalz may display advertisements and promotional content. We may use your information to show you relevant ads.\n\nCommercial Use:\n• Business accounts may be subject to additional terms\n• Advertising content must comply with our guidelines\n• We reserve the right to reject or remove any advertising content\n• Fees may apply for certain commercial features',
                  ),

                  _buildSection(
                    '9. Termination',
                    'We may terminate or suspend your account and access to the service immediately, without prior notice, for any reason, including breach of these Terms.\n\nYou may also terminate your account at any time by:\n• Using the account deletion feature in settings\n• Contacting our support team\n\nUpon termination:\n• Your right to access the service ceases immediately\n• We may delete your account and data\n• Certain provisions of these Terms survive termination',
                  ),

                  _buildSection(
                    '10. Disclaimers and Limitation of Liability',
                    'DISCLAIMER:\nThe service is provided "as is" without warranties of any kind. We disclaim all warranties, whether express or implied, including merchantability, fitness for a particular purpose, and non-infringement.\n\nLIMITATION OF LIABILITY:\nIn no event shall VipGalzscort be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or use, incurred by you or any third party.\n\nOur total liability shall not exceed the amount paid by you for the service in the 12 months preceding the claim.',
                  ),

                  _buildSection(
                    '11. Indemnification',
                    'You agree to defend, indemnify, and hold harmless VipGalz and its officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses arising out of or in any way connected with:\n\n• Your use of the service\n• Your violation of these Terms\n• Your violation of any rights of another party\n• Your content posted on the service',
                  ),

                  _buildSection(
                    '12. Governing Law and Dispute Resolution',
                    'These Terms shall be governed by and construed in accordance with the laws of [Jurisdiction], without regard to its conflict of law provisions.\n\nDispute Resolution:\n• We encourage users to contact us first to resolve disputes\n• If informal resolution fails, disputes will be resolved through binding arbitration\n• Class action lawsuits are waived\n• You may opt out of arbitration within 30 days of account creation',
                  ),

                  _buildSection(
                    '13. Changes to Terms',
                    'We reserve the right to modify these Terms at any time. We will notify users of significant changes through:\n\n• In-app notifications\n• Email notifications\n• Updates to this page\n\nContinued use of the service after changes constitutes acceptance of the new Terms. If you disagree with changes, you should discontinue use of the service.',
                  ),

                  _buildSection(
                    '14. Contact Information',
                    'If you have any questions about these Terms and Conditions, please contact us:\n\nEmail: legal@vipgalz.app\nAddress: [Company Address]\nPhone: [Phone Number]\n\nSupport: support@vipgalz.app\nBusiness Inquiries: business@vipgalz.app',
                  ),

                  SizedBox(height: 40),

                  // Acknowledgment section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.yellow,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'By using VipGalz, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                          textAlign: TextAlign.center,
                          
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[600]!),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasScrolledToBottom ? () {
                      // Show acceptance confirmation
                      _showAcceptanceDialog();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasScrolledToBottom ? Colors.yellow : Colors.grey[700],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _hasScrolledToBottom ? 'I Agree' : 'Scroll to Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            height: 1.6,
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  void _showAcceptanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              'Terms Accepted',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Thank you for reading and accepting our Terms and Conditions. You can now enjoy all features of VipGalz.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
