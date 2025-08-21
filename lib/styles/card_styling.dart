import 'package:escort/screens/advertisers%20screens/subscription.dart';
import 'package:escort/screens/shared_screens/signup.dart';
import 'package:escort/styles/textstyle.dart';
import 'package:flutter/material.dart';

class SignUpCard extends StatelessWidget {
  final String type;
  final String title;
  final Icon icon;

  const SignUpCard({
    super.key,
    required this.type,
    required this.title,
    required this.icon,
    required Function() onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Use responsive insets
    final textStyle = getTextStyle(context); // Use responsive text styles
    final colorScheme = Theme.of(context).colorScheme;

    final cardWidth = isMobile ? screenWidth * 0.9 : screenWidth * 0.2;
    final cardHeight = isMobile ? 120.0 : 250.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (type == 'advertiser') {
              showDialog(
                context: context,
                builder: (context) => const SubscriptionDialog(),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Signup(type: 'user')),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          hoverColor: colorScheme.primary.withOpacity(0.1), // Web hover effect
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              Text(
                title,
                style: isMobile
                    ? textStyle.bodyMdMedium
                    : textStyle.titleMdMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
