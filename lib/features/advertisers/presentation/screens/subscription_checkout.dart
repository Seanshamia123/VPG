// subscription_checkout.dart - Fixed with proper UserSession integration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your subscription_plans_page.dart to use SubscriptionPlan class
import 'subscription_plans_page.dart';
// Import your actual UserSession service
import 'package:escort/services/user_session.dart';
import 'package:escort/config/api_config.dart';

// Currency class (you can move this to a separate file if needed)
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

// Payment Service with proper authentication
class PaymentService {
  static Future<Map<String, dynamic>> createCheckout({
    required String planId,
    required String currency,
    String? phoneNumber,
    String? email,
    String? redirectUrl,
  }) async {
    try {
      // Check if user is logged in first
      final isLoggedIn = await UserSession.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('User must be logged in to make payments');
      }

      // Get user data for additional validation
      final userData = await UserSession.getCurrentUserData();
      final userId = await UserSession.getUserId();
      
      print('=== CREATING CHECKOUT ===');
      print('User ID: $userId');
      print('Plan ID: $planId');
      print('Currency: $currency');
      print('Email: $email');
      print('Phone: $phoneNumber');
      print('========================');

      final requestBody = {
        'plan_id': planId,
        'currency': currency,
        'user_id': userId, // Include user ID from session
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (redirectUrl != null && redirectUrl.isNotEmpty) 'redirect_url': redirectUrl,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.api}/payment/create-checkout'),
        headers: await _getHeaders(),
        body: json.encode(requestBody),
      );

      print('=== CHECKOUT RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      } else {
        // Handle specific error cases
        if (response.statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else if (response.statusCode == 403) {
          throw Exception('Access denied. Please check your account status.');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create checkout');
        }
      }
    } catch (e) {
      print('Error creating checkout: $e');
      throw Exception('Error creating checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(String checkoutId) async {
    try {
      // Check if user is still logged in
      final isLoggedIn = await UserSession.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('User session expired. Please log in again.');
      }

      print('=== VERIFYING PAYMENT ===');
      print('Checkout ID: $checkoutId');
      print('========================');

      final response = await http.post(
        Uri.parse('${ApiConfig.api}/payment/verify/$checkoutId'),
        headers: await _getHeaders(),
      );

      print('=== VERIFICATION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        if (response.statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to verify payment');
        }
      }
    } catch (e) {
      print('Error verifying payment: $e');
      throw Exception('Error verifying payment: $e');
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await UserSession.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('=== REQUEST HEADERS ===');
        print('Authorization: Bearer ${token.substring(0, 20)}...');
        print('=====================');
      } else {
        print('Warning: No access token found');
      }
      
      return headers;
    } catch (e) {
      print('Error getting headers: $e');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }
}

// Modified Checkout Page to accept selected plan
class SubscriptionCheckoutPage extends StatefulWidget {
  final SubscriptionPlan selectedPlan;
  final String selectedCurrency;

  const SubscriptionCheckoutPage({
    Key? key,
    required this.selectedPlan,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  State<SubscriptionCheckoutPage> createState() => _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  // Color scheme
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showWebView = false;
  String? _checkoutUrl;
  String? _checkoutId;
  
  WebViewController? _webViewController;
  bool _webViewInitialized = false;

  // User session data
  Map<String, dynamic>? _userData;
  String? _userEmail;
  String? _userPhone;
  bool _sessionChecked = false;

  @override
  void initState() {
    super.initState();
    _initializeUserSession();
  }

  Future<void> _initializeUserSession() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await UserSession.isLoggedIn();
      if (!isLoggedIn) {
        _showErrorSnackBar('Please log in to continue with payment');
        Navigator.of(context).pop();
        return;
      }

      // Get user data
      _userData = await UserSession.getCurrentUserData();
      _userEmail = await UserSession.getUserEmail();
      _userPhone = await UserSession.getUserPhoneNumber();

      // Pre-fill email if available
      if (_userEmail != null && _userEmail!.isNotEmpty) {
        _emailController.text = _userEmail!;
      }

      // Pre-fill phone if available (for KES currency)
      if (widget.selectedCurrency == 'KES' && _userPhone != null && _userPhone!.isNotEmpty) {
        // Format phone number for display (remove country code if present)
        String displayPhone = _userPhone!;
        if (displayPhone.startsWith('254')) {
          displayPhone = '0${displayPhone.substring(3)}';
        } else if (displayPhone.startsWith('+254')) {
          displayPhone = '0${displayPhone.substring(4)}';
        }
        _phoneController.text = displayPhone;
      }

      setState(() {
        _sessionChecked = true;
      });

      print('=== USER SESSION INITIALIZED ===');
      print('User Email: $_userEmail');
      print('User Phone: $_userPhone');
      print('User Data Keys: ${_userData?.keys.toList()}');
      print('================================');

    } catch (e) {
      print('Error initializing user session: $e');
      _showErrorSnackBar('Failed to load user session');
      Navigator.of(context).pop();
    }
  }

