import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/shared%20screens/signupoptions.dart';
import 'package:flutter/material.dart';
import 'package:escort/styles/app_size.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Color palette - Black & Bright Gold
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final insets = context.insets;
    final textStyle = context.textStyle;

    return Scaffold(
      backgroundColor: pureBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkCharcoal,
              pureBlack,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(insets.padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: StyleContext(context).isTablet
                      ? 600
                      : StyleContext(context).isDesktop
                      ? 400
                      : context.screenWidth * 0.9,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                     Text(
                      'VPG',
                      style: GoogleFonts.cormorantGaramond(
                        color: primaryGold,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Sizes.sm),
                    // Subtitle
                    Text(
                      'Enjoyable Time',
                      style: textStyle.bodyLgMedium.copyWith(
                        color: lightGray,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Sizes.lg),
                    // Username Field
                    TextFormField(
                      style: TextStyle(color: white),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: lightGray),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold, width: 2),
                        ),
                        prefixIcon: Icon(
                          Iconsax.direct_right,
                          color: primaryGold,
                        ),
                        filled: true,
                        fillColor: darkGray,
                      ),
                    ),
                    SizedBox(height: Sizes.md),
                    // Password Field
                    TextFormField(
                      style: TextStyle(color: white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: lightGray),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Sizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(color: primaryGold, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                            color: primaryGold,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        prefixIcon: Icon(
                          Iconsax.password_check,
                          color: primaryGold,
                        ),
                        filled: true,
                        fillColor: darkGray,
                      ),
                      obscureText: _obscurePassword,
                    ),
                    SizedBox(height: Sizes.lg),
                    // Remember me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return primaryGold;
                                  }
                                  return Colors.transparent;
                                },
                              ),
                              checkColor: pureBlack,
                              side: BorderSide(color: primaryGold),
                            ),
                            Text(
                              "Remember Me",
                              style: TextStyle(color: white),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot Password",
                            style: TextStyle(color: primaryGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sizes.spaceBtwSections),
                    // Login Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: pureBlack,
                        minimumSize: Size(double.infinity, Sizes.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return darkGold;
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return accentGold;
                            }
                            return primaryGold;
                          },
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: pureBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: Sizes.spaceBtwSections),
                    // Sign up button when clicked takes you to option cards to choose from
                    ElevatedButton(
                      onPressed: () => Get.to(SignOptions()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: primaryGold,
                        minimumSize: Size(double.infinity, Sizes.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: primaryGold, width: 2),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return primaryGold.withOpacity(0.1);
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return primaryGold.withOpacity(0.05);
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}