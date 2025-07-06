import 'package:escort/theme/app_theme.dart';
import 'package:escort/screens/sign_options.dart';
import 'package:escort/screens/login.dart';
import 'package:escort/screens/sign_up.dart';
import 'package:escort/screens/home_screen.dart';
import 'package:escort/screens/profile_screen.dart';
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
        '/sign-options': (context) => const SignOptions(),
        '/login': (context) => const Login(),
        '/sign-up': (context) => const Signup(type: 'user',),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class SignUp {
  const SignUp();
}