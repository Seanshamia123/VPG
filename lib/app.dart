import 'package:escort/screens/advertisers screens/checkout.dart';
import 'package:escort/theme/app_theme.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode
          .system, //either dark or light according to the device settings
      theme: AppTheme.lightTheme, //lighttheme by default
      darkTheme: AppTheme.darkTheme,
      home: CheckoutPage(),
    );
  }
}
