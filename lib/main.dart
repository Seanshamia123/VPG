import 'package:escort/screens/advertisers_screens/advertiser_profile.dart';
import 'package:escort/screens/advertisers_screens/checkout.dart';
import 'package:escort/screens/advertisers_screens/subscription.dart';
import 'package:escort/screens/shared_screens/message.dart';
import 'package:escort/screens/splash_screen.dart';
import 'package:escort/theme/app_theme.dart';
import 'package:escort/screens/shared_screens/signupoptions.dart';
import 'package:escort/screens/shared_screens/login.dart';
import 'package:escort/screens/shared_screens/signup.dart';
import 'package:escort/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:escort/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const Escort());
}

class Escort extends StatelessWidget {
  const Escort({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'VipGalz',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          // Start with SignOptions instead of HomeScreen
          initialRoute: '/sign-options',
          routes: {
            '/vipgalz': (context) => VideoSplashScreen(),
            '/sign-options': (context) => const SignOptions(),
            '/login': (context) => const Login(),
            '/sign-up': (context) => const Signup(userType: 'user'),
            '/home': (context) => const HomeScreen(),
            // '/profile': (context) => const ProfileScreen(),
            '/advertiser': (context) => const AdvertiserProfile(),
            '/checkout': (context) => const CheckoutPage(),
            '/subscriptions': (context) => const SubscriptionDialog(),
            '/messages': (context) => const Message(),
          },
        );
      },
    );
  }
}

class SignUp {
  const SignUp();
}
