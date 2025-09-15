import 'package:escort/features/advertisers/presentation/screens/checkout.dart';
import 'package:escort/services/subscription_service.dart';
import 'package:flutter/material.dart';

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog({super.key});

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  Map<String, dynamic>? _active;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sub = await SubscriptionService.activeSubscription();
      if (!mounted) return;
      setState(() => _active = sub);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Color palette - Black & Bright Gold
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryGold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: lightGray,
  );

  static const TextStyle bodyStyle = TextStyle(fontSize: 14, color: white);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCharcoal, pureBlack],
          ),
          border: Border.all(color: primaryGold.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: primaryGold.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading) ...[
                      const SizedBox(height: 80),
                      const Center(child: CircularProgressIndicator(color: primaryGold)),
                      const SizedBox(height: 24),
                      Text('Loading subscription...', style: subtitleStyle),
                    ] else if (_active != null) ...[
                      Text('Your Subscription', style: titleStyle),
                      SizedBox(height: 16),
                      Text('You are on the Starter plan', style: subtitleStyle),
                      SizedBox(height: 24),
                      _buildActiveCard(context),
                    ] else ...[
                      Text('Choose Your Plan', style: titleStyle),
                      SizedBox(height: 16),
                      Text('Select the perfect subscription for your needs', style: subtitleStyle),
                      SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildStarterCard(context)),
                                SizedBox(width: 32),
                                Expanded(child: _buildProfessionalCard(context)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildStarterCard(context),
                                SizedBox(height: 32),
                                _buildProfessionalCard(context),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: 24),
                      Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.security, color: primaryGold, size: 20),
                              SizedBox(width: 8),
                              Text('Secure payments', style: bodyStyle),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.support_agent, color: primaryGold, size: 20),
                              SizedBox(width: 8),
                              Text('24/7 support', style: bodyStyle),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: primaryGold),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: darkGray,
        border: Border.all(color: primaryGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryGold.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$20',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryGold,
                  ),
                ),
                Text(
                  '/month',
                  style: TextStyle(fontSize: 14, color: lightGray),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Perfect for individuals getting started',
              style: TextStyle(fontSize: 14, color: lightGray),
            ),
            SizedBox(height: 24),
            ..._buildFeatures([
              'Up to 5 projects',
              '10GB storage',
              'Email support',
              'Basic analytics',
              'Mobile app access',
            ]),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _working
                    ? null
                    : () async {
                        setState(() => _working = true);
                        try {
                          final res = await SubscriptionService.subscribeBasic(amount: 20.0, method: 'card');
                          if (!mounted) return;
                          setState(() => _active = res);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription activated')));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to subscribe: $e')));
                        } finally {
                          if (mounted) setState(() => _working = false);
                        }
                      },
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: pureBlack,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return darkGold;
                          }
                          if (states.contains(MaterialState.hovered)) {
                            return accentGold;
                          }
                          return primaryGold;
                        },
                      ),
                    ),
                child: _working
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: pureBlack),
                          ),
                          SizedBox(width: 10),
                          Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: pureBlack)),
                        ],
                      )
                    : Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: pureBlack,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context) {
    final start = (_active?['start_date'] ?? '').toString();
    final end = (_active?['end_date'] ?? '').toString();
    final method = (_active?['payment_method'] ?? 'card').toString();
    final status = (_active?['status'] ?? 'active').toString();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: darkGray,
        border: Border.all(color: primaryGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: primaryGold),
                const SizedBox(width: 8),
                const Text('Starter • \$20/month', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(), style: const TextStyle(color: primaryGold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Payment: $method', style: bodyStyle),
            const SizedBox(height: 6),
            Text('Start: $start', style: bodyStyle),
            const SizedBox(height: 6),
            Text('Renews: $end', style: bodyStyle),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () async {
                        final id = int.tryParse((_active?['id'] ?? '').toString());
                        if (id == null) return;
                        setState(() => _working = true);
                        try {
                          await SubscriptionService.cancel(id);
                          if (!mounted) return;
                          setState(() => _active = null);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
                        } finally {
                          if (mounted) setState(() => _working = false);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold,
                  side: const BorderSide(color: primaryGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryGold),
                      )
                    : const Icon(Icons.cancel),
                label: Text(_working ? 'Cancelling...' : 'Cancel Subscription'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: darkCharcoal,
        border: Border.all(color: accentGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentGold.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: pureBlack,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Professional',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$40',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryGold,
                      ),
                    ),
                    Text(
                      '/month',
                      style: TextStyle(fontSize: 14, color: lightGray),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Ideal for growing businesses and teams',
                  style: TextStyle(fontSize: 14, color: lightGray),
                ),
                SizedBox(height: 24),
                ..._buildFeatures([
                  'Unlimited projects',
                  '100GB storage',
                  'Priority support',
                  'Advanced analytics',
                  'Team collaboration',
                  'API access',
                  'Custom integrations',
                ]),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => CheckoutPage()),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: primaryGold,
                          foregroundColor: pureBlack,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.pressed)) {
                                  return darkGold;
                                }
                                if (states.contains(MaterialState.hovered)) {
                                  return accentGold;
                                }
                                return primaryGold;
                              }),
                        ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: pureBlack,
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

  List<Widget> _buildFeatures(List<String> features) {
    return features
        .map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: primaryGold, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(fontSize: 14, color: white),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
