import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/sign_up.dart';
import 'package:escort/style/app_size.dart';
import 'package:flutter/material.dart';

class SignUpCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final String title;

  const SignUpCard({
    super.key,
    required this.type,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth - 40 : 200.0;
    final cardHeight = isMobile ? 100.0 : 200.0;
    final textStyle = context.textStyle;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Signup(type: type)),
            );
          },
          borderRadius: BorderRadius.circular(Sizes.cardElevation),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: Sizes.sm),
              Text(title, style: textStyle.bodyMdMedium),
            ],
          ),
        ),
      ),
    );
  }
}
