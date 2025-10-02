// subscription_plans_page.dart - Plan selection page
import 'package:flutter/material.dart';
import 'subscription_checkout.dart'; // Import your checkout page

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double priceKes;
  final double priceUsd;
  final double priceEur;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final Color accentColor;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceKes,
    required this.priceUsd,
    required this.priceEur,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
    this.accentColor = const Color(0xFFFFD700),
  });

  double getPriceForCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'KES': return priceKes;
      case 'USD': return priceUsd;
      case 'EUR': return priceEur;
      default: return priceKes;
    }
  }

  String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'KES': return 'KSh';
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return 'KSh';
    }
  }
}

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  // Color Scheme
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic Plan',
      description: 'Perfect for getting started',
      priceKes: 10,
      priceUsd: 15,
      priceEur: 13,
      durationDays: 30,
      features: [
        'Up to 10 posts per month',
        'Basic profile visibility',
        'Standard support',
        'Mobile app access',
        'Basic analytics',
      ],
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium Plan',
      description: 'Most popular choice for professionals',
      priceKes: 3500,
      priceUsd: 35,
      priceEur: 30,
      durationDays: 30,
      features: [
        'Unlimited posts',
        'Priority profile placement',
        'Verified badge',
        'Priority support',
        'Advanced analytics',
        'Featured in search results',
        'Premium visibility boost',
        'Direct messaging features',
      ],
      isPopular: true,
      accentColor: accentGold,
    ),
  ];

  String _selectedCurrency = 'KES';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: primaryGold),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkCharcoal, pureBlack],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the perfect plan for your needs',
                      style: TextStyle(
                        color: lightGray,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Currency Selector
              _buildCurrencySelector(),
              const SizedBox(height: 24),

              // Plans
              ..._plans.map((plan) => _buildPlanCard(plan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final currencies = ['KES', 'USD', 'EUR'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Currency',
            style: TextStyle(
              color: primaryGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: currencies.map((currency) {
              final isSelected = _selectedCurrency == currency;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCurrency = currency),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: currency != currencies.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? primaryGold 
                            : lightGray.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      currency,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? pureBlack : white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final price = plan.getPriceForCurrency(_selectedCurrency);
    final symbol = plan.getCurrencySymbol(_selectedCurrency);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: darkGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plan.isPopular 
                ? plan.accentColor 
                : lightGray.withOpacity(0.3),
            width: plan.isPopular ? 2 : 1,
          ),
          boxShadow: plan.isPopular ? [
            BoxShadow(
              color: plan.accentColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      color: plan.isPopular ? plan.accentColor : white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: pureBlack,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: const TextStyle(
                color: lightGray,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$symbol${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: plan.isPopular ? plan.accentColor : white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/${plan.durationDays} days',
                  style: const TextStyle(
                    color: lightGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Features
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: plan.isPopular ? plan.accentColor : primaryGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: lightGray,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),

            // Get Started Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToCheckout(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.isPopular ? plan.accentColor : primaryGold,
                  foregroundColor: pureBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Get Started - $symbol${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckout(SubscriptionPlan selectedPlan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionCheckoutPage(
          selectedPlan: selectedPlan,
          selectedCurrency: _selectedCurrency,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Payment successful - navigate back to profile or show success
        Navigator.pop(context, true);
      }
    });
  }
}