// Enhanced signup.dart with integrated subscription flow
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription_plans_page.dart';
import 'package:escort/features/auth/presentation/screens/login.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class Signup extends StatefulWidget {
  final String userType; // 'user' or 'advertiser'

  const Signup({super.key, required this.userType});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  // Match login page aesthetic
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color accentGold = Color(0xFFFFA500);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showErrorSnackBar('Please agree to the Terms and Conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('=== FORM DATA ===');
    print('User Type: ${widget.userType}');
    print('Username: ${_usernameController.text.trim()}');
    print('Email: ${_emailController.text.trim()}');
    print('==================');

    try {
      Map<String, dynamic> result;

      if (widget.userType == 'user') {
        result = await AuthService.registerUser(
          username: _usernameController.text.trim(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          gender: _selectedGender,
        );
      } else {
        result = await AuthService.registerAdvertiser(
          username: _usernameController.text.trim(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          gender: _selectedGender,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        );
      }

      print('=== SIGNUP RESULT DEBUG ===');
      print('Result: $result');
      print('==========================');

      bool isSuccess = _determineSuccess(result);
      print('Final success determination: $isSuccess');

      if (isSuccess) {
        _showSuccessSnackBar(
          widget.userType == 'advertiser'
              ? 'Account created! Please choose a subscription plan.'
              : 'Account created successfully! Welcome to VipGalz!',
        );

        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          if (widget.userType == 'advertiser') {
            // For advertisers, navigate to subscription plans with pending login credentials
            print('Navigating to subscription plans for advertiser...');

            final userId = result['user_id'] ?? result['data']?['user_id'];

            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => SubscriptionPlansPage(
                    userId: userId,
                    pendingLoginEmail: _emailController.text.trim(),
                    pendingLoginPassword: _passwordController.text,
                    pendingLoginUserType: 'advertiser',
                    onSubscriptionComplete: () {
                      // After successful subscription, navigate to login
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const Login()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                (route) => false,
              );
            }
          } else {
            // For regular users, go directly to login
            print('Navigating to login screen for user...');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Login()),
              (route) => false,
            );
          }
        }
      } else {
        String errorMessage = _extractErrorMessage(result);
        print('Registration failed: $errorMessage');
        _showErrorSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== EXCEPTION DURING SIGNUP ===');
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      print('===============================');

      _showErrorSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _determineSuccess(Map<String, dynamic> result) {
    // Check for explicit success indicators
    if (result.containsKey('success')) {
      var success = result['success'];
      if (success is bool) return success;
      if (success is String) return success.toLowerCase() == 'true';
    }

    // Check status field
    if (result.containsKey('status')) {
      String status = result['status'].toString().toLowerCase();
      if (status == 'success' || status == 'ok') return true;
    }

    // Check HTTP status codes
    if (result.containsKey('statusCode')) {
      int statusCode = result['statusCode'];
      if (statusCode >= 200 && statusCode < 300) return true;
    }

    // Check for presence of tokens or user data
    if (result.containsKey('data') && result['data'] != null) {
      final data = result['data'];
      if (data is Map) {
        if (data.containsKey('access_token') ||
            data.containsKey('user_id') ||
            data.containsKey('token')) {
          return true;
        }
      }
    }

    // Check message for success indicators
    if (result.containsKey('message')) {
      String message = result['message'].toString().toLowerCase();
      if (message.contains('success') ||
          message.contains('created') ||
          message.contains('registered') ||
          message.contains('welcome')) {
        return true;
      }
    }

    // If no explicit error and we have some data, assume success
    if (!result.containsKey('error') &&
        !result.containsKey('errors') &&
        result.isNotEmpty) {
      return true;
    }

    return false;
  }

  String _extractErrorMessage(Map<String, dynamic> result) {
    String errorMessage = 'Registration failed';

    if (result.containsKey('message')) {
      errorMessage = result['message'].toString();
    } else if (result.containsKey('error')) {
      var error = result['error'];
      if (error is String) {
        errorMessage = error;
      } else if (error is Map && error.containsKey('message')) {
        errorMessage = error['message'].toString();
      }
    } else if (result.containsKey('errors')) {
      var errors = result['errors'];
      if (errors is String) {
        errorMessage = errors;
      } else if (errors is List && errors.isNotEmpty) {
        errorMessage = errors.first.toString();
      } else if (errors is Map) {
        List<String> errorList = [];
        errors.forEach((key, value) {
          if (value is List) {
            errorList.addAll(value.map((e) => e.toString()));
          } else {
            errorList.add(value.toString());
          }
        });
        if (errorList.isNotEmpty) {
          errorMessage = errorList.join(', ');
        }
      }
    }

    if (result.containsKey('statusCode')) {
      errorMessage += ' (Status: ${result['statusCode']})';
    }

    return errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final insets = context.insets;
    final textStyle = context.textStyle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: pureBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkCharcoal, pureBlack],
          ),
        ),
        child: Center(
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
                    // Title
                    Text(
                      "Create ${widget.userType.capitalize} Account",
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Sizes.spaceBtwItems),

                    // Form
                    Container(
                      decoration: BoxDecoration(
                        color: darkGray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryGold.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: darkGray,
                            hintStyle: const TextStyle(color: Colors.white70),
                            labelStyle: TextStyle(
                              color: lightGray.withOpacity(0.9),
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIconColor: primaryGold,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: BorderSide(
                                color: primaryGold.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: const BorderSide(
                                color: primaryGold,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Sizes.inputFieldRadius,
                              ),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Username
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: white),
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter username',
                                  prefixIcon: Icon(Iconsax.user_edit),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Full Name
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: white),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'Enter your full name',
                                  prefixIcon: Icon(Iconsax.user),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Iconsax.sms),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!GetUtils.isEmail(value.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Phone Number
                              TextFormField(
                                controller: _phoneController,
                                style: const TextStyle(color: white),
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'Enter phone number',
                                  prefixIcon: Icon(Iconsax.call),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Location
                              TextFormField(
                                controller: _locationController,
                                style: const TextStyle(color: white),
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  hintText: 'City, Country',
                                  prefixIcon: Icon(Iconsax.location),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Location is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Gender Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                style: const TextStyle(color: white),
                                decoration: InputDecoration(
                                  labelText: "Gender",
                                  prefixIcon: const Icon(Iconsax.user_tag),
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
                                items: ['Male', 'Female', 'other'].map((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedGender = newValue!;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a gender';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwinputFields),

                              // Bio field (only for advertisers)
                              if (widget.userType == 'advertiser') ...[
                                TextFormField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  style: const TextStyle(color: white),
                                  decoration: const InputDecoration(
                                    labelText: 'Bio (Optional)',
                                    hintText: 'Tell us about yourself',
                                    prefixIcon: Icon(Iconsax.note_text),
                                  ),
                                ),
                                const SizedBox(
                                  height: Sizes.spaceBtwinputFields,
                                ),
                              ],

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: white),
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Create password',
                                  prefixIcon: const Icon(
                                    Iconsax.password_check,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Iconsax.eye
                                          : Iconsax.eye_slash,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sizes.spaceBtwSections),

                              // Terms & Conditions checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: Sizes.spaceBtwItems),
                                  Expanded(
                                    child: Text.rich(
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                          TextSpan(
                                            text: "and",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          TextSpan(
                                            text: " Terms of Use",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Sizes.spaceBtwItems),

                              // Sign up Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    minimumSize: const Size(
                                      double.infinity,
                                      Sizes.buttonHeight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Sizes.inputFieldRadius,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text("Sign Up"),
                                ),
                              ),

                              const SizedBox(height: Sizes.spaceBtwItems),

                              // Already have account link
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const Login(),
                                  ),
                                ),
                                child: const Text(
                                  "Already have an account? Sign In",
                                  style: TextStyle(color: primaryGold),
                                ),
                              ),
                            ],
                          ),
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

/// Feature: Auth
/// Screen: Signup