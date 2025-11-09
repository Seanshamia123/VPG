// subscription_status_widget.dart - Display subscription on profile
import 'package:flutter/material.dart';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';
import 'package:intl/intl.dart';

class SubscriptionStatusWidget extends StatefulWidget {
  const SubscriptionStatusWidget({Key? key}) : super(key: key);

  @override
  State<SubscriptionStatusWidget> createState() =>
      _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  Map<String, dynamic>? _subscription;
  bool _isLoading = true;
  bool _hasSubscription = false;
  String? _errorMessage;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color brightGold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.getJson(
        '${ApiConfig.api}/payment/subscription-status',
        auth: true,
      );

      print('=== SUBSCRIPTION STATUS RESPONSE ===');
      print(response);

      if (response['has_subscription'] == true) {
        setState(() {
          _hasSubscription = true;
          _subscription = response['subscription'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasSubscription = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription: $e');
      setState(() {
        _errorMessage = 'Failed to load subscription status';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Cancel Subscription?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel your subscription?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'You will continue to have access until ${_formatDate(_subscription?['end_date'])}',
            ),
            const SizedBox(height: 10),
            const Text(
              'After that, your account will revert to free features.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelSubscription();
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      final subscriptionId = _subscription?['id'];
      if (subscriptionId == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await ApiClient.postJson(
        '${ApiConfig.api}/payment/cancel-subscription/$subscriptionId',
        {},
        auth: true,
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload subscription status
        await _loadSubscriptionStatus();
      } else {
        throw Exception(response['error'] ?? 'Failed to cancel');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(String? amount, String? currency) {
    if (amount == null) return 'N/A';
    try {
      final value = double.parse(amount);
      return '${currency ?? 'KES'} ${value.toStringAsFixed(2)}';
    } catch (e) {
      return amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(goldColor),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadSubscriptionStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_hasSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [goldColor.withOpacity(0.1), brightGold.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: goldColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.card_membership,
              color: goldColor,
              size: 50,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Subscribe to unlock premium features and boost your visibility',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription-plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Active subscription display
    final status = _subscription?['status'] ?? 'unknown';
    final isCancelled = status == 'cancelled';
    final daysRemaining = _subscription?['days_remaining'] ?? 0;
    final daysUntilRenewal = _subscription?['days_until_renewal'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCancelled
              ? [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)]
              : [goldColor.withOpacity(0.1), brightGold.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? Colors.grey.withOpacity(0.3)
              : goldColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.grey.withOpacity(0.2)
                      : goldColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled ? Icons.cancel : Icons.workspace_premium,
                  color: isCancelled ? Colors.grey : goldColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subscription?['plan_name'] ?? 'Premium Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? Colors.grey : goldColor,
                      ),
                    ),
                    Text(
                      isCancelled ? 'Cancelled' : 'Active',
                      style: TextStyle(
                        color: isCancelled ? Colors.grey : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCancelled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Subscription details
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Started',
            value: _formatDate(_subscription?['start_date']),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.event,
            label: 'Expires',
            value: _formatDate(_subscription?['end_date']),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Amount',
            value: _formatCurrency(
              _subscription?['amount_paid'],
              _subscription?['currency'],
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.payment,
            label: 'Payment Method',
            value: _subscription?['payment_method'] ?? 'N/A',
          ),

          // Days remaining badge
          if (!isCancelled && daysRemaining != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: daysRemaining <= 7
                    ? Colors.red.withOpacity(0.1)
                    : goldColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: daysRemaining <= 7
                      ? Colors.red.withOpacity(0.3)
                      : goldColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: daysRemaining <= 7 ? Colors.red : goldColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$daysRemaining days remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: daysRemaining <= 7 ? Colors.red : goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Renewal info
          if (!isCancelled &&
              daysUntilRenewal != null &&
              _subscription?['auto_renew'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.autorenew, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Auto-renews in $daysUntilRenewal days on ${_formatDate(_subscription?['next_billing_date'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 20),
          Row(
            children: [
              if (!isCancelled) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCancelDialog,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/subscription-plans');
                  },
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: Text(isCancelled ? 'Resubscribe' : 'Upgrade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}