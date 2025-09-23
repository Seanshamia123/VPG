// lib/services/subscription_service.dart - Updated with IntaSend integration
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class SubscriptionService {
  // Get user's subscriptions
  static Future<List<Map<String, dynamic>>> mySubscriptions() async {
    final url = '${ApiConfig.api}/subscriptions/my';
    final data = await ApiClient.getJson(url, auth: true);
    
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    if (data is Map && data.values.any((v) => v is List)) {
      final firstList = data.values.firstWhere((v) => v is List) as List;
      return firstList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Get active subscription
  static Future<Map<String, dynamic>?> activeSubscription() async {
    final list = await mySubscriptions();
    for (final s in list) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      if (status == 'active') return s;
    }
    return null;
  }

  // Get available subscription plans from IntaSend service
  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final url = '${ApiConfig.api}/payments/plans';
      final data = await ApiClient.getJson(url, auth: true);
      
      if (data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else if (data is List) {
        return (data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return [];
    }
  }

  // Get supported currencies
  static Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      final url = '${ApiConfig.api}/payments/currencies';
      final data = await ApiClient.getJson(url, auth: true);
      
      if (data['currencies'] is List) {
        return (data['currencies'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching currencies: $e');
      // Return default currencies
      return [
        {"code": "KES", "name": "Kenyan Shilling", "symbol": "KSh"},
        {"code": "USD", "name": "US Dollar", "symbol": "\$"},
        {"code": "EUR", "name": "Euro", "symbol": "€"},
      ];
    }
  }

  // Create IntaSend checkout session
  static Future<Map<String, dynamic>> createCheckoutSession({
    required String planId,
    required String currency,
    String? phoneNumber,
    String? redirectUrl,
  }) async {
    try {
      final url = '${ApiConfig.api}/payments/create-checkout';
      final requestBody = {
        'plan_id': planId,
        'currency': currency,
      };

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        requestBody['redirect_url'] = redirectUrl;
      }

      return await ApiClient.postJson(url, requestBody, auth: true);
    } catch (e) {
      print('Error creating checkout session: $e');
      return {'error': 'Failed to create checkout session: $e'};
    }
  }

  // Verify payment with IntaSend
  static Future<Map<String, dynamic>> verifyPayment(String checkoutId) async {
    try {
      final url = '${ApiConfig.api}/payments/verify/$checkoutId';
      return await ApiClient.postJson(url, {}, auth: true);
    } catch (e) {
      print('Error verifying payment: $e');
      return {'error': 'Failed to verify payment: $e'};
    }
  }

  // Legacy method for basic subscription (keep for compatibility)
  static Future<Map<String, dynamic>> subscribeBasic({
    double amount = 20.0,
    String method = 'card'
  }) async {
    final url = '${ApiConfig.api}/subscriptions/subscribe';
    return ApiClient.postJson(url, {
      'amount_paid': amount,
      'payment_method': method,
      'duration_days': 30,
    }, auth: true);
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancel(int subscriptionId) async {
    final url = '${ApiConfig.api}/subscriptions/cancel/$subscriptionId';
    return ApiClient.postJson(url, {}, auth: true);
  }

  // Format phone number for M-Pesa
  static String formatPhoneNumber(String phone) {
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

  // Validate phone number
  static bool isValidKenyanPhone(String phone) {
    final formatted = formatPhoneNumber(phone);
    return formatted.length == 12 && formatted.startsWith('254');
  }
}