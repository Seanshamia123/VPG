import 'package:escort/features/advertisers/presentation/screens/advertiser_profile.dart';
import 'package:escort/features/advertisers/presentation/screens/checkout.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription.dart';
import 'package:escort/features/messages/presentation/screens/message.dart';
import 'package:escort/features/messages/presentation/screens/chat_screen.dart';
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
import 'package:provider/provider.dart';

// ADDED: Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:escort/services/notification_service.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ADDED: Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[Main] Firebase initialized');
  
  // ADDED: Initialize Notifications
  await NotificationService.initialize(
    onMessageTapped: (data) {
      print('[Main] Notification tapped: $data');
      // Navigation will be handled by the navigatorKey in MaterialApp
    },
  );
  print('[Main] Notification service initialized');
  
  final themeController = ThemeController();
  await themeController.load();
  await LocaleController.load();
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const Escort(),
    ),
  );
}

class Escort extends StatelessWidget {
  const Escort({super.key});

  // ADDED: Global navigator key for notification navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.locale,
          builder: (context, appLocale, __) {
            return MaterialApp(
              title: 'VipGalz',
              debugShowCheckedModeBanner: false,
              themeMode: themeController.mode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              locale: appLocale,
              
              // ADDED: Navigator key for handling notification taps
              navigatorKey: navigatorKey,
              
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                LocaleNamesLocalizationsDelegate(),
              ],
              supportedLocales: kSupportedMaterialLocales,

              initialRoute: '/sign-options',
              routes: {
                '/vipgalz': (context) => VideoSplashScreen(),
                '/sign-options': (context) => const SignOptions(),
                '/login': (context) => const Login(),
                '/sign-up': (context) => const Signup(userType: 'user'),
                '/home': (context) => const HomeScreen(),
                '/advertiser': (context) => const AdvertiserProfile(),
                '/checkout': (context) => const CheckoutPage(),
                '/subscriptions': (context) => const SubscriptionDialog(),
                '/messages': (context) => const Message(),
              },
              
              // ADDED: Handle notification navigation
              onGenerateRoute: (settings) {
                // Handle deep linking from notifications
                if (settings.name == '/chat') {
                  final args = settings.arguments as Map<String, dynamic>?;
                  if (args != null) {
                    return MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: args['conversation_id'] as int,
                        otherParticipantName: args['sender_name'] as String?,
                        otherParticipantAvatar: args['sender_avatar'] as String?,
                      ),
                    );
                  }
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}

// ADDED: Helper class to handle notification navigation
class NotificationNavigationHelper {
  /// Navigate to chat screen from notification
  static void navigateToChat({
    required int conversationId,
    String? senderName,
    String? senderAvatar,
  }) {
    final context = Escort.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherParticipantName: senderName,
            otherParticipantAvatar: senderAvatar,
          ),
        ),
      );
    } else {
      print('[NotificationNav] Context not available yet');
    }
  }
  
  /// Handle notification tap data
  static void handleNotificationTap(Map<String, dynamic> data) {
    print('[NotificationNav] Handling notification tap: $data');
    
    try {
      final type = data['type']?.toString();
      
      if (type == 'new_message') {
        final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');
        final senderName = data['sender_name']?.toString();
        final senderAvatar = data['sender_avatar']?.toString();
        
        if (conversationId != null) {
          // Wait a bit for app to be ready
          Future.delayed(const Duration(milliseconds: 500), () {
            navigateToChat(
              conversationId: conversationId,
              senderName: senderName,
              senderAvatar: senderAvatar,
            );
          });
        } else {
          print('[NotificationNav] Invalid conversation ID');
        }
      }
    } catch (e) {
      print('[NotificationNav] Error handling notification: $e');
    }
  }
}

// Update the notification service initialization in main():
// Change the onMessageTapped callback to use the helper:
/*
await NotificationService.initialize(
  onMessageTapped: NotificationNavigationHelper.handleNotificationTap,
);
*/

class SignUp {
  const SignUp();
}