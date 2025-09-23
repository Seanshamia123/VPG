// lib/dialogs/intasend_subscription_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:escort/services/subscription_service.dart';

class IntaSendSubscriptionDialog extends StatefulWidget {
  const IntaSendSubscriptionDialog({super.key});

  @override
  State<IntaSendSubscriptionDialog> createState() => _IntaSendSubscriptionDialogState();
}

class _IntaSendSubscriptionDialogState extends State<IntaSendSubscriptionDialog> {
  // Color palette
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  // State variables
  Map<String, dynamic>? _activeSubscription;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _currencies = [];
  Map<String, dynamic>? _selectedPlan;
  Map<String, dynamic>? _selectedCurrency;
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showWebView = false;
  String? _checkoutUrl;
  String? _checkoutId;

  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadData();
  }

  void _initializeWebView() {
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
      // Load data concurrently
      final futures = await Future.wait([
        SubscriptionService.activeSubscription(),
        SubscriptionService.getSubscriptionPlans(),
        SubscriptionService.getSupportedCurrencies(),
      ]);

      if (!mounted) return;

      setState(() {
        _activeSubscription = futures[0] as Map<String, dynamic>?;
        _plans = futures[1] as List<Map<String, dynamic>>;
        _currencies = futures[2] as List<Map<String, dynamic>>;

        // Set default currency (KES preferred)
        if (_currencies.isNotEmpty) {
          _selectedCurrency = _currencies.firstWhere(
            (c) => c['code'] == 'KES',
            orElse: () => _currencies.first,
          );
        }

        // Set default plan (popular plan preferred)
        if (_plans.isNotEmpty) {
          _selectedPlan = _plans.firstWhere(
            (p) => p['is_popular'] == true,
            orElse: () => _plans.first,
          );
        }
      });
    } catch (e) {
      print('Error loading data: $e');
      _showErrorSnackBar('Failed to load subscription data');
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    if (_selectedPlan == null || _selectedCurrency == null) {
      _showErrorSnackBar('Please select a plan and currency');
      return;
    }

    // Validate phone number for KES payments
    if (_selectedCurrency!['code'] == 'KES') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _showErrorSnackBar('Phone number is required for M-Pesa payments');
        return;
      }
      
      if (!SubscriptionService.isValidKenyanPhone(phone)) {
        _showErrorSnackBar('Please enter a valid Kenyan phone number');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final phoneNumber = _selectedCurrency!['code'] == 'KES' 
          ? SubscriptionService.formatPhoneNumber(_phoneController.text.trim())
          : null;

      final checkoutData = await SubscriptionService.createCheckoutSession(
        planId: _selectedPlan!['id'],
        currency: _selectedCurrency!['code'],
        phoneNumber: phoneNumber,
        redirectUrl: 'your-app://payment-complete',
      );

      if (checkoutData['error'] != null) {
        _showErrorSnackBar(checkoutData['error']);
        return;
      }

      final checkoutUrl = checkoutData['checkout_url'];
      final checkoutId = checkoutData['checkout_id'];
      
      if (checkoutUrl != null) {
        setState(() {
          _checkoutUrl = checkoutUrl;
          _checkoutId = checkoutId;
          _showWebView = true;
        });
        
        _webViewController.loadRequest(Uri.parse(checkoutUrl));
      } else {
        _showErrorSnackBar('Invalid checkout URL received');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_checkoutId == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await SubscriptionService.verifyPayment(_checkoutId!);
      
      if (result['success'] == true || result['status'] == 'complete') {
        _showSuccessSnackBar('Payment successful! Your subscription is now active.');
        
        // Reload data to show new subscription
        await _loadData();
        
        setState(() {
          _showWebView = false;
          _checkoutUrl = null;
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
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelSubscription() async {
    if (_activeSubscription == null) return;

    setState(() => _isProcessing = true);

    try {
      final subscriptionId = _activeSubscription!['id'] as int;
      final result = await SubscriptionService.cancel(subscriptionId);
      
      if (result['error'] == null) {
        _showSuccessSnackBar('Subscription cancelled successfully');
        await _loadData(); // Reload data
      } else {
        _showErrorSnackBar('Failed to cancel subscription');
      }
    } catch (e) {
      _showErrorSnackBar('Error cancelling subscription: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _checkoutUrl != null) {
      return _buildWebViewDialog();
    }

    return Dialog(
      insetPadding: EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCharcoal, pureBlack],
          ),
          border: Border.all(color: primaryGold.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: _isLoading ? _buildLoadingView() : _buildContent(),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: primaryGold),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGold.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryGold),
          SizedBox(height: 16),
          Text('Loading subscription plans...', style: TextStyle(color: lightGray)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_activeSubscription != null) {
      return _buildActiveSubscriptionView();
    } else {
      return _buildSubscriptionPlansView();
    }
  }

  Widget _buildActiveSubscriptionView() {
    final sub = _activeSubscription!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your Active Subscription',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryGold,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGold),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: primaryGold),
                    SizedBox(width: 8),
                    Text(
                      'Active Plan',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (sub['status'] ?? 'active').toString().toUpperCase(),
                        style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildInfoRow('Amount', 'KSh ${sub['amount_paid'] ?? 'N/A'}'),
                _buildInfoRow('Payment Method', sub['payment_method'] ?? 'N/A'),
                _buildInfoRow('Start Date', _formatDate(sub['start_date'])),
                _buildInfoRow('End Date', _formatDate(sub['end_date'])),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _cancelSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: white),
                          )
                        : Text('Cancel Subscription', style: TextStyle(color: white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlansView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryGold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Select the perfect subscription for your needs',
            style: TextStyle(color: lightGray),
          ),
          SizedBox(height: 24),
          
          // Currency Selector
          if (_currencies.isNotEmpty) _buildCurrencySelector(),
          SizedBox(height: 24),
          
          // Plans
          if (_plans.isNotEmpty) ..._plans.map(_buildPlanCard),
          
          // Phone number input for KES
          if (_selectedCurrency?['code'] == 'KES') ...[
            SizedBox(height: 20),
            _buildPhoneNumberInput(),
          ],
          
          SizedBox(height: 24),
          
          // Payment button
          if (_selectedPlan != null && _selectedCurrency != null)
            _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Currency',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _currencies.map((currency) {
            final isSelected = _selectedCurrency?['code'] == currency['code'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCurrency = currency),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryGold : lightGray,
                  ),
                ),
                child: Text(
                  '${currency['symbol']} ${currency['code']}',
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
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan?['id'] == plan['id'];
    final isPopular = plan['is_popular'] == true;
    final currency = _selectedCurrency?['code'] ?? 'KES';
    final price = _getPlanPrice(plan, currency);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: Container(
          padding: EdgeInsets.all(16),
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
                      plan['name'] ?? 'Plan',
                      style: TextStyle(
                        color: isSelected ? primaryGold : white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                plan['description'] ?? 'Premium subscription plan',
                style: TextStyle(color: lightGray, fontSize: 14),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_selectedCurrency?['symbol'] ?? 'KSh'}${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? primaryGold : white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${plan['duration_days'] ?? 30} days',
                    style: TextStyle(color: lightGray, fontSize: 14),
                  ),
                ],
              ),
              if (plan['features'] != null) ...[
                SizedBox(height: 12),
                ...((plan['features'] as List?) ?? []).map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: primaryGold, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.toString(),
                          style: TextStyle(color: lightGray, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'M-Pesa Phone Number',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
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
      ],
    );
  }

  Widget _buildPaymentButton() {
    final price = _getPlanPrice(_selectedPlan!, _selectedCurrency!['code']);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: pureBlack,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isProcessing
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(pureBlack),
                ),
              )
            : Text(
                'Pay ${_selectedCurrency!['symbol']}${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildWebViewDialog() {
    return Dialog.fullscreen(
      backgroundColor: pureBlack,
      child: Scaffold(
        backgroundColor: pureBlack,
        appBar: AppBar(
          backgroundColor: darkCharcoal,
          title: Text('Complete Payment', style: TextStyle(color: primaryGold)),
          iconTheme: IconThemeData(color: primaryGold),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showWebView = false;
                  _checkoutUrl = null;
                });
              },
              child: Text('Cancel', style: TextStyle(color: primaryGold)),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: darkGray,
              child: Column(
                children: [
                  Text(
                    'Complete your payment in the secure checkout below',
                    style: TextStyle(color: white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _verifyPayment,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                    child: _isProcessing
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Verify Payment', style: TextStyle(color: pureBlack)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _webViewController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: lightGray, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  double _getPlanPrice(Map<String, dynamic> plan, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return (plan['price_usd'] ?? 0.0).toDouble();
      case 'EUR':
        return (plan['price_eur'] ?? 0.0).toDouble();
      case 'KES':
      default:
        return (plan['price_kes'] ?? 0.0).toDouble();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}