// integrated_subscription_flow.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

// Mock Payment Gateway for Testing
class MockPaymentGateway {
  static Future<Map<String, dynamic>> createCheckoutSession({
    required String planId,
    required double amount,
    required String currency,
    String? phoneNumber,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));
    
    return {
      'success': true,
      'checkout_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'checkout_url': 'https://mock-payment-gateway.com/checkout/session_123',
      'amount': amount,
      'currency': currency,
      'status': 'pending'
    };
  }

  static Future<Map<String, dynamic>> simulatePayment(String checkoutId) async {
    // Simulate payment processing
    await Future.delayed(Duration(seconds: 3));
    
    // 90% success rate for testing
    final success = DateTime.now().millisecond % 10 != 0;
    
    return {
      'success': success,
      'status': success ? 'completed' : 'failed',
      'checkout_id': checkoutId,
      'message': success ? 'Payment successful' : 'Payment failed - insufficient funds',
      'transaction_id': success ? 'txn_${DateTime.now().millisecondsSinceEpoch}' : null,
    };
  }
}

// Enhanced Subscription Plan Model
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

// Main Integrated Subscription Page
class IntegratedSubscriptionPage extends StatefulWidget {
  const IntegratedSubscriptionPage({Key? key}) : super(key: key);

  @override
  State<IntegratedSubscriptionPage> createState() => _IntegratedSubscriptionPageState();
}

