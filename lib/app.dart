import 'package:escort/features/advertisers/presentation/screens/checkout.dart';
import 'package:escort/theme/app_theme.dart';
import 'package:escort/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return GetMaterialApp(
          themeMode: themeController.mode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: CheckoutPage(),
        );
      },
    );
  }
}
