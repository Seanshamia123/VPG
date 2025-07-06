import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/login.dart';
import 'package:escort/style/app_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

//sign-up page
class Signup extends StatelessWidget {
  const Signup({super.key, required String type});

  @override
  Widget build(BuildContext context) {
    final insets = context.insets;
    final textStyle = context.textStyle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Get.back()),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(insets.padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isDesktop
                    ? 400
                    : StyleContext(context).isTablet
                    ? 600
                    : context.screenWidth * 0.9,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //title
                  Text("Sign Up", style: textStyle.titleLgBold),
                  const SizedBox(height: Sizes.spaceBtwItems),
                  //Form
                  Form(
                    child: Column(
                      children: [
                        //Prefferd username
                        TextFormField(
                          expands: false,
                          decoration: InputDecoration(
                            labelText: "Username",
                            prefixIcon: Icon(Iconsax.user_edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Sizes.spaceBtwinputFields),
                        //Email
                        TextFormField(
                          expands: false,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Iconsax.user_edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Sizes.spaceBtwinputFields),
                        //password
                        TextFormField(
                          expands: false,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                            prefixIcon: Icon(Iconsax.password_check),
                            suffixIcon: Icon(Iconsax.eye_slash),
                          ),
                        ),
                        const SizedBox(height: Sizes.spaceBtwSections),
                        //Terms&Conditions checkox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: true,
                                onChanged: (value) {},
                              ),
                            ),
                            const SizedBox(width: Sizes.spaceBtwItems),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "I Agree To ",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  TextSpan(
                                    text: "Privacy Policy ",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  TextSpan(
                                    text: "and",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  TextSpan(
                                    text: " Terms of Use",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.spaceBtwItems),
                        //Sign up Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Get.to(() => const Login()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              minimumSize: Size(
                                double.infinity,
                                Sizes.buttonHeight,
                              ),
                            ),
                            child: const Text("Sign Up"),
                          ),
                        ),
                      ],
                    ),
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
