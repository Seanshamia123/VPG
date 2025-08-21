// signupoptions.dart
import 'package:escort/screens/advertisers%20screens/subscription.dart';
import 'package:escort/screens/shared_screens/login.dart';
import 'package:escort/screens/shared_screens/signup.dart'; // Import your signup screen
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignOptions extends StatelessWidget {
  const SignOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A), // Dark charcoal
              Color(0xFF000000), // Pure black
              Color(0xFF1A1A1A), // Dark charcoal
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Golden particles/stars background effect
            Positioned.fill(
              child: CustomPaint(
                painter: GoldenParticlesPainter(),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? screenWidth - 48 : 800,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glamorous title
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700), // Bright gold
                                      Color(0xFFFFA500), // Orange gold
                                      Color(0xFFFFD700), // Bright gold
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Welcome to VipGalz',
                                    style: TextStyle(
                                      fontSize: isMobile ? 28 : 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  width: 100,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFFFFD700),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Sign up cards
                          isMobile
                              ? Column(
                                  children: [
                                    GlamorousSignUpCard(
                                      type: 'user',
                                      icon: Icons.person_outline,
                                      title: 'Sign up as User',
                                      subtitle: 'Join our exclusive community',
                                      onTap: () {
                                        // Navigate to signup page with user type
                                        Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Signup(userType: 'user'),
                                        ),
                                      );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    GlamorousSignUpCard(
                                      type: 'advertiser',
                                      icon: Icons.business_center_outlined,
                                      title: 'Sign up as Advertiser',
                                      subtitle: 'Promote your premium services',
                                      onTap: () {
                                        // For advertisers, you might want to show subscription first
                                        // or navigate directly to signup
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Choose Option'),
                                            content: const Text('Would you like to see subscription options or proceed directly to signup?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => const Dialog(child: SubscriptionDialog()),
                                                  );
                                                },
                                                child: const Text('View Subscriptions'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => const Signup(userType: 'advertiser'),
                                                        ),
                                                      );

                                                },
                                                child: const Text('Direct Signup'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : Wrap(
                                  spacing: 32,
                                  runSpacing: 24,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    GlamorousSignUpCard(
                                      type: 'user',
                                      icon: Icons.person_outline,
                                      title: 'Sign up as User',
                                      subtitle: 'Join our exclusive community',
                                      onTap: () {
                                        // Navigate to signup page with user type
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const Signup(userType: 'user'),
                                          ),
                                        );
                                 },
                                    ),
                                    GlamorousSignUpCard(
                                      type: 'advertiser',
                                      icon: Icons.business_center_outlined,
                                      title: 'Sign up as Advertiser',
                                      subtitle: 'Promote your premium services',
                                      onTap: () {
                                        // For advertisers, you might want to show subscription first
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Choose Option'),
                                            content: const Text('Would you like to see subscription options or proceed directly to signup?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => const Dialog(child: SubscriptionDialog()),
                                                  );
                                                },
                                                child: const Text('View Subscriptions'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => const Signup(userType: 'advertiser'),
                                                            ),
                                                          );
                                                },
                                                child: const Text('Direct Signup'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                          
                          const SizedBox(height: 40),
                          
                          // Glamorous back to login button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF333333),
                                  Color(0xFF1A1A1A),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Get.to(() => const Login());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFFFFD700),
                                shadowColor: Colors.transparent,
                                minimumSize: Size(isMobile ? 200 : 250, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
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
          ],
        ),
      ),
    );
  }
}

class GlamorousSignUpCard extends StatefulWidget {
  final String type;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const GlamorousSignUpCard({
    Key? key,
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  State<GlamorousSignUpCard> createState() => _GlamorousSignUpCardState();
}

class _GlamorousSignUpCardState extends State<GlamorousSignUpCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: isMobile ? double.infinity : 280,
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 280,
                  minHeight: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [
                            const Color(0xFF2A2A2A),
                            const Color(0xFF1A1A1A),
                            const Color(0xFF0A0A0A),
                          ]
                        : [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF0A0A0A),
                            const Color(0xFF000000),
                          ],
                  ),
                  border: Border.all(
                    color: _isHovered
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFFFD700).withOpacity(0.5),
                    width: _isHovered ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(_isHovered ? 0.4 : 0.2),
                      blurRadius: _isHovered ? 25 : 15,
                      spreadRadius: _isHovered ? 5 : 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with golden glow
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 32,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Decorative line
                      Container(
                        height: 1,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD700).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GoldenParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw golden particles/stars
    for (int i = 0; i < 50; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 23) % size.height;
      final radius = (i % 3) + 1.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}