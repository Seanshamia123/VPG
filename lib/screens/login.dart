import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/sign_options.dart';
import 'package:flutter/material.dart';
import 'package:escort/style/app_size.dart';
import 'package:iconsax/iconsax.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = context.insets;
    final textStyle = context.textStyle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(insets.padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isDesktop
                    ? 400
                    : context.isTablet
                    ? 600
                    : context.screenWidth * 0.9,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'VPG',
                    style: textStyle.bodyLgBold.copyWith(
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Sizes.sm),
                  // Subtitle
                  Text(
                    'Enjoyable Time',
                    style: textStyle.bodyLgMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Sizes.lg),
                  // Username Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: colorScheme.onSurface),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      prefixIcon: Icon(
                        Iconsax.direct_right,
                        color: colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: Sizes.md),
                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: colorScheme.onSurface),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Sizes.inputFieldRadius,
                        ),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      suffixIcon: Icon(
                        Iconsax.eye_slash,
                        color: colorScheme.primary,
                      ),
                      prefixIcon: Icon(
                        Iconsax.password_check,
                        color: colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: Sizes.lg),
                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (value) {},
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Remember Me",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forgot Password",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.spaceBtwSections),
                  // Login Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: Size(double.infinity, Sizes.buttonHeight),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: Sizes.spaceBtwSections),
                  //Sign up but
                  ElevatedButton(
                    onPressed: () {
                      SignOptions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: Size(double.infinity, Sizes.buttonHeight),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
