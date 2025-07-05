import 'package:escort/app.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
// import 'screens/chat_list_screen.dart'; // Add this import

void main() {
  runApp(const Escort());
}

class Escort extends StatelessWidget {
  const Escort({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipGalz',
      debugShowCheckedModeBanner: false, // Optional: removes debug banner
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        // '/chat': (context) => const ChatListScreen(),
      },
    );
  }
}