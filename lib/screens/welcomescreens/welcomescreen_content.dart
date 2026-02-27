import 'package:flutter/material.dart';

class WelcomescreenContent {
  final String image;
  final String title;
  final String button_text;
  final IconData icon;

  WelcomescreenContent({
    required this.image,
    required this.title,
    required this.button_text,
    required this.icon,
  });
}

List<WelcomescreenContent> welcomescreen_data = [
  WelcomescreenContent(
    image: 'assets/images/workout.jpg',
    title: 'Start Your Journey Towards A More Active Lifestyle',
    button_text: 'Next',
    icon: Icons.run_circle_outlined,
  ),
  WelcomescreenContent(
    image: 'assets/images/nutrition.jpg',
    title: 'Eat Smart, Stay Strong',
    button_text: 'Next',
    icon: Icons.restaurant_rounded,
  ),
  WelcomescreenContent(
    image: 'assets/images/tracking.jpg',
    title: 'Track Progress & Stay Motivated',
    button_text: 'Get Started',
    icon: Icons.groups_outlined,
  ),
];
