import 'package:flutter/material.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart';
import 'package:kealthy/view/subscription/subscription_lunch_dinner_page.dart';

import 'sub_details.dart';

class SubscriptionHubPage extends StatelessWidget {
  const SubscriptionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Subscription'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HubButton(
              label: 'Milk',
              icon: Icons.local_drink,
              color: Colors.blue[100],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionDetailsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _HubButton(
              label: 'Lunch',
              icon: Icons.lunch_dining,
              color: Colors.orange[100],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LunchDinnerPlanPage(mealType: MealType.lunch),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _HubButton(
              label: 'Dinner',
              icon: Icons.dinner_dining,
              color: Colors.purple[100],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LunchDinnerPlanPage(mealType: MealType.dinner),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _HubButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.teal[700], size: 28),
              radius: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
