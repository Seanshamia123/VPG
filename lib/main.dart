import 'package:escort/app.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Escort());
}

class Escort extends StatelessWidget {
  const Escort({super.key});
  @override
  Widget build(BuildContext context) {
    return App();
  }
}
