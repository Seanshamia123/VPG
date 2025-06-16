import 'package:escort/screens/login.dart';
import 'package:escort/style/card_styling.dart';
import 'package:flutter/material.dart';
import 'package:escort/style/app_size.dart'; // Assuming Sizes is defined here

class SignOptions extends StatelessWidget {
  const SignOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Choose your role'),
            const SizedBox(height: 20),
            isMobile
                ? Column(
                    children: [
                      SignUpCard(
                        type: 'user',
                        icon: Icons.person_outline,
                        title: 'Sign up as User',
                      ),
                      const SizedBox(height: Sizes.spaceBtwItems),
                      SignUpCard(
                        type: 'advertiser',
                        icon: Icons.business_center_outlined,
                        title: 'Sign up as Advertiser',
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SignUpCard(
                        type: 'user',
                        icon: Icons.person_outline,
                        title: 'Sign up as User',
                      ),
                      const SizedBox(width: Sizes.spaceBtwItems),
                      SignUpCard(
                        type: 'advertiser',
                        icon: Icons.business_center_outlined,
                        title: 'Sign up as Advertiser',
                      ),
                    ],
                  ),
            const SizedBox(height: Sizes.spaceBtwItems),

            //Go back to Login page button
            ElevatedButton(
              onPressed: () {
                Login();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: Size(Sizes.buttonHeight, double.minPositive),
              ),
              child: const Text('Go back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
