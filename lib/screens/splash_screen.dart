import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.pink.shade600],
                ),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 70,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'LoveMatch',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Find Your Perfect Match',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.pink),
          ],
        ),
      ),
    );
  }
}
