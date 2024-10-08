import 'package:flutter/material.dart';
import 'package:frontend/lit_Screens/baseScaffold.dart';
import 'package:lottie/lottie.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Error",
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Lottie icon for better visual representation
            Lottie.asset(
              'assets/images/error.json',
              height: 200,
              width: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Suggestion text
            Text(
              'Please check the URL or go back to the home page.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Navigate button with icon
          ],
        ),
      ),
    );
  }
}
