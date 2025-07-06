import 'package:escort/constants/subscription_colors.dart';

import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool isPopular;
  final VoidCallback onButtonPressed;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    required this.buttonText,
    this.isPopular = false,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: isPopular
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: SubscriptionColors.primaryColor,
                width: 2,
              ),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SubscriptionColors.cardTitleStyle),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(price, style: SubscriptionColors.priceStyle),
                    SizedBox(width: 8),
                    Text('/month', style: SubscriptionColors.subtitleStyle),
                  ],
                ),
                SizedBox(height: 16),
                Text(description, style: SubscriptionColors.bodyStyle),
                SizedBox(height: 32),
                Column(
                  children: features
                      .map(
                        (feature) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: SubscriptionColors.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: SubscriptionColors.bodyStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SubscriptionColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SubscriptionColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'Most Popular',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
