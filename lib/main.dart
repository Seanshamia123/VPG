import 'package:escort/screens/advertisers screens/advertiser_profile.dart';
import 'package:escort/screens/advertisers screens/checkout.dart';
import 'package:escort/screens/advertisers screens/subscription.dart';
import 'package:escort/screens/shared screens/message.dart';
import 'package:escort/screens/splash_screen.dart';
import 'package:escort/theme/app_theme.dart';
import 'package:escort/screens/shared screens/signupoptions.dart';
import 'package:escort/screens/shared screens/login.dart';
import 'package:escort/screens/shared screens/signup.dart';
import 'package:escort/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Escort());
}

class Escort extends StatelessWidget {
  const Escort({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipGalz',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Start with SignOptions instead of HomeScreen
      initialRoute: '/sign-options',
      routes: {
        '/vipgalz': (context) => VideoSplashScreen(),
        '/sign-options': (context) => const SignOptions(),
        '/login': (context) => const Login(),
        '/sign-up': (context) => const Signup(
              type: 'user',
            ),
        '/home': (context) => const HomeScreen(),
        // '/profile': (context) => const ProfileScreen(),
        '/advertiser': (context) => const AdvertiserProfile(),
        '/checkout': (context) => const CheckoutPage(),
        '/subscriptions': (context) => const SubscriptionDialog(),
        '/messages': (context) => const Message(),
      },
    );
  }
}

class SignUp {
  const SignUp();
}
