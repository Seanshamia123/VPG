// controllers/signup_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:escort/services/auth_service.dart';
import 'package:escort/services/token_storage.dart';
import 'package:escort/features/auth/presentation/screens/login.dart';

class SignupController extends GetxController {
  // Form controllers
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();

  // Form state
  final formKey = GlobalKey<FormState>();
  final selectedGender = 'Male'.obs;
  final isPasswordVisible = false.obs;
  final agreeToTerms = false.obs;
  final isLoading = false.obs;

  @override
  void onClose() {
    // Dispose controllers
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    locationController.dispose();
    bioController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void updateGender(String gender) {
    selectedGender.value = gender;
  }

  void toggleTermsAgreement() {
    agreeToTerms.value = !agreeToTerms.value;
  }

  Future<void> signup(String userType) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!agreeToTerms.value) {
      Get.snackbar(
        'Error',
        'Please agree to the Terms and Conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      Map<String, dynamic> result;
      
      if (userType == 'user') {
        result = await AuthService.registerUser(
          username: usernameController.text.trim(),
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          phoneNumber: phoneController.text.trim(),
          location: locationController.text.trim(),
          gender: selectedGender.value,
        );
      } else {
        result = await AuthService.registerAdvertiser(
          username: usernameController.text.trim(),
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          phoneNumber: phoneController.text.trim(),
          location: locationController.text.trim(),
          gender: selectedGender.value,
          bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
        );
      }

      if (result['success']) {
        // Store tokens and user info securely
        final data = result['data'];
        await TokenStorage.storeTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user_id'],
          userType: data['user_type'],
          expiresAt: data['expires_at'],
        );
        
        Get.snackbar(
          'Success',
          'Account created successfully! Welcome to VipGalz!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Navigate to appropriate screen based on user type
        if (data['user_type'] == 'user') {
          // Navigate to user dashboard/home
          // Get.offAll(() => const UserDashboard());
          Get.offAll(() => const Login()); // Temporary - replace with user dashboard
        } else {
          // Navigate to advertiser dashboard
          // Get.offAll(() => const AdvertiserDashboard());
          Get.offAll(() => const Login()); // Temporary - replace with advertiser dashboard
        }
        
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Registration failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Exception during signup: $e');
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form data
  void clearForm() {
    usernameController.clear();
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    locationController.clear();
    bioController.clear();
    selectedGender.value = 'Male';
    isPasswordVisible.value = false;
    agreeToTerms.value = false;
  }
}
