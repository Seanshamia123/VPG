// subscription_checkout.dart - FIXED to support pending login credentials
import 'package:escort/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:escort/features/advertisers/presentation/screens/subscription_plans_page.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription.dart';
import 'package:escort/config/api_config.dart';

// Currency class
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

// Payment Service - FIXED to handle pending login
class PaymentService {
  static Future<Map<String, dynamic>> createCheckout({
    required String planId,
    required String currency,
    String? phoneNumber,
    String? email,
    String? redirectUrl,
    // Card payment fields
    String? cardNumber,
    String? cardExpiry,
    String? cardCvc,
    String? cardHolderName,
    String? country,
    // CRITICAL: Pending login credentials
    String? pendingLoginEmail,
    String? pendingLoginPassword,
    String? pendingLoginUserType,
  }) async {
    try {
      print('=== CREATING CHECKOUT ===');
      print('Plan ID: $planId');
      print('Currency: $currency');
      print('Has Pending Login: ${pendingLoginEmail != null}');
      print('========================');

      final requestBody = {
        'plan_id': planId,
        'currency': currency,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (redirectUrl != null && redirectUrl.isNotEmpty) 'redirect_url': redirectUrl,
        if (cardNumber != null && cardNumber.isNotEmpty) 'card_number': cardNumber,
        if (cardExpiry != null && cardExpiry.isNotEmpty) 'card_expiry': cardExpiry,
        if (cardCvc != null && cardCvc.isNotEmpty) 'card_cvc': cardCvc,
        if (cardHolderName != null && cardHolderName.isNotEmpty) 'card_holder_name': cardHolderName,
        if (country != null && country.isNotEmpty) 'country': country,
        // CRITICAL: Add pending login credentials
        if (pendingLoginEmail != null && pendingLoginEmail.isNotEmpty) 'pending_login_email': pendingLoginEmail,
        if (pendingLoginPassword != null && pendingLoginPassword.isNotEmpty) 'pending_login_password': pendingLoginPassword,
        if (pendingLoginUserType != null && pendingLoginUserType.isNotEmpty) 'pending_login_user_type': pendingLoginUserType,
      };

      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.api}/payment/create-checkout'),
        headers: headers,
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
        throw Exception(responseData['message'] ?? responseData['error'] ?? 'Failed to create checkout');
      }
    } catch (e) {
      print('Error creating checkout: $e');
      throw Exception('Error creating checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(
    String checkoutId, {
    String? pendingLoginEmail,
    String? pendingLoginPassword,
    String? pendingLoginUserType,
  }) async {
    try {
      print('=== VERIFYING PAYMENT ===');
      print('Checkout ID: $checkoutId');
      print('Has Pending Login: ${pendingLoginEmail != null}');
      print('========================');

      final requestBody = {
        if (pendingLoginEmail != null && pendingLoginEmail.isNotEmpty) 'pending_login_email': pendingLoginEmail,
        if (pendingLoginPassword != null && pendingLoginPassword.isNotEmpty) 'pending_login_password': pendingLoginPassword,
        if (pendingLoginUserType != null && pendingLoginUserType.isNotEmpty) 'pending_login_user_type': pendingLoginUserType,
      };

      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.api}/payment/verify/$checkoutId'),
        headers: headers,
        body: requestBody.isNotEmpty ? json.encode(requestBody) : null,
      );

      print('=== VERIFICATION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify payment');
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
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      return headers;
    } catch (e) {
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }
}

// Main Checkout Page - FIXED
class SubscriptionCheckoutPage extends StatefulWidget {
  final SubscriptionPlan selectedPlan;
  final String selectedCurrency;
  final String? pendingLoginEmail;
  final String? pendingLoginPassword;
  final String? pendingLoginUserType;

