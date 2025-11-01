import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription_plans_page.dart';
import 'package:escort/features/auth/presentation/screens/signupoptions.dart';
import 'package:escort/features/advertisers/presentation/screens/advertiser_profile.dart';
import 'package:escort/services/auth_service.dart';
import 'package:escort/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:escort/styles/app_size.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:escort/services/user_session.dart';

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

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedUserType = 'user'; // Default to user

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('=== LOGIN ATTEMPT ===');
    print('Email: ${_emailController.text.trim()}');
    print('User Type: $_selectedUserType');
    print('====================');

    try {
      Map<String, dynamic> result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: _selectedUserType,
      );

      print('=== LOGIN RESULT DEBUG ===');
      print('Result Type: ${result.runtimeType}');
      print('Result Keys: ${result.keys.toList()}');
      print('Full result: $result');
      print('==========================');

      // Check for subscription requirement (for advertisers)
      if (result.containsKey('subscription_required') &&
          result['subscription_required'] == true) {
        print('Subscription required for advertiser');

        String errorMessage = result['error'] ??
            result['message'] ??
            'Active subscription required to access advertiser account';

        // Show subscription required dialog with credentials
        if (mounted) {
          _showSubscriptionRequiredDialog(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            userId: result['user_id'],
            currentStatus: result['subscription_status'] ?? 'No subscription',
          );
        }
        return;
      }

      // Check for successful login
      bool isSuccess = _determineLoginSuccess(result);
      print('Login success determination: $isSuccess');

      if (isSuccess) {
        await _handleSuccessfulLogin(result);
        _showSuccessSnackBar('Login successful! Welcome back!');
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          String userType = result['user_type'] ?? _selectedUserType;
          print('Navigating to dashboard for user type: $userType');

          if (userType == 'advertiser') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const AdvertiserProfile(),
              ),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        String errorMessage = _extractErrorMessage(result);
        print('Login failed: $errorMessage');
        _showErrorSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== EXCEPTION DURING LOGIN ===');
      print('Exception: $e');
      print('Exception type: ${e.runtimeType}');
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

  void _showSubscriptionRequiredDialog({
    required String email,
    required String password,
    dynamic userId,
    required String currentStatus,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryGold.withOpacity(0.5)),
          ),
          title: Row(
            children: [
              Icon(Iconsax.warning_2, color: primaryGold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Subscription Required',
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your advertiser account requires an active subscription to access all features.',
                style: TextStyle(
                  color: white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current status: $currentStatus',
                style: TextStyle(
                  color: lightGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Back',
                style: TextStyle(color: lightGray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // CRITICAL FIX: Pass credentials to subscription page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionPlansPage(
                      onSubscriptionComplete: () async {
                        // After subscription completes, attempt login again
                        print('=== POST-SUBSCRIPTION LOGIN ===');
                        await _retryLoginAfterSubscription(email, password);
                      },
                      userId: userId,
                      // PASS CREDENTIALS FOR PAYMENT FLOW
                      pendingLoginEmail: email,
                      pendingLoginPassword: password,
                      pendingLoginUserType: _selectedUserType,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: pureBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryLoginAfterSubscription(
      String email, String password) async {
    print('=== RETRYING LOGIN AFTER SUBSCRIPTION ===');
    print('Email: $email');
    print('User Type: $_selectedUserType');

    setState(() {
      _isLoading = true;
    });

    try {
      // Retry login with credentials
      Map<String, dynamic> result = await AuthService.login(
        email: email,
        password: password,
        userType: _selectedUserType,
      );

      print('=== POST-SUBSCRIPTION LOGIN RESULT ===');
      print(
        'Access Token: ${result.containsKey('access_token') ? "Present" : "Missing"}',
      );
      print('Subscription Required: ${result['subscription_required']}');
      print('Status Code: ${result['statusCode']}');
      print('======================================');

      // Check again if subscription is still required
      if (result.containsKey('subscription_required') &&
          result['subscription_required'] == true) {
        _showErrorSnackBar(
          'Subscription is still processing. Please try again in a moment.',
        );
        return;
      }

      bool isSuccess = _determineLoginSuccess(result);

      if (isSuccess) {
        // Save session with new tokens
        await _handleSuccessfulLogin(result);

        _showSuccessSnackBar(
          'Subscription activated! Welcome to VipGalz Advertiser!',
        );
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Navigate to advertiser profile
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdvertiserProfile(),
            ),
            (route) => false,
          );
        }
      } else {
        String errorMessage = _extractErrorMessage(result);
        _showErrorSnackBar('Login after subscription failed: $errorMessage');
        print('Post-subscription login failed: $errorMessage');
      }
    } catch (e) {
      print('=== EXCEPTION IN POST-SUBSCRIPTION LOGIN ===');
      print('Exception: $e');
      _showErrorSnackBar(
        'Unable to complete login. Please try manually logging in.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _determineLoginSuccess(Map<String, dynamic> result) {
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

    // Check HTTP status codes (200-299 are success)
    if (result.containsKey('statusCode')) {
      int statusCode = result['statusCode'];
      if (statusCode >= 200 && statusCode < 300) return true;
    }

    // Check for presence of access token (most reliable indicator)
    if (result.containsKey('access_token') &&
        result['access_token'] != null &&
        result['access_token'].isNotEmpty) {
      return true;
    }

    // Check for nested data with tokens
    if (result.containsKey('data') && result['data'] != null) {
      final data = result['data'];
      if (data is Map && data.containsKey('access_token')) {
        return true;
      }
    }

    // If no explicit error and we have some meaningful data, assume success
    if (!result.containsKey('error') &&
        !result.containsKey('errors') &&
        result.isNotEmpty &&
        result['statusCode'] != 403) {
      return true;
    }

    return false;
  }

  String _extractErrorMessage(Map<String, dynamic> result) {
    String errorMessage = 'Login failed';

    // Check various error fields
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
      }
    }

    // Add status code if available
    if (result.containsKey('statusCode')) {
      errorMessage += ' (Status: ${result['statusCode']})';
    }

    return errorMessage;
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> result) async {
    // Extract user data and tokens
    String? accessToken = result['access_token'];
    String? refreshToken = result['refresh_token'];
    dynamic userId = result['user_id'] ?? result['id'];
    String? userType = result['user_type'] ?? _selectedUserType;

    print('=== SUCCESSFUL LOGIN DATA ===');
    print(
      'Access Token: ${accessToken != null ? 'Present (${accessToken.length} chars)' : 'Missing'}',
    );
    print(
      'Refresh Token: ${refreshToken != null ? 'Present (${refreshToken.length} chars)' : 'Missing'}',
    );
    print('User ID: $userId');
    print('User Type: $userType');
    print('Full Response: $result');
    print('==============================');

    // Prepare basic user data from login response
    Map<String, dynamic> userData = {
      'email': _emailController.text.trim(),
      'user_type': userType ?? _selectedUserType,
      'is_online': true,
    };

    // Add any additional data from login response
    if (userId != null) userData['id'] = userId;
    if (result.containsKey('username')) {
      userData['username'] = result['username'];
    }
    if (result.containsKey('name')) {
      userData['name'] = result['name'];
    }

    try {
      // First, save basic session data
      await UserSession.saveUserSession(
        userData: userData,
        accessToken: accessToken ?? '',
        refreshToken: refreshToken,
        userType: userType ?? _selectedUserType,
      );

      print('Basic user session saved successfully');

      // Now fetch complete profile data
      if (userId != null) {
        Map<String, dynamic>? completeProfile;

        if (userType == 'advertiser') {
          completeProfile = await UserSession.fetchAdvertiserProfile(
            int.parse(userId.toString()),
          );
        } else {
          completeProfile = await UserSession.fetchUserProfile(
            int.parse(userId.toString()),
          );
        }

        if (completeProfile != null) {
          // Merge the complete profile with existing session data
          final mergedData = {...userData, ...completeProfile};

          // Update session with complete profile data
          await UserSession.saveUserSession(
            userData: mergedData,
            accessToken: accessToken ?? '',
            refreshToken: refreshToken,
            userType: userType ?? _selectedUserType,
          );

          print('=== COMPLETE PROFILE SAVED ===');
          print('Complete Profile Data: $mergedData');
          print('==============================');
        } else {
          print('Failed to fetch complete profile, using basic data');
        }
      } else {
        print('No user ID found, cannot fetch complete profile');
      }
    } catch (e) {
      print('Error during profile setup: $e');
    }
  }

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
            colors: [darkCharcoal, pureBlack],
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
                child: Form(
                  key: _formKey,
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

                      // User Type Selection
                      Container(
                        decoration: BoxDecoration(
                          color: darkGray,
                          borderRadius:
                              BorderRadius.circular(Sizes.inputFieldRadius),
                          border: Border.all(
                            color: primaryGold.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUserType = 'user';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedUserType == 'user'
                                        ? primaryGold
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      Sizes.inputFieldRadius,
                                    ),
                                  ),
                                  child: Text(
                                    'User',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedUserType == 'user'
                                          ? pureBlack
                                          : white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUserType = 'advertiser';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedUserType == 'advertiser'
                                        ? primaryGold
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      Sizes.inputFieldRadius,
                                    ),
                                  ),
                                  child: Text(
                                    'Advertiser',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedUserType == 'advertiser'
                                          ? pureBlack
                                          : white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Sizes.md),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(color: primaryGold),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: BorderSide(
                              color: primaryGold.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(
                              color: primaryGold,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          prefixIcon: const Icon(Iconsax.sms, color: primaryGold),
                          filled: true,
                          fillColor: darkGray,
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
                      SizedBox(height: Sizes.md),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(color: primaryGold),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: BorderSide(
                              color: primaryGold.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(
                              color: primaryGold,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Sizes.inputFieldRadius),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              color: primaryGold,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          prefixIcon: const Icon(
                            Iconsax.password_check,
                            color: primaryGold,
                          ),
                          filled: true,
                          fillColor: darkGray,
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
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
                                fillColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return primaryGold;
                                  }
                                  return Colors.transparent;
                                }),
                                checkColor: pureBlack,
                                side: const BorderSide(color: primaryGold),
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(color: white),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _showErrorSnackBar(
                                'Forgot password feature coming soon!',
                              );
                            },
                            child: const Text(
                              "Forgot Password",
                              style: TextStyle(color: primaryGold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.spaceBtwSections),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGold,
                          foregroundColor: pureBlack,
                          minimumSize:
                              const Size(double.infinity, Sizes.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.disabled)) {
                              return primaryGold.withOpacity(0.6);
                            }
                            if (states.contains(WidgetState.pressed)) {
                              return darkGold;
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return accentGold;
                            }
                            return primaryGold;
                          }),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    pureBlack,
                                  ),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: pureBlack,
                                ),
                              ),
                      ),
                      const SizedBox(height: Sizes.spaceBtwSections),

                      // Sign up - go to card chooser (SignOptions)
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignOptions(),
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: primaryGold,
                          minimumSize:
                              const Size(double.infinity, Sizes.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                const BorderSide(color: primaryGold, width: 2),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.disabled)) {
                              return Colors.transparent;
                            }
                            if (states.contains(WidgetState.pressed)) {
                              return primaryGold.withOpacity(0.1);
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return primaryGold.withOpacity(0.05);
                            }
                            return Colors.transparent;
                          }),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLoading
                                ? primaryGold.withOpacity(0.6)
                                : primaryGold,
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
      ),
    );
  }
}