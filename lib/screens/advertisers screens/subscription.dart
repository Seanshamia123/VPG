import 'package:escort/constants/subscription_colors.dart';
import 'package:escort/screens/advertisers%20screens/checkout.dart';
import 'package:escort/styles/subscription_cards.dart';
import 'package:flutter/material.dart';

class SubscriptionDialog extends StatelessWidget {
  const SubscriptionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SubscriptionColors.backgroundStart,
              SubscriptionColors.backgroundEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Your Plan',
                      style: SubscriptionColors.titleStyle,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select the perfect subscription for your needs',
                      style: SubscriptionColors.subtitleStyle,
                    ),
                    SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildStarterCard(context)),
                              SizedBox(width: 32),
                              Expanded(child: _buildProfessionalCard(context)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildStarterCard(context),
                              SizedBox(height: 32),
                              _buildProfessionalCard(context),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: 32),
                    Column(
                      children: [
                        Wrap(
                          spacing: 32,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.security,
                                  color: SubscriptionColors.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Secure payments',
                                  style: SubscriptionColors.bodyStyle,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.support_agent,
                                  color: SubscriptionColors.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '24/7 support',
                                  style: SubscriptionColors.bodyStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.black),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildStarterCard(BuildContext context) {
  return SubscriptionCard(
    title: 'Starter',
    price: '\$20',
    description: 'Perfect for individuals getting started',
    features: [
      'Up to 5 projects',
      '10GB storage',
      'Email support',
      'Basic analytics',
      'Mobile app access',
    ],
    buttonText: 'Get Started',
    onButtonPressed: () {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => CheckoutPage()));
    },
  );
}

Widget _buildProfessionalCard(BuildContext context) {
  return SubscriptionCard(
    title: 'Professional',
    price: '\$40',
    description: 'Ideal for growing businesses and teams',
    features: [
      'Unlimited projects',
      '100GB storage',
      'Priority support',
      'Advanced analytics',
      'Team collaboration',
      'API access',
      'Custom integrations',
    ],
    buttonText: 'Get Started',
    isPopular: true,
    onButtonPressed: () {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => CheckoutPage()));
    },
  );
}
