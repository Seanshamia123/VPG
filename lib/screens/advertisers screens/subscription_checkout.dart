// subscription_checkout.dart - Flutter checkout page (FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:escort/styles/app_size.dart'; // Comment out if not found
// import 'package:escort/services/user_session.dart'; // Comment out if not found
import 'package:url_launcher/url_launcher.dart';

// Mock UserSession class - replace with your actual implementation
class UserSession {
  static Future<String?> getAccessToken() async {
    // Replace with your actual token retrieval logic
    return "your_access_token_here";
  }
}

// Models
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
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      priceKes: (json['price_kes'] ?? 0.0).toDouble(),
      priceUsd: (json['price_usd'] ?? 0.0).toDouble(),
      priceEur: (json['price_eur'] ?? 0.0).toDouble(),
      durationDays: json['duration_days'] ?? 30,
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['is_popular'] ?? false,
    );
  }

  double getPriceForCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'KES':
        return priceKes;
      case 'USD':
        return priceUsd;
      case 'EUR':
        return priceEur;
      default:
        return priceKes;
    }
  }
}

class Currency {
  final String code;
  final String name;
  final String symbol;

  Currency({required this.code, required this.name, required this.symbol});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }
}

// Payment Service
class PaymentService {
  static const String baseUrl = 'https://your-api-url.com'; // Replace with your actual API URL

  static Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/plans'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        
        // Handle both direct array and wrapped response
        List<dynamic> jsonList;
        if (responseBody is List) {
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody['data'] != null) {
          jsonList = responseBody['data'];
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => SubscriptionPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subscription plans: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading plans: $e'); // Add logging
      throw Exception('Error loading plans: $e');
    }
  }

  static Future<List<Currency>> getSupportedCurrencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/currencies'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> currencies = data['currencies'] ?? data['data'] ?? [];
        return currencies.map((json) => Currency.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load currencies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading currencies: $e'); // Add logging
      throw Exception('Error loading currencies: $e');
    }
  }

  static Future<Map<String, dynamic>> createCheckout({
    required String planId,
    required String currency,
    String? phoneNumber,
    String? redirectUrl,
  }) async {
    try {
      final requestBody = {
        'plan_id': planId,
        'currency': currency,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (redirectUrl != null && redirectUrl.isNotEmpty) 'redirect_url': redirectUrl,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-checkout'),
        headers: await _getHeaders(),
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create checkout');
      }
    } catch (e) {
      print('Error creating checkout: $e'); // Add logging
      throw Exception('Error creating checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(String checkoutId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/verify/$checkoutId'),
        headers: await _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify payment');
      }
    } catch (e) {
      print('Error verifying payment: $e'); // Add logging
      throw Exception('Error verifying payment: $e');
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await UserSession.getAccessToken();
      return {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting headers: $e');
      return {'Content-Type': 'application/json'};
    }
  }
}

// Main Checkout Page
class SubscriptionCheckoutPage extends StatefulWidget {
  const SubscriptionCheckoutPage({super.key});

  @override
  State<SubscriptionCheckoutPage> createState() => _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  // Color scheme
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  List<SubscriptionPlan> _plans = [];
  List<Currency> _currencies = [];
  SubscriptionPlan? _selectedPlan;
  Currency? _selectedCurrency;
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _showWebView = false;
  String? _checkoutUrl;
  String? _checkoutId;
  
