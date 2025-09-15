import 'package:escort/constants/checkout_colors.dart';

import 'package:flutter/material.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CheckoutColors.gray50,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, size: 24),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // TODO: Replace with the selected subscription plan from subscription.dart
          // Example usage:
          // _buildSubscriptionItem(selectedPlan.title, selectedPlan.price),
          _buildSubscriptionItem('Basic', 20),
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 8),
          _buildSummaryLine('Subtotal', 79.98),
          _buildSummaryLine('Tax', 7.20),
          Divider(),
          _buildSummaryLine('Total', 97.17, isTotal: true),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CheckoutColors.primary600,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'Complete Secure Payment',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, color: Colors.green),
              SizedBox(width: 8),
              Text(
                '256-bit SSL encryption',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Accepted payment methods:',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logos/visa.png', width: 32, height: 24),
              SizedBox(width: 12),
              Image.asset('assets/logos/mastercard.png', width: 32, height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(String title, double price) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          color: Colors.grey[200],
          child: Icon(Icons.inventory_2, color: Colors.grey[500]),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryLine(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
/// Feature: Advertisers
/// Widget: PaymentSummary