  const SubscriptionCheckoutPage({
    Key? key,
    required this.selectedPlan,
    required this.selectedCurrency,
    this.pendingLoginEmail,
    this.pendingLoginPassword,
    this.pendingLoginUserType,
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

  // Form controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isLoading = false;
  bool _showWebView = false;
  String? _checkoutUrl;
  String? _checkoutId;
  String? _invoiceId;
  String? _apiRef;
  
  WebViewController? _webViewController;
  bool _webViewInitialized = false;

  String? _userEmail;
  bool _sessionChecked = false;
  bool _hasPendingLogin = false;

  String _cardBrand = '';
  String _selectedCountry = 'US';
  
  final Map<String, String> _countries = {
    'US': 'United States',
    'KE': 'Kenya',
    'DE': 'Germany',
    'GB': 'United Kingdom',
    'FR': 'France',
    'IT': 'Italy',
    'ES': 'Spain',
    'CA': 'Canada',
    'AU': 'Australia',
  };

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _autoSelectCountry();
  }
  
  void _autoSelectCountry() {
    final currencyCountryMap = {
      'KES': 'KE',
      'USD': 'US',
      'EUR': 'DE',
      'GBP': 'GB',
    };
    
    final autoCountry = currencyCountryMap[widget.selectedCurrency];
    if (autoCountry != null && _countries.containsKey(autoCountry)) {
      setState(() {
        _selectedCountry = autoCountry;
      });
    }
  }

  Future<void> _initializeSession() async {
    try {
      // CRITICAL FIX: Check if we have pending login credentials
      _hasPendingLogin = widget.pendingLoginEmail != null && 
                        widget.pendingLoginPassword != null;

      print('=== INITIALIZING SESSION ===');
      print('Has Pending Login: $_hasPendingLogin');
      print('Pending Email: ${widget.pendingLoginEmail}');
      
      if (_hasPendingLogin) {
        // Use pending login email for checkout
        _userEmail = widget.pendingLoginEmail;
        _emailController.text = _userEmail!;
        
        print('✓ Using pending login credentials');
        setState(() {
          _sessionChecked = true;
        });
        return;
      }

      // Try to get logged-in user session
      final isLoggedIn = await UserSession.isLoggedIn();
      print('Is Logged In: $isLoggedIn');

      if (isLoggedIn) {
        _userEmail = await UserSession.getUserEmail();
        final userPhone = await UserSession.getUserPhoneNumber();

        if (_userEmail != null && _userEmail!.isNotEmpty) {
          _emailController.text = _userEmail!;
        }

        if (widget.selectedCurrency == 'KES' && userPhone != null && userPhone.isNotEmpty) {
          String displayPhone = userPhone;
          if (displayPhone.startsWith('254')) {
            displayPhone = '0${displayPhone.substring(3)}';
          } else if (displayPhone.startsWith('+254')) {
            displayPhone = '0${displayPhone.substring(4)}';
          }
          _phoneController.text = displayPhone;
        }
      } else if (!_hasPendingLogin) {
        // No session and no pending login - can't proceed
        _showErrorSnackBar('Please log in or complete signup to continue');
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _sessionChecked = true;
      });

    } catch (e) {
      print('Error initializing session: $e');
      
      // If we have pending login, continue anyway
      if (_hasPendingLogin) {
        _userEmail = widget.pendingLoginEmail;
        _emailController.text = _userEmail!;
        setState(() {
          _sessionChecked = true;
        });
      } else {
        _showErrorSnackBar('Failed to load session');
        Navigator.of(context).pop();
      }
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
        print('Error initializing WebView: $e');
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

  String _detectCardBrand(String number) {
    final cleaned = number.replaceAll(' ', '');
    if (cleaned.isEmpty) return '';
    
    if (cleaned.startsWith('4')) return 'VISA';
    if (cleaned.startsWith('5')) return 'MASTERCARD';
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) return 'AMEX';
    if (cleaned.startsWith('6')) return 'DISCOVER';
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
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
                'Loading...',
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
              // Show pending login notice
              if (_hasPendingLogin)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: darkGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: primaryGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Completing Registration',
                              style: TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Account: ${widget.pendingLoginEmail}',
                              style: const TextStyle(
                                color: lightGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              _buildPlanSummary(),
              const SizedBox(height: 24),
              _buildPaymentForm(),
              const SizedBox(height: 32),
              _buildPaymentButton(),
              const SizedBox(height: 16),
              _buildSecurityBadge(),
            ],
          ),
        ),
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
    final isKES = widget.selectedCurrency == 'KES';
    
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
        
        _buildEmailField(),
        const SizedBox(height: 16),
        