  // WebView controller - Initialize properly
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadData();
  }

  void _initializeWebView() {
    // Initialize WebView controller (for newer webview_flutter versions)
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _handlePageNavigation(url);
          },
        ),
      );
  }

  void _handlePageNavigation(String url) {
    // Handle payment completion redirect
    if (url.contains('payment-success') || 
        url.contains('payment-complete') || 
        url.contains('success')) {
      _verifyPayment();
    } else if (url.contains('payment-failed') || 
               url.contains('cancel') || 
               url.contains('error')) {
      _showErrorSnackBar('Payment was cancelled or failed');
      setState(() {
        _showWebView = false;
        _checkoutUrl = null;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load default currencies if API fails
      final List<Currency> defaultCurrencies = [
        Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh'),
        Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
        Currency(code: 'EUR', name: 'Euro', symbol: '€'),
      ];

      // Load default plans if API fails
      final List<SubscriptionPlan> defaultPlans = [
        SubscriptionPlan(
          id: 'basic',
          name: 'Basic Plan',
          description: 'Perfect for getting started',
          priceKes: 1000,
          priceUsd: 10,
          priceEur: 9,
          durationDays: 30,
          features: ['Feature 1', 'Feature 2', 'Feature 3'],
          isPopular: false,
        ),
        SubscriptionPlan(
          id: 'premium',
          name: 'Premium Plan',
          description: 'Most popular choice',
          priceKes: 2500,
          priceUsd: 25,
          priceEur: 22,
          durationDays: 30,
          features: ['All Basic features', 'Premium Feature 1', 'Premium Feature 2'],
          isPopular: true,
        ),
      ];

      try {
        final plansResult = PaymentService.getSubscriptionPlans();
        final currenciesResult = PaymentService.getSupportedCurrencies();
        
        final plans = await plansResult;
        final currencies = await currenciesResult;
        
        if (mounted) {
          setState(() {
            _plans = plans.isNotEmpty ? plans : defaultPlans;
            _currencies = currencies.isNotEmpty ? currencies : defaultCurrencies;
          });
        }
      } catch (e) {
        print('API call failed, using defaults: $e');
        if (mounted) {
          setState(() {
            _plans = defaultPlans;
            _currencies = defaultCurrencies;
          });
        }
      }

      // Set default selections
      if (mounted) {
        setState(() {
          _selectedCurrency = _currencies.firstWhere(
            (c) => c.code == 'KES', 
            orElse: () => _currencies.isNotEmpty ? _currencies.first : defaultCurrencies.first
          );
          
          if (_plans.isNotEmpty) {
            _selectedPlan = _plans.firstWhere(
              (p) => p.isPopular,
              orElse: () => _plans.first
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Kenyan numbers
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254') && cleaned.length == 12) {
      // Already formatted
    } else if (cleaned.length == 9) {
      cleaned = '254$cleaned';
    }
    
    return cleaned;
  }

  Future<void> _proceedToPayment() async {
    if (_selectedPlan == null || _selectedCurrency == null) {
      _showErrorSnackBar('Please select a plan and currency');
      return;
    }

    // Validate phone number for M-Pesa payments
    if (_selectedCurrency!.code == 'KES') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _showErrorSnackBar('Phone number is required for M-Pesa payments');
        return;
      }
      
      final formattedPhone = _formatPhoneNumber(phone);
      if (formattedPhone.length != 12 || !formattedPhone.startsWith('254')) {
        _showErrorSnackBar('Please enter a valid Kenyan phone number');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = _selectedCurrency!.code == 'KES' 
          ? _formatPhoneNumber(_phoneController.text.trim())
          : null;

      final checkoutData = await PaymentService.createCheckout(
        planId: _selectedPlan!.id,
        currency: _selectedCurrency!.code,
        phoneNumber: phoneNumber,
        redirectUrl: 'your-app://payment-complete', // Add your redirect URL
      );

      if (checkoutData['success'] == true || checkoutData['checkout_url'] != null) {
        final checkoutUrl = checkoutData['checkout_url'] ?? checkoutData['url'];
        final checkoutId = checkoutData['checkout_id'] ?? checkoutData['id'];
        
        if (checkoutUrl != null) {
          setState(() {
            _checkoutUrl = checkoutUrl;
            _checkoutId = checkoutId;
            _showWebView = true;
          });
          
          // Load the URL in WebView
          _webViewController.loadRequest(Uri.parse(checkoutUrl));
        } else {
          _showErrorSnackBar('Invalid checkout URL received');
        }
      } else {
        _showErrorSnackBar(checkoutData['message'] ?? 'Failed to create payment session');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_checkoutId == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await PaymentService.verifyPayment(_checkoutId!);
      
      if (result['success'] == true || result['status'] == 'completed') {
        _showSuccessSnackBar('Payment successful! Your subscription is now active.');
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return success
          }
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'Payment verification failed');
        setState(() {
          _showWebView = false;
          _checkoutUrl = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Verification error: $e');
      setState(() {
        _showWebView = false;
        _checkoutUrl = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _checkoutUrl != null) {
      return _buildWebViewPage();
    }

    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        title: const Text(
          'Choose Subscription Plan',
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGold),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency Selection
                    if (_currencies.isNotEmpty) _buildCurrencySelector(),
                    if (_currencies.isNotEmpty) const SizedBox(height: 24),
                    
                    // Plans List
                    if (_plans.isNotEmpty) _buildPlansList(),
                    if (_plans.isNotEmpty) const SizedBox(height: 24),
                    
                    // Phone Number Input (for M-Pesa)
                    if (_selectedCurrency?.code == 'KES')
                      _buildPhoneNumberInput(),
                    
                    // Payment Button
                    if (_selectedPlan != null && _selectedCurrency != null)
                      _buildPaymentButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
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
            'Select Currency',
            style: TextStyle(
              color: primaryGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _currencies.map((currency) {
              final isSelected = _selectedCurrency?.code == currency.code;
              return GestureDetector(
                onTap: () => setState(() => _selectedCurrency = currency),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryGold : lightGray,
                    ),
                  ),
                  child: Text(
                    '${currency.symbol} ${currency.code}',
                    style: TextStyle(
                      color: isSelected ? pureBlack : white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPlansList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            color: primaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan?.id == plan.id;
    final price = plan.getPriceForCurrency(_selectedCurrency?.code ?? 'KES');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? darkGold.withOpacity(0.2) : darkGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryGold : lightGray.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
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
                        color: isSelected ? primaryGold : white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_selectedCurrency?.symbol ?? 'KSh'}${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? primaryGold : white,
                      fontSize: 24,
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
              const SizedBox(height: 12),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: lightGray,
                          fontSize: 12,
                        ),
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

  Widget _buildPhoneNumberInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Number (for M-Pesa)',
            style: TextStyle(
              color: primaryGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: white),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: '0712345678',
              hintStyle: TextStyle(color: lightGray),
              prefixText: '+254 ',
              prefixStyle: const TextStyle(color: primaryGold),
              filled: true,
              fillColor: darkGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: pureBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(pureBlack),
                ),
              )
            : Text(
                'Pay ${_selectedCurrency?.symbol ?? 'KSh'}${_selectedPlan?.getPriceForCurrency(_selectedCurrency?.code ?? 'KES').toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildWebViewPage() {
    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: primaryGold),
        ),
        iconTheme: const IconThemeData(color: primaryGold),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showWebView = false;
                _checkoutUrl = null;
              });
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: primaryGold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Payment Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: darkGray,
            child: Column(
              children: [
                const Text(
                  'Complete your payment in the secure checkout below',
                  style: TextStyle(color: white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: pureBlack,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify Payment'),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _webViewController),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}