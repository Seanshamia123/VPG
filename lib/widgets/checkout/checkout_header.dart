import 'package:escort/constants/checkout_colors.dart';
import 'package:flutter/material.dart';

class CheckoutHeader extends StatelessWidget {
  const CheckoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CheckoutColors.primary600, CheckoutColors.primary700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_checkout, size: 32, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Secure Checkout',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Complete your purchase securely',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              color: CheckoutColors.primary100,
            ),
          ),
        ],
      ),
    );
  }
}