        if (isKES) ...[
          _buildPhoneField(),
        ] else ...[
          _buildCardFields(),
        ],
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: white),
      enabled: !_hasPendingLogin, // Disable if using pending login
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: const TextStyle(color: primaryGold),
        hintText: 'your@email.com',
        hintStyle: const TextStyle(color: lightGray),
        filled: true,
        fillColor: darkGray,
        prefixIcon: const Icon(Icons.email_outlined, color: primaryGold),
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
    return TextFormField(
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
        prefixIcon: const Icon(Icons.phone_android, color: primaryGold),
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

  Widget _buildCardFields() {
    return Column(
      children: [
        // Country Selector
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          dropdownColor: darkGray,
          style: const TextStyle(color: white),
          decoration: InputDecoration(
            labelText: 'Country',
            labelStyle: const TextStyle(color: primaryGold),
            filled: true,
            fillColor: darkGray,
            prefixIcon: const Icon(Icons.public, color: primaryGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _countries.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCountry = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: white),
          onChanged: (value) {
            setState(() {
              _cardBrand = _detectCardBrand(value);
            });
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Card Number',
            labelStyle: const TextStyle(color: primaryGold),
            hintText: '4### #### #### ####',
            filled: true,
            fillColor: darkGray,
            prefixIcon: const Icon(Icons.credit_card, color: primaryGold),
            suffixIcon: _cardBrand.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _cardBrand,
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Expiry and CVC
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cardExpiryController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: white),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  labelStyle: const TextStyle(color: primaryGold),
                  hintText: '12/25',
                  filled: true,
                  fillColor: darkGray,
                  prefixIcon: const Icon(Icons.calendar_today, color: primaryGold, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cardCvcController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: white),
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: const TextStyle(color: primaryGold),
                  hintText: '123',
                  filled: true,
                  fillColor: darkGray,
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryGold, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Card Holder Name
        TextFormField(
          controller: _cardHolderController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: white),
          decoration: InputDecoration(
            labelText: 'Name on Card',
            labelStyle: const TextStyle(color: primaryGold),
            hintText: 'John Doe',
            filled: true,
            fillColor: darkGray,
            prefixIcon: const Icon(Icons.person_outline, color: primaryGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, color: primaryGold, size: 16),
          const SizedBox(width: 8),
          Text(
            'Secured by IntaSend',
            style: TextStyle(
              color: lightGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  Future<void> _proceedToPayment() async {
    // CRITICAL FIX: Allow payment with pending login credentials
    if (!_hasPendingLogin) {
      final isLoggedIn = await UserSession.isLoggedIn();
      if (!isLoggedIn) {
        _showErrorSnackBar('Session expired. Please log in again.');
        Navigator.of(context).pop();
        return;
      }
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email is required');
      return;
    }
    
    final isKES = widget.selectedCurrency == 'KES';
    
    if (isKES && _phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required for M-Pesa');
      return;
    }
    
    // Validate card fields for non-KES payments
    if (!isKES) {
      if (_cardNumberController.text.trim().isEmpty) {
        _showErrorSnackBar('Card number is required');
        return;
      }
      if (_cardExpiryController.text.trim().isEmpty) {
        _showErrorSnackBar('Card expiry date is required');
        return;
      }
      if (_cardCvcController.text.trim().isEmpty) {
        _showErrorSnackBar('Card CVC is required');
        return;
      }
      if (_cardHolderController.text.trim().isEmpty) {
        _showErrorSnackBar('Cardholder name is required');
        return;
      }
      
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      if (cardNumber.length < 13 || cardNumber.length > 19) {
        _showErrorSnackBar('Invalid card number');
        return;
      }
      
      if (!_cardExpiryController.text.contains('/') || _cardExpiryController.text.length != 5) {
        _showErrorSnackBar('Invalid expiry date format (MM/YY)');
        return;
      }
      
      if (_cardCvcController.text.length < 3) {
        _showErrorSnackBar('Invalid CVC');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = isKES 
          ? _formatPhoneNumber(_phoneController.text.trim())
          : null;

      print('=== PAYMENT REQUEST ===');
      print('Has Pending Login: $_hasPendingLogin');
      print('Email: ${_emailController.text.trim()}');
      print('Phone: $phoneNumber');
      print('Currency: ${widget.selectedCurrency}');
      print('======================');

      final checkoutResult = await PaymentService.createCheckout(
        planId: widget.selectedPlan.id,
        currency: widget.selectedCurrency,
        phoneNumber: phoneNumber,
        email: _emailController.text.trim(),
        redirectUrl: 'your-app://payment-complete',
        cardNumber: !isKES ? _cardNumberController.text.replaceAll(' ', '') : null,
        cardExpiry: !isKES ? _cardExpiryController.text.replaceAll('/', '') : null,
        cardCvc: !isKES ? _cardCvcController.text : null,
        cardHolderName: !isKES ? _cardHolderController.text.trim() : null,
        country: !isKES ? _selectedCountry : null,
        // CRITICAL: Pass pending login credentials
        pendingLoginEmail: widget.pendingLoginEmail,
        pendingLoginPassword: widget.pendingLoginPassword,
        pendingLoginUserType: widget.pendingLoginUserType,
      );

      if (checkoutResult['success'] == true) {
        final paymentType = checkoutResult['payment_type'] ?? 'web_checkout';
        
        if (paymentType == 'mpesa_stk_push') {
          _handleMpesaStkPush(checkoutResult);
        } else {
          final checkoutUrl = checkoutResult['checkout_url'] ?? checkoutResult['url'];
          final checkoutId = checkoutResult['checkout_id'] ?? checkoutResult['id'];
          
          if (checkoutUrl != null) {
            _initializeWebView();
            
            setState(() {
              _checkoutUrl = checkoutUrl;
              _checkoutId = checkoutId;
              _showWebView = true;
            });
            
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_webViewController != null && mounted) {
                _webViewController!.loadRequest(Uri.parse(checkoutUrl));
              }
            });
          } else {
            _showErrorSnackBar('Invalid checkout URL received');
          }
        }
      } else {
        _showErrorSnackBar(checkoutResult['message'] ?? 'Failed to create payment session');
      }
    } catch (e) {
      String errorMessage = e.toString();
      print('Payment error: $errorMessage');
      _showErrorSnackBar('Error: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMpesaStkPush(Map<String, dynamic> checkoutResult) {
    final checkoutId = checkoutResult['checkout_id'];
    final invoiceId = checkoutResult['invoice_id'];
    final apiRef = checkoutResult['reference'];
    final phoneNumber = checkoutResult['phone_number'];
    final message = checkoutResult['message'] ?? 'Please check your phone for M-Pesa prompt';

    _checkoutId = checkoutId;
    _invoiceId = invoiceId;
    _apiRef = apiRef;

    print('=== M-PESA STK PUSH INITIATED ===');
    print('Checkout ID: $checkoutId');
    print('Invoice ID: $invoiceId');
    print('Phone: $phoneNumber');
    print('================================');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _MpesaWaitingDialog(
          message: message,
          phoneNumber: phoneNumber,
          invoiceId: invoiceId,
          onVerify: () => _verifyPayment(),
          onCancel: () {
            Navigator.of(context).pop();
            setState(() {
              _checkoutId = null;
              _invoiceId = null;
              _apiRef = null;
            });
          },
        );
      },
    );
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
    if (_checkoutId == null && _invoiceId == null && _apiRef == null) {
      _showErrorSnackBar('No payment to verify');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('=== VERIFYING PAYMENT ===');
      print('Checkout ID: $_checkoutId');
      print('Has Pending Login: $_hasPendingLogin');
      print('========================');

      final result = await PaymentService.verifyPayment(
        _checkoutId!,
        pendingLoginEmail: widget.pendingLoginEmail,
        pendingLoginPassword: widget.pendingLoginPassword,
        pendingLoginUserType: widget.pendingLoginUserType,
      );
      
      print('=== VERIFICATION RESULT ===');
      print('Success: ${result['success']}');
      print('Status: ${result['status']}');
      print('Message: ${result['message']}');
      print('===========================');
      
      final state = result['state']?.toString().toUpperCase() ?? '';
      final status = result['status']?.toString().toLowerCase() ?? '';
      
      if (result['success'] == true || state == 'COMPLETE' || state == 'COMPLETED' || status == 'complete') {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        _showSuccessSnackBar('Payment successful! Your subscription is now active.');
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else if (state == 'PENDING' || status == 'pending') {
        _showErrorSnackBar('Payment is still processing. Please wait and try again.');
      } else {
        final errorMessage = result['message'] ?? 'Payment verification failed';
        _showErrorSnackBar(errorMessage);
        
        if (state == 'FAILED' || state == 'CANCELLED') {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          setState(() {
            _showWebView = false;
            _checkoutUrl = null;
            _checkoutId = null;
            _invoiceId = null;
            _apiRef = null;
          });
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      print('Verification error: $errorMessage');
      _showErrorSnackBar('Verification error: $errorMessage');
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
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }
}

// Input Formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// M-Pesa Waiting Dialog
class _MpesaWaitingDialog extends StatelessWidget {
  final String message;
  final String? phoneNumber;
  final String? invoiceId;
  final VoidCallback onVerify;
  final VoidCallback onCancel;

  const _MpesaWaitingDialog({
    Key? key,
    required this.message,
    this.phoneNumber,
    this.invoiceId,
    required this.onVerify,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFD700), width: 1),
      ),
      title: Row(
        children: [
          Icon(Icons.phone_android, color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'M-Pesa Payment',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFFD700)),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (phoneNumber != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_iphone, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    phoneNumber!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Enter your M-Pesa PIN on your phone to complete payment.',
            style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: onVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
          ),
          child: const Text('Verify Payment'),
        ),
      ],
    );
  }
}