  void _initializeWebView() {
    if (!_webViewInitialized) {
      try {
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                _handlePageNavigation(url);
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
              },
              onWebResourceError: (WebResourceError error) {
                print('WebView error: ${error.description}');
              },
            ),
          );
        _webViewInitialized = true;
      } catch (e) {
        print('Error initializing WebView controller: $e');
        _showErrorSnackBar('Failed to initialize payment interface');
      }
    }
  }

  void _handlePageNavigation(String url) {
    print('Navigating to: $url');
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

  @override
  Widget build(BuildContext context) {
    // Show loading while checking session
    if (!_sessionChecked) {
      return Scaffold(
        backgroundColor: pureBlack,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryGold),
              SizedBox(height: 16),
              Text(
                'Loading user session...',
                style: TextStyle(color: white),
              ),
            ],
          ),
        ),
      );
    }

    if (_showWebView && _checkoutUrl != null) {
      return _buildWebViewPage();
    }

    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        title: const Text(
          'Complete Payment',
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
              // User Info Display
              _buildUserInfo(),
              const SizedBox(height: 16),
              
              // Plan Summary
              _buildPlanSummary(),
              const SizedBox(height: 24),
              
              // Payment Details Form
              _buildPaymentForm(),
              const SizedBox(height: 32),
              
              // Payment Button
              _buildPaymentButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged in as',
                  style: TextStyle(color: lightGray, fontSize: 12),
                ),
                FutureBuilder<String?>(
                  future: UserSession.getUserName(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? _userEmail ?? 'User',
                      style: const TextStyle(color: white, fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    final price = widget.selectedPlan.getPriceForCurrency(widget.selectedCurrency);
    final symbol = widget.selectedPlan.getCurrencySymbol(widget.selectedCurrency);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: primaryGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedPlan.name,
                      style: const TextStyle(
                        color: white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.selectedPlan.description,
                      style: const TextStyle(
                        color: lightGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$symbol${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: lightGray),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$symbol${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Details',
          style: TextStyle(
            color: primaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Email Field
        _buildEmailField(),
        const SizedBox(height: 16),
        
        // Phone Field (for M-Pesa)
        if (widget.selectedCurrency == 'KES') _buildPhoneField(),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: white),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: const TextStyle(color: primaryGold),
        hintText: 'your@email.com',
        hintStyle: const TextStyle(color: lightGray),
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
    );
  }

  Widget _buildPhoneField() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: white),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: 'Phone Number (M-Pesa)',
            labelStyle: const TextStyle(color: primaryGold),
            hintText: '0712345678',
            hintStyle: const TextStyle(color: lightGray),
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentButton() {
    final price = widget.selectedPlan.getPriceForCurrency(widget.selectedCurrency);
    final symbol = widget.selectedPlan.getCurrencySymbol(widget.selectedCurrency);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: pureBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                'Pay $symbol${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildWebViewPage() {
    if (_webViewController == null) {
      _initializeWebView();
    }

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
            child: _webViewController != null 
                ? WebViewWidget(controller: _webViewController!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryGold),
                        SizedBox(height: 16),
                        Text(
                          'Initializing payment interface...',
                          style: TextStyle(color: white),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Payment processing methods
  Future<void> _proceedToPayment() async {
    // Validate user session first
    final isLoggedIn = await UserSession.isLoggedIn();
    if (!isLoggedIn) {
      _showErrorSnackBar('Session expired. Please log in again.');
      Navigator.of(context).pop();
      return;
    }

    // Validate fields
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email is required');
      return;
    }
    
    if (widget.selectedCurrency == 'KES' && _phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required for M-Pesa');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = widget.selectedCurrency == 'KES' 
          ? _formatPhoneNumber(_phoneController.text.trim())
          : null;

      final checkoutResult = await PaymentService.createCheckout(
        planId: widget.selectedPlan.id,
        currency: widget.selectedCurrency,
        phoneNumber: phoneNumber,
        email: _emailController.text.trim(),
        redirectUrl: 'your-app://payment-complete',
      );

      if (checkoutResult['success'] == true || checkoutResult['checkout_url'] != null) {
        final checkoutUrl = checkoutResult['checkout_url'] ?? checkoutResult['url'];
        final checkoutId = checkoutResult['checkout_id'] ?? checkoutResult['id'];
        
        if (checkoutUrl != null) {
          // Initialize WebView before showing it
          _initializeWebView();
          
          setState(() {
            _checkoutUrl = checkoutUrl;
            _checkoutId = checkoutId;
            _showWebView = true;
          });
          
          // Load URL after a small delay to ensure WebView is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_webViewController != null && mounted) {
              _webViewController!.loadRequest(Uri.parse(checkoutUrl));
            }
          });
        } else {
          _showErrorSnackBar('Invalid checkout URL received');
        }
      } else {
        _showErrorSnackBar(checkoutResult['message'] ?? 'Failed to create payment session');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Authentication failed')) {
        // Handle authentication error
        Navigator.of(context).pop();
        _showErrorSnackBar('Please log in again to continue');
      } else {
        _showErrorSnackBar('Error: $errorMessage');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254') && cleaned.length == 12) {
      // Already formatted
    } else if (cleaned.length == 9) {
      cleaned = '254$cleaned';
    }
    
    return cleaned;
  }

  Future<void> _verifyPayment() async {
    if (_checkoutId == null) return;

    // Check session before verification
    final isLoggedIn = await UserSession.isLoggedIn();
    if (!isLoggedIn) {
      _showErrorSnackBar('Session expired during payment');
      Navigator.of(context).pop();
      return;
    }

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
      String errorMessage = e.toString();
      if (errorMessage.contains('Authentication failed')) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Session expired. Please log in again.');
      } else {
        _showErrorSnackBar('Verification error: $errorMessage');
        setState(() {
          _showWebView = false;
          _checkoutUrl = null;
        });
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

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}