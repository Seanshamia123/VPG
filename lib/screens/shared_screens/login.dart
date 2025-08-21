import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/shared_screens/signupoptions.dart';
import 'package:escort/screens/advertisers screens/advertiser_profile.dart';
import 'package:escort/services/auth_service.dart';
import 'package:escort/screens/home_screen.dart';
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

    // Debug: Print login data
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

      // Enhanced debugging
      print('=== LOGIN RESULT DEBUG ===');
      print('Result Type: ${result.runtimeType}');
      print('Result Keys: ${result.keys.toList()}');
      print('Full result: $result');
      print('==========================');

      // Check for successful login
      bool isSuccess = _determineLoginSuccess(result);
      print('Login success determination: $isSuccess');

      if (isSuccess) {
        // Handle successful login
        _handleSuccessfulLogin(result);
        
        // Show success message
        _showSuccessSnackBar('Login successful! Welcome back!');
        
        // Wait a bit to show the success message
        await Future.delayed(const Duration(milliseconds: 1000));

        // Navigate to appropriate dashboard based on user type
        if (mounted) {
          String userType = result['user_type'] ?? _selectedUserType;
          print('Navigating to dashboard for user type: $userType');
          
          // TODO: Replace these with your actual dashboard routes
          if (userType == 'advertiser') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdvertiserProfile()),
              (route) => false,
            );
            print('Should navigate to Advertiser Dashboard');
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
            print('Should navigate to User Dashboard');
          }
        }
        
      } else {
        // Handle login failure
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
    
    // Check HTTP status codes
    if (result.containsKey('statusCode')) {
      int statusCode = result['statusCode'];
      if (statusCode >= 200 && statusCode < 300) return true;
    }
    
    // Check for presence of access token (most reliable indicator)
    if (result.containsKey('access_token') && result['access_token'] != null) {
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
        result.isNotEmpty) {
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

  void _handleSuccessfulLogin(Map<String, dynamic> result) {
    // Extract user data and tokens
    String? accessToken = result['access_token'];
    String? refreshToken = result['refresh_token'];
    dynamic userId = result['user_id'];
    String? userType = result['user_type'];
    
    print('=== SUCCESSFUL LOGIN DATA ===');
    print('Access Token: ${accessToken != null ? 'Present (${accessToken.length} chars)' : 'Missing'}');
    print('Refresh Token: ${refreshToken != null ? 'Present (${refreshToken.length} chars)' : 'Missing'}');
    print('User ID: $userId');
    print('User Type: $userType');
    print('==============================');
    
    // TODO: Store tokens securely using SharedPreferences or FlutterSecureStorage
    // await _storeUserSession(accessToken, refreshToken, userId, userType);
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
                          borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                          border: Border.all(color: primaryGold.withOpacity(0.5)),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedUserType == 'user' 
                                        ? primaryGold 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedUserType == 'advertiser' 
                                        ? primaryGold 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
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
                        style: TextStyle(color: white),
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Sizes.inputFieldRadius,
                            ),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          prefixIcon: Icon(
                            Iconsax.sms,
                            color: primaryGold,
                          ),
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Sizes.inputFieldRadius,
                            ),
                            borderSide: BorderSide(color: Colors.red),
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
                            onPressed: () {
                              // TODO: Implement forgot password functionality
                              _showErrorSnackBar('Forgot password feature coming soon!');
                            },
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
                        onPressed: _isLoading ? null : _handleLogin,
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
                            },
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(pureBlack),
                                ),
                              )
                            : Text(
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
                        onPressed: _isLoading ? null : () => Get.to(SignOptions()),
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
                            },
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLoading ? primaryGold.withOpacity(0.6) : primaryGold,
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