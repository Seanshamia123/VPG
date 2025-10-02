import 'package:escort/constants/checkout_colors.dart';
import 'package:flutter/material.dart';

class CheckoutFooter extends StatelessWidget {
  const CheckoutFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      color: CheckoutColors.gray50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFooterItem(Icons.verified, 'SSL Secured', Colors.green),
          SizedBox(width: 32),
          _buildFooterItem(Icons.shield, 'Data Protected', Colors.blue),
          SizedBox(width: 32),
          _buildFooterItem(Icons.support_agent, '24/7 Support', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
/// Feature: Advertisers
/// Widget: CheckoutFooter
