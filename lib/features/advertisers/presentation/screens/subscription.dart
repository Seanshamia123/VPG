// subscription.dart - Complete replacement for your subscription screen
import 'package:flutter/material.dart';
import 'subscription_plans_page.dart';

class SubscriptionDialog extends StatelessWidget {
  final VoidCallback? onSubscriptionComplete;
  final dynamic userId;

  const SubscriptionDialog({
    Key? key,
    this.onSubscriptionComplete,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Just navigate to the subscription plans page
    return SubscriptionPlansPage(
      onSubscriptionComplete: onSubscriptionComplete,
      userId: userId,
    );
  }
}