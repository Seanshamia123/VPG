/// Feature: Advertisers
/// Screen: CheckoutPage
///
/// Checkout flow for subscriptions/purchases.
import 'package:escort/constants/checkout_colors.dart';
import 'package:escort/features/advertisers/presentation/widgets/checkout/checkout_footer.dart';
import 'package:escort/features/advertisers/presentation/widgets/checkout/checkout_header.dart';
import 'package:escort/features/advertisers/presentation/widgets/checkout/payment_info.dart';
import 'package:escort/features/advertisers/presentation/widgets/checkout/payment_summary.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: CheckoutColors.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: isWide ? BoxConstraints(maxWidth: 1200) : null,
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 8,
              vertical: 24,
            ),
            child: Column(
              children: [
                CheckoutHeader(),
                SizedBox(height: 24),
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [PaymentInfo(), SizedBox(height: 32)],
                            ),
                          ),
                          SizedBox(width: 32),
                          Expanded(flex: 1, child: PaymentSummary()),
                        ],
                      )
                    : Column(
                        children: [
                          PaymentInfo(),
                          SizedBox(height: 32),
                          PaymentSummary(),
                        ],
                      ),
                SizedBox(height: 24),
                CheckoutFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