class _IntegratedSubscriptionPageState extends State<IntegratedSubscriptionPage>
    with TickerProviderStateMixin {
  
  // UI States
  int _currentStep = 0;
  bool _isLoading = false;
  String? _selectedCurrency = 'KES';
  SubscriptionPlan? _selectedPlan;
  String? _checkoutId;
  String? _paymentStatus;
  
  // Controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Scheme
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);

  // Mock Data
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'starter',
      name: 'Starter',
      description: 'Perfect for individuals getting started',
      priceKes: 2000,
      priceUsd: 20,
      priceEur: 18,
      durationDays: 30,
      features: [
        'Up to 5 posts per day',
        '10GB storage',
        'Email support',
        'Basic analytics',
        'Mobile app access',
      ],
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'professional',
      name: 'Professional',
      description: 'Ideal for growing businesses and teams',
      priceKes: 4000,
      priceUsd: 40,
      priceEur: 36,
      durationDays: 30,
      features: [
        'Unlimited posts',
        '100GB storage',
        'Priority support',
        'Advanced analytics',
        'Team collaboration',
        'API access',
        'Custom integrations',
        'Verified badge',
      ],
      isPopular: true,
      accentColor: accentGold,
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Enterprise',
      description: 'For large organizations with advanced needs',
      priceKes: 8000,
      priceUsd: 80,
      priceEur: 72,
      durationDays: 30,
      features: [
        'Everything in Professional',
        'Unlimited storage',
        'Dedicated support manager',
        'Custom branding',
        'White-label solution',
        'SLA guarantee',
        'Advanced security',
        'Multi-region deployment',
      ],
      isPopular: false,
      accentColor: Colors.purple,
    ),
  ];

  final List<String> _currencies = ['KES', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Set default popular plan
    _selectedPlan = _plans.firstWhere((plan) => plan.isPopular);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Navigation Methods
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Payment Processing
  Future<void> _processPayment() async {
    if (_selectedPlan == null) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Create checkout session
      final checkoutResult = await MockPaymentGateway.createCheckoutSession(
        planId: _selectedPlan!.id,
        amount: _selectedPlan!.getPriceForCurrency(_selectedCurrency!),
        currency: _selectedCurrency!,
        phoneNumber: _phoneController.text.trim(),
      );

      _checkoutId = checkoutResult['checkout_id'];
      _nextStep(); // Move to payment processing screen

      // Step 2: Simulate payment processing
      await Future.delayed(Duration(seconds: 1));
      final paymentResult = await MockPaymentGateway.simulatePayment(_checkoutId!);

      setState(() {
        _paymentStatus = paymentResult['status'];
        _isLoading = false;
      });

      _nextStep(); // Move to result screen

      if (paymentResult['success']) {
        _showSuccessMessage('Subscription activated successfully!');
      } else {
        _showErrorMessage(paymentResult['message'] ?? 'Payment failed');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'error';
      });
      _showErrorMessage('Payment processing error: $e');
      _nextStep(); // Move to error screen
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        title: Text(
          'Subscription Flow',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: primaryGold),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkCharcoal, pureBlack],
          ),
        ),
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildPlanSelectionPage(),
                  _buildPaymentDetailsPage(),
                  _buildProcessingPage(),
                  _buildResultPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? successGreen : 
                           isActive ? primaryGold : darkGray,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: isCompleted || isActive ? pureBlack : lightGray,
                    size: 16,
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? successGreen : darkGray,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlanSelectionPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: TextStyle(
                color: primaryGold,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select the perfect subscription for your needs',
              style: TextStyle(color: lightGray, fontSize: 16),
            ),
            SizedBox(height: 24),
            
            // Currency Selector
            _buildCurrencySelector(),
            SizedBox(height: 24),
            
            // Plans
            ..._plans.map((plan) => _buildPlanCard(plan)),
            
            SizedBox(height: 24),
            _buildNavigationButton(
              text: 'Continue',
              onPressed: _selectedPlan != null ? _nextStep : null,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency',
            style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: _currencies.map((currency) {
              final isSelected = _selectedCurrency == currency;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCurrency = currency),
                  child: Container(
                    margin: EdgeInsets.only(right: currency != _currencies.last ? 8 : 0),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? primaryGold : lightGray.withOpacity(0.3),
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
    final isSelected = _selectedPlan?.id == plan.id;
    final price = plan.getPriceForCurrency(_selectedCurrency!);
    final symbol = plan.getCurrencySymbol(_selectedCurrency!);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? plan.accentColor.withOpacity(0.1) : darkGray,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? plan.accentColor : lightGray.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: plan.accentColor.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        color: isSelected ? plan.accentColor : white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
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
              SizedBox(height: 8),
              Text(
                plan.description,
                style: TextStyle(color: lightGray, fontSize: 14),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$symbol${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? plan.accentColor : white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${plan.durationDays} days',
                    style: TextStyle(color: lightGray, fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...plan.features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isSelected ? plan.accentColor : primaryGold,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(color: lightGray, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              color: primaryGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          // Selected Plan Summary
          if (_selectedPlan != null) _buildPlanSummary(),
          
          SizedBox(height: 24),
          
          // Phone Number (for M-Pesa)
          if (_selectedCurrency == 'KES') _buildPhoneInput(),
          
          // Email Input
          _buildEmailInput(),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildNavigationButton(
                  text: 'Back',
                  onPressed: _previousStep,
                  isPrimary: false,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildNavigationButton(
                  text: 'Pay Now',
                  onPressed: _validateAndProceed,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    final price = _selectedPlan!.getPriceForCurrency(_selectedCurrency!);
    final symbol = _selectedPlan!.getCurrencySymbol(_selectedCurrency!);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedPlan!.name, style: TextStyle(color: white)),
              Text('$symbol${price.toStringAsFixed(0)}', style: TextStyle(color: white)),
            ],
          ),
          Divider(color: lightGray.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
              ),
              Text(
                '$symbol${price.toStringAsFixed(0)}',
                style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number (M-Pesa)',
          style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: white),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: '0712345678',
            hintStyle: TextStyle(color: lightGray),
            prefixText: '+254 ',
            prefixStyle: TextStyle(color: primaryGold),
            filled: true,
            fillColor: darkGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryGold),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: white),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            hintStyle: TextStyle(color: lightGray),
            filled: true,
            fillColor: darkGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Processing Payment...',
            style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we process your payment',
            style: TextStyle(color: lightGray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultPage() {
    final isSuccess = _paymentStatus == 'completed';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSuccess ? successGreen : errorRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check : Icons.close,
                color: white,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: TextStyle(
                color: isSuccess ? successGreen : errorRed,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              isSuccess
                  ? 'Your subscription has been activated successfully'
                  : 'There was an issue processing your payment',
              style: TextStyle(color: lightGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildNavigationButton(
              text: isSuccess ? 'Continue to App' : 'Try Again',
              onPressed: () {
                if (isSuccess) {
                  Navigator.of(context).pop(true);
                } else {
                  setState(() {
                    _currentStep = 0;
                    _paymentStatus = null;
                  });
                  _pageController.animateToPage(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryGold : darkGray,
          foregroundColor: isPrimary ? pureBlack : white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _validateAndProceed() {
    // Validate required fields
    if (_selectedCurrency == 'KES' && _phoneController.text.trim().isEmpty) {
      _showErrorMessage('Phone number is required for M-Pesa payments');
      return;
    }
    
    if (_emailController.text.trim().isEmpty) {
      _showErrorMessage('Email address is required');
      return;
    }
    
    // Proceed to payment
    _processPayment();
  }
}