// lib/services/subscription_service.dart
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class SubscriptionService {
  static Future<List<Map<String, dynamic>>> mySubscriptions() async {
    final url = '${ApiConfig.api}/subscriptions/my';
    final data = await ApiClient.getJson(url, auth: true);
    // Flask-RESTX marshal may return list directly, which ApiClient wraps as {'data': list}
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    if (data is Map && data.values.any((v) => v is List)) {
      final firstList = data.values.firstWhere((v) => v is List) as List;
      return firstList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> activeSubscription() async {
    final list = await mySubscriptions();
    for (final s in list) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      if (status == 'active') return s;
    }
    return null;
  }

  static Future<Map<String, dynamic>> subscribeBasic({double amount = 20.0, String method = 'card'}) async {
    final url = '${ApiConfig.api}/subscriptions/subscribe';
    return ApiClient.postJson(url, {
      'amount_paid': amount,
      'payment_method': method,
      'duration_days': 30,
    }, auth: true);
  }

  static Future<Map<String, dynamic>> cancel(int subscriptionId) async {
    final url = '${ApiConfig.api}/subscriptions/cancel/$subscriptionId';
    return ApiClient.postJson(url, {}, auth: true);
  }
}

