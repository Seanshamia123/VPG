import 'package:escort/features/advertisers/presentation/screens/advertiser_profile.dart';
import 'package:escort/features/advertisers/presentation/screens/checkout.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription.dart';
import 'package:escort/features/messages/presentation/screens/message.dart';
import 'package:escort/features/app/presentation/screens/splash_screen.dart';
import 'package:escort/theme/app_theme.dart';
import 'package:escort/features/auth/presentation/screens/signupoptions.dart';
import 'package:escort/features/auth/presentation/screens/login.dart';
import 'package:escort/features/auth/presentation/screens/signup.dart';
import 'package:escort/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:escort/l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:escort/localization/supported_locales.dart';
import 'package:escort/theme/theme_controller.dart';
import 'package:escort/localization/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  await LocaleController.load();
  runApp(const Escort());
}

class Escort extends StatelessWidget {
  const Escort({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.locale,
          builder: (context, appLocale, __) {
            return MaterialApp(
              title: 'VipGalz',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              locale: appLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                LocaleNamesLocalizationsDelegate(),
              ],
              // Broad set of locales (Europe, Asia, global) supported by Material.
              supportedLocales: kSupportedMaterialLocales,

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
      },
    );
  }
}

class SignUp {
  const SignUp();
}
