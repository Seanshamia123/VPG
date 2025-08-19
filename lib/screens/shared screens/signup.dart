// signup.dart
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/shared%20screens/login.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/services/auth_service.dart'; // Import the auth service
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
  final _bioController = TextEditingController(); // Only for advertisers
  
  String _selectedGender = 'Male';
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

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

Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      Get.snackbar(
        'Error',
        'Please agree to the Terms and Conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Debug: Print form data before sending
    print('=== FORM DATA ===');
    print('User Type: ${widget.userType}');
    print('Username: ${_usernameController.text.trim()}');
    print('Name: ${_nameController.text.trim()}');
    print('Email: ${_emailController.text.trim()}');
    print('Phone: ${_phoneController.text.trim()}');
    print('Location: ${_locationController.text.trim()}');
    print('Gender: $_selectedGender');
    if (widget.userType == 'advertiser') {
      print('Bio: ${_bioController.text.trim()}');
    }
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
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        );
      }

      // Debug: Print the result
      print('=== SIGNUP RESULT ===');
      print('Success: ${result['success']}');
      print('Full result: $result');
      print('=====================');

      if (result['success']) {
        // Store tokens and user info (implement secure storage)
        final data = result['data'];
        
        // Safely extract data with null checks
        String? accessToken = data['access_token'];
        String? refreshToken = data['refresh_token'];
        dynamic userId = data['user_id'];
        String? userType = data['user_type'];
        
        print('=== TOKEN EXTRACTION ===');
        print('Access Token: ${accessToken != null ? 'Present (${accessToken.length} chars)' : 'Missing'}');
        print('Refresh Token: ${refreshToken != null ? 'Present (${refreshToken.length} chars)' : 'Missing'}');
        print('User ID: $userId');
        print('User Type: $userType');
        print('========================');
        
        // TODO: Store tokens securely using SharedPreferences or FlutterSecureStorage
        // await _storeTokens(accessToken, refreshToken, userId, userType);
        
        Get.snackbar(
          'Success',
          'Account created successfully! Welcome to VipGalz!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Navigate to appropriate screen based on user type
        if (userType == 'user') {
          // Navigate to user dashboard/home
          // Get.offAll(() => const UserDashboard());
          Get.offAll(() => const Login()); // Temporary - replace with user dashboard
        } else {
          // Navigate to advertiser dashboard
          // Get.offAll(() => const AdvertiserDashboard());
          Get.offAll(() => const Login()); // Temporary - replace with advertiser dashboard
        }
        
      } else {
        // Enhanced error display
        String errorMessage = result['message'] ?? 'Registration failed';
        int? statusCode = result['statusCode'];
        
        if (statusCode != null) {
          errorMessage += ' (Status: $statusCode)';
        }
        
        print('Registration failed: $errorMessage');
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('=== EXCEPTION DURING SIGNUP ===');
      print('Exception: $e');
      print('Exception type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      print('===============================');
      
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again. Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final insets = context.insets;
    final textStyle = context.textStyle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up as ${widget.userType.capitalize}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
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
                  // Title
                  Text(
                    "Create ${widget.userType.capitalize} Account",
                    style: textStyle.titleLgBold,
                  ),
                  const SizedBox(height: Sizes.spaceBtwItems),
                  
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            prefixIcon: const Icon(Iconsax.user_edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
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
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: const Icon(Iconsax.user),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
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
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Iconsax.sms),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
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
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            prefixIcon: const Icon(Iconsax.call),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
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
                          decoration: InputDecoration(
                            labelText: "Location",
                            prefixIcon: const Icon(Iconsax.location),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
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
                          decoration: InputDecoration(
                            labelText: "Gender",
                            prefixIcon: const Icon(Iconsax.user_tag),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          items: ['Male', 'Female', 'other'].map((String value) {
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
                            decoration: InputDecoration(
                              labelText: "Bio (Optional)",
                              prefixIcon: const Icon(Iconsax.note_text),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                                borderSide: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: Sizes.spaceBtwinputFields),
                        ],
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Iconsax.password_check),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Iconsax.eye : Iconsax.eye_slash,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              borderSide: BorderSide(color: colorScheme.primary),
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
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    TextSpan(
                                      text: "Privacy Policy ",
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "and",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    TextSpan(
                                      text: " Terms of Use",
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
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
                              minimumSize: const Size(double.infinity, Sizes.buttonHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text("Sign Up"),
                          ),
                        ),
                        
                        const SizedBox(height: Sizes.spaceBtwItems),
                        
                        // Already have account link
                        TextButton(
                          onPressed: () => Get.to(() => const Login()),
                          child: Text(
                            "Already have an account? Sign In",
                            style: TextStyle(color: colorScheme.primary),
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
