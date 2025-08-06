import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/subscription/provider.dart';
import 'package:kealthy/view/subscription/sub_confirmation.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionDetailsPage extends ConsumerStatefulWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  ConsumerState<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState
    extends ConsumerState<SubscriptionDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Subscription Plans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: plansAsync.when(
          data: (plans) {
            final plan = plans.first;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CachedNetworkImage(
                    imageUrl: plan.imageUrl,
                    fit: BoxFit.cover,
                    width: 140,
                    height: 140,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 140,
                        height: 140,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  plan.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${plan.baseRate.toStringAsFixed(0)}/-',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.caption,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),

                // Plan cards section
                ...plans.map((p) => PlanCard(
                      title: p.title,
                      description: p.description,
                      baseRate: p.baseRate,
                      durationDays: p.durationDays,
                      name: p.name,
                    )),
                const SizedBox(height: 12),
              ],
            );
          },
          loading: () => Column(
            children: [
              // Shimmer for image and text placeholders
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 140,
                  height: 140,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(3, (_) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 20,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Shimmer for PlanCard placeholders
              ...List.generate(2, (_) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ],
          ),
          error: (e, _) => Center(child: Text('Error loading plans: $e')),
        ),
      ),
    );
  }
}

class PlanCard extends ConsumerWidget {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;
  final String name;

  const PlanCard({
    super.key,
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQty = ref.watch(quantityProvider(title));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              title: title,
              description: description,
              baseRate: baseRate,
              durationDays: durationDays,
              selectedQty: selectedQty,
              productName: name,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '₹${(baseRate * selectedQty * durationDays).toStringAsFixed(0)} ',
                      key: ValueKey('${baseRate * selectedQty * durationDays}'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.contains('Plus'))
                        Row(
                          children: [
                            const Icon(CupertinoIcons.gift,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                description.split('\n').firstWhere(
                                    (line) => line.contains('Plus')),
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.green),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      if (description.contains('Free Delivery'))
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Free Delivery',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.green),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Select Quantity:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedQty,
                        dropdownColor: Colors.white,
                        items: List.generate(2, (index) {
                          final value = index + 1;
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value L'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(quantityProvider(title).notifier).state =
                                value;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 65, 88, 108),
                ),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
