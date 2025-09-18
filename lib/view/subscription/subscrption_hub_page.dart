import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart';
import 'package:kealthy/view/subscription/subscription_lunch_dinner_page.dart';
import 'package:shimmer/shimmer.dart';

import 'sub_details.dart';

class SubscriptionHubPage extends StatelessWidget {
  const SubscriptionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'Categories': 'Milk',
        'image': 'lib/assets/images/subscribe.png',
      },
      {
        'Categories': 'Lunch',
        'image': 'lib/assets/images/lunch_subscribe.png',
      },
      {
        'Categories': 'Dinner',
        'image': 'lib/assets/images/dinner_subscribe.png',
      }
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    double tileWidth;
    double tileHeight;

    if (screenWidth < 600) {
      tileWidth = screenWidth;
      tileHeight = screenWidth * 0.5;
    } else if (screenWidth < 900) {
      tileWidth = screenWidth;
      tileHeight = 280;
    } else {
      tileWidth = screenWidth;
      tileHeight = 300;
    }
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
            Wrap(
              spacing: 18.0,
              runSpacing: 18.0,
              children: categories?.map((category) {
                    return GestureDetector(
                      onTap: () {
                        if (category['Categories'].toString().trim() ==
                            'Milk') {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  const SubscriptionDetailsPage(),
                            ),
                          );
                        } else if (category['Categories'].toString().trim() ==
                            'Lunch') {
                          // Navigator.push(
                          //   context,
                          //   CupertinoPageRoute(
                          //     builder: (context) => const LunchDinnerPlanPage(
                          //       mealType: MealType.lunch,
                          //     ),
                          //   ),
                          // );
                        } else {
                          // Navigator.push(
                          //   context,
                          //   CupertinoPageRoute(
                          //     builder: (context) => const LunchDinnerPlanPage(
                          //       mealType: MealType.dinner,
                          //     ),
                          //   ),
                          // );
                        }

                        // Navigator.push(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => SubCategoryPage(
                        //       categoryName: category['Categories'],
                        //     ),
                        //   ),
                        // );
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4F4F5),
                                  ),
                                  child: Image.asset(
                                    category['image'] as String,
                                    width: tileWidth,
                                    height: tileHeight,
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, url, error) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 100,
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category['Categories'] as String,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  }).toList() ??
                  [],
            ),
          ],
        ),
      ),
    );
  }
}
