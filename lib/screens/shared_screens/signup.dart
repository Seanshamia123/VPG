// Enhanced signup.dart with Navigator and simplified success handling
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/shared_screens/login.dart';
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

      // Enhanced debugging
      print('=== SIGNUP RESULT DEBUG ===');
      print('Result Type: ${result.runtimeType}');
      print('Result Keys: ${result.keys.toList()}');
      print('Full result: $result');
      print('Success field exists: ${result.containsKey('success')}');
      if (result.containsKey('success')) {
        print('Success value: ${result['success']}');
        print('Success value type: ${result['success'].runtimeType}');
      }
      print('==========================');

      // Simplified success detection
      bool isSuccess = _determineSuccess(result);
      print('Final success determination: $isSuccess');

      if (isSuccess) {
        // Store tokens and user info if available
        _handleSuccessfulRegistration(result);
        
        // Show success message using ScaffoldMessenger
        _showSuccessSnackBar('Account created successfully! Welcome to VipGalz!');
        
        // Wait a bit to show the success message
        await Future.delayed(const Duration(milliseconds: 1000));

        // Navigate to login screen using Navigator
        if (mounted) {
          print('Navigating to login screen using Navigator...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false, // Remove all previous routes
          );
        }
        
      } else {
        // Handle registration failure
        String errorMessage = _extractErrorMessage(result);
        print('Registration failed: $errorMessage');
        _showErrorSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== EXCEPTION DURING SIGNUP ===');
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
      } else if (errors is Map) {
        // Handle validation errors
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
    
    // Add status code if available
    if (result.containsKey('statusCode')) {
      errorMessage += ' (Status: ${result['statusCode']})';
    }
    
    return errorMessage;
  }

  void _handleSuccessfulRegistration(Map<String, dynamic> result) {
    if (result.containsKey('data') && result['data'] != null) {
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
          onPressed: () => Navigator.of(context).pop(),
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
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const Login()),
                          ),
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